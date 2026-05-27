import 'dart:async';
import 'dart:typed_data';

import '../models/app_models.dart';
import 'app_repository.dart';
import 'app_store.dart';

class LocalAppRepository implements AppRepository {
  LocalAppRepository(this._store);

  final AppStore _store;
  final StreamController<AppData> _controller =
      StreamController<AppData>.broadcast();
  AppData _data = AppData.empty();

  @override
  bool get isCloudBacked => false;

  @override
  String get backendLabel => 'Local demo storage';

  @override
  Future<void> initialize() async {
    _data = await _store.load();
    _controller.add(_data);
  }

  @override
  Future<AppData> loadInitialData() async {
    _data = await _store.load();
    return _data;
  }

  @override
  Stream<AppData> watchAppData() => _controller.stream;

  @override
  Future<void> createAdmin({
    required String name,
    required String email,
    required String password,
    required String companyName,
  }) async {
    final admin = AdminAccount(name: name, email: email, password: password);
    final organization = _data.organization.copyWith(
      companyName: companyName,
      adminName: name,
      adminEmail: email,
    );
    _data = _data.copyWith(admin: admin, organization: organization);
    await _persist();
  }

  @override
  Future<bool> loginAdmin(String email, String password) async {
    final existing = _data.admin;
    if (existing == null) return false;
    return existing.email.trim().toLowerCase() == email.trim().toLowerCase() &&
        existing.password == password;
  }

  @override
  Future<bool> loginScreen(String loginCode, String password) async {
    final match = _data.screens.where((screen) {
      return screen.loginCode.trim().toLowerCase() ==
              loginCode.trim().toLowerCase() &&
          screen.password == password;
    }).toList();
    if (match.isEmpty) return false;
    final screen = match.first.copyWith(
      lastSeenAt: DateTime.now().toIso8601String(),
    );
    _data = _data.copyWith(
      screens: _data.screens
          .map((item) => item.id == screen.id ? screen : item)
          .toList(),
    );
    await _persist();
    return true;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> updateOrganization(OrganizationProfile profile) async {
    _data = _data.copyWith(organization: profile);
    final admin = _data.admin;
    if (admin != null) {
      _data = _data.copyWith(
        admin: admin.copyWith(
          name: profile.adminName,
          email: profile.adminEmail,
        ),
      );
    }
    await _persist();
  }

  @override
  Future<String?> addScreen({
    required String name,
    required String loginCode,
    required String password,
    required String location,
  }) async {
    final exists = _data.screens.any(
      (screen) =>
          screen.loginCode.trim().toLowerCase() ==
          loginCode.trim().toLowerCase(),
    );
    if (exists) {
      return 'Login code already exists.';
    }

    _data = _data.copyWith(
      screens: [
        ..._data.screens,
        ScreenDevice(
          id: _id(),
          name: name.trim(),
          loginCode: loginCode.trim(),
          password: password,
          location: location.trim(),
          assignedMediaIds: const [],
          lastSeenAt: null,
          playCount: 0,
          completedRounds: 0,
          lastPlaybackAt: null,
        ),
      ],
    );
    await _persist();
    return null;
  }

  @override
  Future<void> updateScreen(ScreenDevice screen) async {
    _data = _data.copyWith(
      screens: _data.screens
          .map((item) => item.id == screen.id ? screen : item)
          .toList(),
    );
    await _persist();
  }

  @override
  Future<void> reportScreenPlayback({
    required String screenId,
    required bool completedRound,
  }) async {
    _data = _data.copyWith(
      screens: _data.screens.map((screen) {
        if (screen.id != screenId) return screen;
        return screen.copyWith(
          playCount: screen.playCount + 1,
          completedRounds: screen.completedRounds + (completedRound ? 1 : 0),
          lastPlaybackAt: DateTime.now().toIso8601String(),
        );
      }).toList(),
    );
    await _persist();
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
    final media = MediaItem(
      id: _id(),
      title: title.trim(),
      url: (externalUrl ?? '').trim(),
      kind: kind,
      description: description.trim(),
      durationSeconds: durationSeconds,
      createdAt: DateTime.now().toIso8601String(),
      storagePath: null,
    );

    _data = _data.copyWith(
      mediaItems: [..._data.mediaItems, media],
      screens: _data.screens.map((screen) {
        if (!screenIds.contains(screen.id)) return screen;
        return screen.copyWith(
          assignedMediaIds: [...screen.assignedMediaIds, media.id],
        );
      }).toList(),
    );
    await _persist();
  }

  @override
  Future<void> deleteMedia(String mediaId) async {
    _data = _data.copyWith(
      mediaItems: _data.mediaItems.where((item) => item.id != mediaId).toList(),
      screens: _data.screens
          .map(
            (screen) => screen.copyWith(
              assignedMediaIds: screen.assignedMediaIds
                  .where((item) => item != mediaId)
                  .toList(),
            ),
          )
          .toList(),
    );
    await _persist();
  }

  Future<void> _persist() async {
    await _store.save(_data);
    _controller.add(_data);
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
}
