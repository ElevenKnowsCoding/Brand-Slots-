import 'dart:async';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_models.dart';
import 'app_repository.dart';

class SupabaseAppRepository implements AppRepository {
  static const _cacheKey = 'ad_master_supabase_cache_v2';

  final _streamController = StreamController<AppData>.broadcast();

  OrganizationProfile _organization = OrganizationProfile.empty();
  List<ClientProfile> _clients = const [];
  List<ScreenDevice> _screens = const [];
  List<MediaItem> _mediaItems = const [];
  List<MediaPlaybackStat> _playbackStats = const [];

  SupabaseClient get _db => Supabase.instance.client;

  @override
  bool get isCloudBacked => true;

  @override
  String get backendLabel => 'Supabase cloud sync';

  @override
  Future<void> initialize() async {
    await loadInitialData();
    try {
      _bindStreams();
    } catch (_) {}
  }

  @override
  Future<AppData> loadInitialData() async {
    try {
      final config = await _db.from('app_config').select().maybeSingle();
      final screens = await _db.from('screens').select();
      final media = await _db.from('media_items').select().order('created_at');

      List clients = const [];
      List playback = const [];

      try {
        clients = await _db.from('clients').select().order('created_at');
      } catch (_) {}
      try {
        playback = await _db
            .from('media_playback')
            .select()
            .order('play_count', ascending: false);
      } catch (_) {}

      if (config != null) _organization = _orgFromRow(config);
      _clients = clients.map((r) => _clientFromRow(r)).toList();
      _screens = (screens as List).map((r) => _screenFromRow(r)).toList();
      _mediaItems = (media as List).map((r) => _mediaFromRow(r)).toList();
      _playbackStats = playback.map((r) => _playbackFromRow(r)).toList();

      final data = _buildData();
      await _saveCache(data);
      return data;
    } catch (_) {
      final cached = await _loadCache();
      if (cached != null) {
        _organization = cached.organization;
        _clients = cached.clients;
        _screens = cached.screens;
        _mediaItems = cached.mediaItems;
        _playbackStats = cached.playbackStats;
        return cached;
      }
      rethrow;
    }
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
    await _db.from('app_config').upsert({
      'id': 'singleton',
      'company_name': companyName.trim(),
      'admin_name': name.trim(),
      'admin_email': email.trim(),
      'admin_password': password,
      'phone': '',
      'welcome_message': 'No content has been assigned yet.',
      'logo_url': '',
      'accent_color_hex': '#0F766E',
      'apk_base_url': '',
      'local_project_path': '',
    });
  }

  @override
  Future<bool> loginAdmin(String email, String password) async {
    final config = await _db.from('app_config').select().maybeSingle();
    if (config == null) return false;
    return config['admin_email'] == email.trim() &&
        config['admin_password'] == password;
  }

