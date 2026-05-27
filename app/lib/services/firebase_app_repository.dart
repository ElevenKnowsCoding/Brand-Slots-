import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase_options.dart';
import '../models/app_models.dart';
import 'app_repository.dart';

class FirebaseAppRepository implements AppRepository {
  FirebaseAppRepository();

  final _streamController = StreamController<AppData>.broadcast();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _configSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _screensSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _mediaSub;

  OrganizationProfile _organization = OrganizationProfile.empty();
  List<ScreenDevice> _screens = const [];
  List<MediaItem> _mediaItems = const [];
  AdminAccount? _admin;
  bool _initialized = false;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  @override
  bool get isCloudBacked => true;

  @override
  String get backendLabel => 'Firebase cloud sync';

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await loadInitialData();
    _bindStreams();
    _initialized = true;
  }

  @override
  Future<AppData> loadInitialData() async {
    final config = await _db.collection('app').doc('config').get();
    final screens = await _db.collection('screens').get();
    final media = await _db.collection('mediaItems').orderBy('createdAt').get();

    final configData = config.data() ?? const {};
    _organization = OrganizationProfile.fromJson(
      configData['organization'] as Map<String, dynamic>? ?? const {},
    );
    final adminData = configData['admin'] as Map<String, dynamic>?;
    _admin = adminData == null ? null : AdminAccount.fromJson(adminData);
    _screens = screens.docs
        .map((doc) => ScreenDevice.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
    _mediaItems = media.docs
        .map((doc) => MediaItem.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
    return _buildData();
  }

  @override
  Stream<AppData> watchAppData() => _streamController.stream;

  @override
  Future<void> createAdmin({
    required String name,
    required String email,
    required String password,
    required String companyName,
  }) async {
    final credentials = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final admin = AdminAccount(name: name, email: email.trim(), password: '');
    final organization = OrganizationProfile.empty().copyWith(
      companyName: companyName.trim(),
      adminName: name.trim(),
      adminEmail: email.trim(),
    );

    await _db.collection('app').doc('config').set({
      'admin': {...admin.toJson(), 'uid': credentials.user?.uid},
      'organization': organization.toJson(),
    });
  }

  @override
  Future<bool> loginAdmin(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> loginScreen(String loginCode, String password) async {
    final snapshot = await _db
        .collection('screens')
        .where('loginCode', isEqualTo: loginCode.trim())
        .where('password', isEqualTo: password)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return false;

    await snapshot.docs.first.reference.update({
      'lastSeenAt': DateTime.now().toIso8601String(),
    });
    return true;
  }

  @override
  Future<void> logout() async {
    if (_auth.currentUser != null) {
      await _auth.signOut();
    }
  }

  @override
  Future<void> updateOrganization(OrganizationProfile profile) async {
    await _db.collection('app').doc('config').set({
      'organization': profile.toJson(),
      'admin': {
        'name': profile.adminName,
        'email': profile.adminEmail,
        'password': '',
        'uid': _auth.currentUser?.uid,
      },
    }, SetOptions(merge: true));
  }

  @override
  Future<String?> addScreen({
    required String name,
    required String loginCode,
    required String password,
    required String location,
  }) async {
    final existing = await _db
        .collection('screens')
        .where('loginCode', isEqualTo: loginCode.trim())
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return 'Login code already exists.';
    }

    await _db.collection('screens').add({
      'name': name.trim(),
      'loginCode': loginCode.trim(),
      'password': password,
      'location': location.trim(),
      'assignedMediaIds': const <String>[],
      'lastSeenAt': null,
    });
    return null;
  }

  @override
  Future<void> addMedia({
    required String title,
    required MediaKind kind,
    required String description,
    required int durationSeconds,
    required List<String> screenIds,
    String? externalUrl,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    String resolvedUrl = (externalUrl ?? '').trim();
    String? storagePath;

    if (fileBytes != null && fileName != null && fileName.isNotEmpty) {
      final path = 'media/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = _storage.ref(path);
      await ref.putData(fileBytes);
      resolvedUrl = await ref.getDownloadURL();
      storagePath = path;
    }

    final mediaRef = await _db.collection('mediaItems').add({
      'title': title.trim(),
      'url': resolvedUrl,
      'kind': kind.name,
      'description': description.trim(),
      'durationSeconds': durationSeconds,
      'createdAt': DateTime.now().toIso8601String(),
      'storagePath': storagePath,
    });

    for (final screenId in screenIds) {
      final screenRef = _db.collection('screens').doc(screenId);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(screenRef);
        final existing =
            (snapshot.data()?['assignedMediaIds'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList();
        if (!existing.contains(mediaRef.id)) {
          existing.add(mediaRef.id);
        }
        transaction.update(screenRef, {'assignedMediaIds': existing});
      });
    }
  }

  @override
  Future<void> deleteMedia(String mediaId) async {
    final mediaDoc = await _db.collection('mediaItems').doc(mediaId).get();
    final storagePath = mediaDoc.data()?['storagePath'] as String?;
    if (storagePath != null && storagePath.isNotEmpty) {
      try {
        await _storage.ref(storagePath).delete();
      } catch (_) {}
    }
    await _db.collection('mediaItems').doc(mediaId).delete();
    final screens = await _db.collection('screens').get();
    for (final screen in screens.docs) {
      final assigned =
          (screen.data()['assignedMediaIds'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .where((item) => item != mediaId)
              .toList();
      await screen.reference.update({'assignedMediaIds': assigned});
    }
  }

  void _bindStreams() {
    _configSub?.cancel();
    _screensSub?.cancel();
    _mediaSub?.cancel();

    _configSub = _db.collection('app').doc('config').snapshots().listen((doc) {
      final data = doc.data() ?? const {};
      _organization = OrganizationProfile.fromJson(
        data['organization'] as Map<String, dynamic>? ?? const {},
      );
      final adminData = data['admin'] as Map<String, dynamic>?;
      _admin = adminData == null ? null : AdminAccount.fromJson(adminData);
      _emit();
    });

    _screensSub = _db.collection('screens').snapshots().listen((snapshot) {
      _screens = snapshot.docs
          .map((doc) => ScreenDevice.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
      _emit();
    });

    _mediaSub = _db
        .collection('mediaItems')
        .orderBy('createdAt')
        .snapshots()
        .listen((snapshot) {
          _mediaItems = snapshot.docs
              .map((doc) => MediaItem.fromJson({'id': doc.id, ...doc.data()}))
              .toList();
          _emit();
        });
  }

  AppData _buildData() {
    return AppData(
      admin: _admin,
      organization: _organization,
      screens: _screens,
      mediaItems: _mediaItems,
    );
  }

  void _emit() {
    _streamController.add(_buildData());
  }
}
