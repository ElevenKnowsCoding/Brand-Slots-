import 'dart:typed_data';

import '../models/app_models.dart';

abstract class AppRepository {
  bool get isCloudBacked;
  String get backendLabel;

  Future<void> initialize();
  Future<AppData> loadInitialData();
  Stream<AppData> watchAppData();
  Future<void> createAdmin({
    required String name,
    required String email,
    required String password,
    required String companyName,
  });
  Future<bool> loginAdmin(String email, String password);
  Future<bool> loginScreen(String loginCode, String password);
  Future<void> logout();
  Future<void> updateOrganization(OrganizationProfile profile);
  Future<String?> addScreen({
    required String name,
    required String loginCode,
    required String password,
    required String location,
  });
  Future<void> updateScreen(ScreenDevice screen);
  Future<void> reportScreenPlayback({
    required String screenId,
    required bool completedRound,
  });
  Future<void> addMedia({
    required String title,
    required MediaKind kind,
    required String description,
    required int durationSeconds,
    required List<String> screenIds,
    String? externalUrl,
    Uint8List? fileBytes,
    String? fileName,
  });
  Future<void> deleteMedia(String mediaId);
}