  @override
  Future<bool> loginScreen(String loginCode, String password) async {
    try {
      final result = await _db
          .from('screens')
          .select()
          .eq('login_code', loginCode.trim())
          .eq('password', password)
          .maybeSingle();
      if (result == null) return false;
      await _db.from('screens').update({
        'last_seen_at': DateTime.now().toIso8601String(),
      }).eq('id', result['id']);
      return true;
    } catch (_) {
      final index = _screens.indexWhere(
        (item) =>
            item.loginCode.trim().toLowerCase() ==
                loginCode.trim().toLowerCase() &&
            item.password == password,
      );
      if (index == -1) return false;
      final updated = _screens[index].copyWith(
        lastSeenAt: DateTime.now().toIso8601String(),
      );
      _screens = [
        for (var i = 0; i < _screens.length; i++)
          if (i == index) updated else _screens[i],
      ];
      _emit();
      return true;
    }
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> updateOrganization(OrganizationProfile profile) async {
    await _db.from('app_config').upsert({
      'id': 'singleton',
      'company_name': profile.companyName,
      'admin_name': profile.adminName,
      'admin_email': profile.adminEmail,
      'phone': profile.phone,
      'welcome_message': profile.welcomeMessage,
      'logo_url': profile.logoUrl,
      'accent_color_hex': profile.accentColorHex,
      'apk_base_url': profile.apkBaseUrl,
      'local_project_path': profile.localProjectPath,
    });
  }

  @override
  Future<void> addClient({
    required String name,
    required String contactName,
    required String contactEmail,
    required String phone,
    required String notes,
  }) async {
    await _db.from('clients').insert({
      'name': name.trim(),
      'contact_name': contactName.trim(),
      'contact_email': contactEmail.trim(),
      'phone': phone.trim(),
      'notes': notes.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateClient(ClientProfile client) async {
    await _db.from('clients').update({
      'name': client.name.trim(),
      'contact_name': client.contactName.trim(),
      'contact_email': client.contactEmail.trim(),
      'phone': client.phone.trim(),
      'notes': client.notes.trim(),
    }).eq('id', client.id);
  }

  @override
  Future<void> deleteClient(String clientId) async {
    final mediaRows = await _db
        .from('media_items')
        .select()
        .eq('client_id', clientId);
    final mediaIds = <String>[];
    final storagePaths = <String>[];

    for (final row in mediaRows as List) {
      final record = row as Map<String, dynamic>;
      mediaIds.add(record['id'] as String);
      final storagePath = record['storage_path'] as String?;
      if (storagePath != null && storagePath.isNotEmpty) {
        storagePaths.add(storagePath);
      }
    }

    if (storagePaths.isNotEmpty) {
      await _db.storage.from('media').remove(storagePaths);
    }

    if (mediaIds.isNotEmpty) {
      await _db.from('media_playback').delete().inFilter('media_id', mediaIds);
      await _db.from('media_items').delete().inFilter('id', mediaIds);

      final screens = await _db.from('screens').select();
      for (final row in screens as List) {
        final screen = row as Map<String, dynamic>;
        final ids = List<String>.from(screen['assigned_media_ids'] as List? ?? []);
        final filtered = ids.where((id) => !mediaIds.contains(id)).toList();
        if (filtered.length != ids.length) {
          await _db
              .from('screens')
              .update({'assigned_media_ids': filtered}).eq('id', screen['id']);
        }
      }
    }

    await _db.from('clients').delete().eq('id', clientId);
  }

  @override
  Future<String?> addScreen({
    required String name,
    required String loginCode,
    required String password,
    required String location,
  }) async {
    final existing = await _db
        .from('screens')
        .select()
        .eq('login_code', loginCode.trim())
        .maybeSingle();
    if (existing != null) return 'Login code already exists.';
    await _db.from('screens').insert({
      'name': name.trim(),
      'login_code': loginCode.trim(),
      'password': password,
      'location': location.trim(),
      'assigned_media_ids': [],
      'last_seen_at': null,
      'play_count': 0,
      'completed_rounds': 0,
      'last_playback_at': null,
    });
    return null;
  }

  @override
  Future<void> updateScreen(ScreenDevice screen) async {
    await _db.from('screens').update({
      'name': screen.name.trim(),
      'login_code': screen.loginCode.trim(),
      'password': screen.password,
      'location': screen.location.trim(),
      'assigned_media_ids': screen.assignedMediaIds,
      'last_seen_at': screen.lastSeenAt,
      'play_count': screen.playCount,
      'completed_rounds': screen.completedRounds,
      'last_playback_at': screen.lastPlaybackAt,
    }).eq('id', screen.id);
  }

  @override
  Future<void> addMedia({
    required String clientId,
    required String title,
    required MediaKind kind,
    required String description,
    required int durationSeconds,
    String? externalUrl,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    String resolvedUrl = (externalUrl ?? '').trim();
    String? storagePath;

    if (fileBytes != null && fileName != null && fileName.isNotEmpty) {
      final path =
          'clients/$clientId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await _db.storage.from('media').uploadBinary(path, fileBytes);
      resolvedUrl = _db.storage.from('media').getPublicUrl(path);
      storagePath = path;
    }

    await _db.from('media_items').insert({
      'client_id': clientId,
      'title': title.trim(),
      'url': resolvedUrl,
      'kind': kind.name,
      'description': description.trim(),
      'duration_seconds': durationSeconds,
      'created_at': DateTime.now().toIso8601String(),
      'storage_path': storagePath,
    });
  }

  @override
  Future<void> deleteMedia(String mediaId) async {
    final media = await _db
        .from('media_items')
        .select()
        .eq('id', mediaId)
        .maybeSingle();
    if (media != null && media['storage_path'] != null) {
      await _db.storage.from('media').remove([media['storage_path'] as String]);
    }

    await _db.from('media_playback').delete().eq('media_id', mediaId);
    await _db.from('media_items').delete().eq('id', mediaId);

    final screens = await _db.from('screens').select();
    for (final screen in screens as List) {
      final ids = List<String>.from(screen['assigned_media_ids'] as List? ?? []);
      if (ids.contains(mediaId)) {
        ids.remove(mediaId);
        await _db
            .from('screens')
            .update({'assigned_media_ids': ids}).eq('id', screen['id']);
      }
    }
  }

  @override
  Future<void> reportScreenPlayback({
    required String screenId,
    required String mediaId,
    required bool completedRound,
  }) async {
    final now = DateTime.now().toIso8601String();
    final index = _screens.indexWhere((screen) => screen.id == screenId);
    if (index == -1) return;

    final updated = _screens[index].copyWith(
      playCount: _screens[index].playCount + 1,
      completedRounds:
          _screens[index].completedRounds + (completedRound ? 1 : 0),
      lastPlaybackAt: now,
    );

    _screens = [
      for (var i = 0; i < _screens.length; i++)
        if (i == index) updated else _screens[i],
    ];

    final localStatIndex = _playbackStats.indexWhere(
      (item) => item.mediaId == mediaId && item.screenId == screenId,
    );
    if (localStatIndex == -1) {
      _playbackStats = [
        ..._playbackStats,
        MediaPlaybackStat(
          id: '$mediaId:$screenId',
          mediaId: mediaId,
          screenId: screenId,
          playCount: 1,
          lastPlayedAt: now,
        ),
      ];
    } else {
      final current = _playbackStats[localStatIndex];
      _playbackStats = [
        for (var i = 0; i < _playbackStats.length; i++)
          if (i == localStatIndex)
            current.copyWith(
              playCount: current.playCount + 1,
              lastPlayedAt: now,
            )
          else
            _playbackStats[i],
      ];
    }

    _emit();

    try {
      await _db.from('screens').update({
        'play_count': updated.playCount,
        'completed_rounds': updated.completedRounds,
        'last_playback_at': updated.lastPlaybackAt,
      }).eq('id', screenId);

      final existing = await _db
          .from('media_playback')
          .select()
          .eq('media_id', mediaId)
          .eq('screen_id', screenId)
          .maybeSingle();
      if (existing == null) {
        await _db.from('media_playback').insert({
          'media_id': mediaId,
          'screen_id': screenId,
          'play_count': 1,
          'last_played_at': now,
        });
      } else {
        await _db.from('media_playback').update({
          'play_count': (existing['play_count'] as num).toInt() + 1,
          'last_played_at': now,
        }).eq('id', existing['id']);
      }
    } catch (_) {}
  }

  void _bindStreams() {
    _db
        .channel('app_config')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'app_config',
          callback: (_) async {
            final config = await _db.from('app_config').select().maybeSingle();
            if (config != null) _organization = _orgFromRow(config);
            _emit();
          },
        )
        .subscribe();

    _db
        .channel('clients')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'clients',
          callback: (_) async {
            try {
              final clients = await _db.from('clients').select().order('created_at');
              _clients = (clients as List).map((r) => _clientFromRow(r)).toList();
              _emit();
            } catch (_) {}
          },
        )
        .subscribe();

    _db
        .channel('screens')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'screens',
          callback: (_) async {
            final screens = await _db.from('screens').select();
            _screens = (screens as List).map((r) => _screenFromRow(r)).toList();
            _emit();
          },
        )
        .subscribe();

    _db
        .channel('media_items')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'media_items',
          callback: (_) async {
            final media = await _db
                .from('media_items')
                .select()
                .order('created_at');
            _mediaItems = (media as List).map((r) => _mediaFromRow(r)).toList();
            _emit();
          },
        )
        .subscribe();

    _db
        .channel('media_playback')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'media_playback',
          callback: (_) async {
            try {
              final playback = await _db
                  .from('media_playback')
                  .select()
                  .order('play_count', ascending: false);
              _playbackStats =
                  (playback as List).map((r) => _playbackFromRow(r)).toList();
              _emit();
            } catch (_) {}
          },
        )
        .subscribe();
  }

