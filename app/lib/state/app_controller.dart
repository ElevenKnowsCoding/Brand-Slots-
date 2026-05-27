import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models/app_models.dart';
import '../services/app_repository.dart';

enum SessionMode { none, admin, screen }

class AppController extends ChangeNotifier {
  AppController(this._repository);

  final AppRepository _repository;

  AppData _data = AppData.empty();
  bool _isReady = false;
  SessionMode _sessionMode = SessionMode.none;
  String? _activeScreenId;
  StreamSubscription<AppData>? _dataSubscription;

  AppData get data => _data;
  bool get isReady => _isReady;
  bool get hasAdmin => _data.admin != null;
  bool get isCloudBacked => _repository.isCloudBacked;
  String get backendLabel => _repository.backendLabel;
  SessionMode get sessionMode => _sessionMode;
  OrganizationProfile get organization => _data.organization;
  AdminAccount? get admin => _data.admin;
  List<ScreenDevice> get screens => _data.screens;
  List<MediaItem> get mediaItems => _data.mediaItems;
  ScreenDevice? get activeScreen =>
      _activeScreenId == null ? null : getScreenById(_activeScreenId!);

  Future<void> initialize() async {
    await _repository.initialize();
    _data = await _repository.loadInitialData();
    _dataSubscription?.cancel();
    _dataSubscription = _repository.watchAppData().listen((data) {
      _data = data;
      notifyListeners();
    });
    _isReady = true;
    notifyListeners();
  }

  Future<void> createAdmin({
    required String name,
    required String email,
    required String password,
    required String companyName,
  }) async {
    await _repository.createAdmin(
      name: name,
      email: email,
      password: password,
      companyName: companyName,
    );
    _sessionMode = SessionMode.admin;
    notifyListeners();
  }

  Future<bool> loginAdmin(String email, String password) async {
    final success = await _repository.loginAdmin(email, password);
    if (!success) return false;
    _sessionMode = SessionMode.admin;
    _activeScreenId = null;
    notifyListeners();
    return success;
  }

  Future<bool> loginScreen(String loginCode, String password) async {
    final success = await _repository.loginScreen(loginCode, password);
    if (!success) return false;
    final screen = _data.screens.firstWhere(
      (item) =>
          item.loginCode.trim().toLowerCase() == loginCode.trim().toLowerCase(),
      orElse: () => const ScreenDevice(
        id: '',
        name: '',
        loginCode: '',
        password: '',
        location: '',
        assignedMediaIds: [],
        lastSeenAt: null,
        playCount: 0,
        completedRounds: 0,
        lastPlaybackAt: null,
      ),
    );
    _sessionMode = SessionMode.screen;
    _activeScreenId = screen.id.isEmpty ? null : screen.id;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await _repository.logout();
    _sessionMode = SessionMode.none;
    _activeScreenId = null;
    notifyListeners();
  }

  Future<void> updateOrganization(OrganizationProfile profile) async {
    await _repository.updateOrganization(profile);
  }

  Future<String?> addScreen({
    required String name,
    required String loginCode,
    required String password,
    required String location,
  }) async {
    return _repository.addScreen(
      name: name,
      loginCode: loginCode,
      password: password,
      location: location,
    );
  }

  Future<void> updateScreen(ScreenDevice updated) async {
    await _repository.updateScreen(updated);
  }

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
    await _repository.addMedia(
      title: title,
      kind: kind,
      description: description,
      durationSeconds: durationSeconds,
      screenIds: screenIds,
      externalUrl: externalUrl,
      fileBytes: fileBytes,
      fileName: fileName,
    );
  }

  Future<void> deleteMedia(String mediaId) async {
    await _repository.deleteMedia(mediaId);
  }

  Future<void> reportScreenPlayback({
    required String screenId,
    required bool completedRound,
  }) async {
    await _repository.reportScreenPlayback(
      screenId: screenId,
      completedRound: completedRound,
    );
  }

  ScreenDevice? getScreenById(String id) {
    for (final screen in _data.screens) {
      if (screen.id == id) return screen;
    }
    return null;
  }

  List<MediaItem> mediaForScreen(String screenId) {
    final screen = getScreenById(screenId);
    if (screen == null) return const [];
    return _data.mediaItems
        .where((item) => screen.assignedMediaIds.contains(item.id))
        .toList();
  }

  String? apkDownloadUrlForScreen(ScreenDevice screen) {
    return screen.apkDownloadUrl(_data.organization.apkBaseUrl);
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }
}