  AppData _buildData() => AppData(
        admin: _organization.adminEmail.isEmpty
            ? null
            : AdminAccount(
                name: _organization.adminName,
                email: _organization.adminEmail,
                password: '',
              ),
        organization: _organization,
        clients: _clients,
        screens: _screens,
        mediaItems: _mediaItems,
        playbackStats: _playbackStats,
      );

  void _emit() {
    final data = _buildData();
    unawaited(_saveCache(data));
    _streamController.add(data);
  }

  Future<void> _saveCache(AppData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, data.encode());
  }

  Future<AppData?> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppData.decode(raw);
    } catch (_) {
      return null;
    }
  }

  OrganizationProfile _orgFromRow(Map<String, dynamic> r) =>
      OrganizationProfile(
        companyName: r['company_name'] as String? ?? '',
        adminName: r['admin_name'] as String? ?? '',
        adminEmail: r['admin_email'] as String? ?? '',
        phone: r['phone'] as String? ?? '',
        welcomeMessage: r['welcome_message'] as String? ??
            'No content has been assigned yet.',
        logoUrl: r['logo_url'] as String? ?? '',
        accentColorHex: r['accent_color_hex'] as String? ?? '#0F766E',
        apkBaseUrl: r['apk_base_url'] as String? ?? '',
        localProjectPath: r['local_project_path'] as String? ?? '',
      );

  ClientProfile _clientFromRow(Map<String, dynamic> r) => ClientProfile(
        id: r['id'] as String,
        name: r['name'] as String? ?? '',
        contactName: r['contact_name'] as String? ?? '',
        contactEmail: r['contact_email'] as String? ?? '',
        phone: r['phone'] as String? ?? '',
        notes: r['notes'] as String? ?? '',
        createdAt: r['created_at'] as String? ?? '',
      );

  ScreenDevice _screenFromRow(Map<String, dynamic> r) => ScreenDevice(
        id: r['id'] as String,
        name: r['name'] as String? ?? '',
        loginCode: r['login_code'] as String? ?? '',
        password: r['password'] as String? ?? '',
        location: r['location'] as String? ?? '',
        assignedMediaIds:
            List<String>.from(r['assigned_media_ids'] as List? ?? []),
        lastSeenAt: r['last_seen_at'] as String?,
        playCount: (r['play_count'] as num?)?.toInt() ?? 0,
        completedRounds: (r['completed_rounds'] as num?)?.toInt() ?? 0,
        lastPlaybackAt: r['last_playback_at'] as String?,
      );

  MediaItem _mediaFromRow(Map<String, dynamic> r) => MediaItem(
        id: r['id'] as String,
        clientId: r['client_id'] as String? ?? '',
        title: r['title'] as String? ?? '',
        url: r['url'] as String? ?? '',
        kind: (r['kind'] as String? ?? 'video') == 'image'
            ? MediaKind.image
            : MediaKind.video,
        description: r['description'] as String? ?? '',
        durationSeconds: (r['duration_seconds'] as num?)?.toInt() ?? 15,
        createdAt: r['created_at'] as String? ?? '',
        storagePath: r['storage_path'] as String?,
      );

  MediaPlaybackStat _playbackFromRow(Map<String, dynamic> r) => MediaPlaybackStat(
        id: r['id'] as String,
        mediaId: r['media_id'] as String? ?? '',
        screenId: r['screen_id'] as String? ?? '',
        playCount: (r['play_count'] as num?)?.toInt() ?? 0,
        lastPlayedAt: r['last_played_at'] as String?,
      );
}
