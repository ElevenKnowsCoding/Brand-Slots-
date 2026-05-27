import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/app_models.dart';
import '../services/screen_media_cache.dart';
import '../state/app_controller.dart';

class ScreenPlayerPage extends StatefulWidget {
  const ScreenPlayerPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<ScreenPlayerPage> createState() => _ScreenPlayerPageState();
}

class _ScreenPlayerPageState extends State<ScreenPlayerPage> {
  int _currentIndex = 0;
  int _visibleIndex = 0;
  String? _visibleMediaId;
  int _loadToken = 0;
  bool _isAdvancing = false;
  bool _hasPendingPlaylistRefresh = false;
  Timer? _imageTimer;
  VideoPlayerController? _videoController;
  ImageProvider<Object>? _imageProvider;
  late final ScreenMediaCache _mediaCache;
  String _playlistSignature = '';

  @override
  void initState() {
    super.initState();
    _mediaCache = createScreenMediaCache();
    widget.controller.addListener(_handleControllerUpdate);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _playlistSignature = _buildPlaylistSignature(_media);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareCurrentMedia());
  }

  @override
  void didUpdateWidget(covariant ScreenPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerUpdate);
      widget.controller.addListener(_handleControllerUpdate);
      _playlistSignature = _buildPlaylistSignature(_media);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerUpdate);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _imageTimer?.cancel();
    _disposeVideo();
    super.dispose();
  }

  List<MediaItem> get _media {
    final screen = widget.controller.activeScreen;
    if (screen == null) return const [];
    return widget.controller.mediaForScreen(screen.id);
  }

  void _handleControllerUpdate() {
    final media = _media;
    final nextSignature = _buildPlaylistSignature(media);
    if (nextSignature == _playlistSignature) return;

    _playlistSignature = nextSignature;
    _syncOfflineCache(media);

    if (media.isEmpty) {
      _hasPendingPlaylistRefresh = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepareCurrentMedia());
      return;
    }

    final visibleItem = _visibleItem;
    final visibleStillExists = visibleItem != null &&
        media.any((item) => item.id == visibleItem.id);

    if (!visibleStillExists) {
      _hasPendingPlaylistRefresh = false;
      _currentIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepareCurrentMedia());
      return;
    }

    _hasPendingPlaylistRefresh = true;
  }

  MediaItem? get _visibleItem {
    final media = _media;
    if (media.isEmpty) return null;
    final visibleMediaId = _visibleMediaId;
    if (visibleMediaId != null) {
      for (final item in media) {
        if (item.id == visibleMediaId) return item;
      }
    }
    if (_visibleIndex < 0 || _visibleIndex >= media.length) return null;
    return media[_visibleIndex];
  }

  String _buildPlaylistSignature(List<MediaItem> media) {
    return media
        .map(
          (item) =>
              '${item.id}|${item.url}|${item.kind.name}|${item.durationSeconds}',
        )
        .join('||');
  }

  Future<void> _prepareCurrentMedia() async {
    final media = _media;
    if (media.isEmpty) {
      _imageTimer?.cancel();
      _disposeVideo();
      if (mounted) {
        setState(() {
          _currentIndex = 0;
          _visibleIndex = 0;
          _visibleMediaId = null;
          _imageProvider = null;
        });
      }
      return;
    }

    _syncOfflineCache(media);

    if (_currentIndex >= media.length) {
      _currentIndex = 0;
    }

    final current = media[_currentIndex];
    final token = ++_loadToken;

    _imageTimer?.cancel();

    if (current.kind == MediaKind.image) {
      late final PreparedMediaImage prepared;
      try {
        prepared = await _mediaCache.prepareImage(current);
        await precacheImage(prepared.provider, context);
      } catch (_) {
        if (!mounted || token != _loadToken) return;
        _disposeVideo();
        setState(() {
          _imageProvider = null;
          _isAdvancing = false;
        });
        _imageTimer = Timer(Duration(seconds: current.durationSeconds), _advance);
        return;
      }

      if (!mounted || token != _loadToken) return;

      _disposeVideo();
      setState(() {
        _visibleIndex = _currentIndex;
        _visibleMediaId = current.id;
        _imageProvider = prepared.provider;
        _isAdvancing = false;
      });
      _imageTimer = Timer(Duration(seconds: current.durationSeconds), _advance);
      return;
    }

    late final VideoPlayerController controller;
    try {
      controller = await _mediaCache.prepareVideoController(current);
    } catch (_) {
      if (!mounted || token != _loadToken) return;
      _disposeVideo();
      setState(() {
        _visibleIndex = _currentIndex;
        _visibleMediaId = current.id;
        _imageProvider = null;
        _isAdvancing = false;
      });
      _imageTimer = Timer(Duration(seconds: current.durationSeconds), _advance);
      return;
    }

    if (!mounted || token != _loadToken) {
      await controller.dispose();
      return;
    }

    final oldController = _videoController;
    controller.addListener(() {
      if (!mounted || _videoController != controller) return;
      final value = controller.value;
      if (!value.isInitialized || value.duration.inMilliseconds <= 0) return;
      if (value.position >= value.duration) {
        _advance();
      }
    });

    setState(() {
      _visibleIndex = _currentIndex;
      _visibleMediaId = current.id;
      _videoController = controller;
      _imageProvider = null;
      _isAdvancing = false;
    });

    await oldController?.dispose();
    await controller.play();
  }

  void _advance() {
    if (_isAdvancing) return;

    final screen = widget.controller.activeScreen;
    final media = _media;
    if (screen == null || media.isEmpty) return;

    final visibleItem = _visibleItem;
    final currentPosition = visibleItem == null
        ? -1
        : media.indexWhere((item) => item.id == visibleItem.id);
    final completedRound =
        currentPosition != -1 && currentPosition == media.length - 1;
    final fallbackIndex = _visibleIndex.clamp(0, media.length - 1) as int;
    final playedMediaId = visibleItem?.id ?? media[fallbackIndex].id;

    _isAdvancing = true;
    unawaited(
      widget.controller.reportScreenPlayback(
        screenId: screen.id,
        mediaId: playedMediaId,
        completedRound: completedRound,
      ),
    );

    setState(() {
      if (_hasPendingPlaylistRefresh) {
        _hasPendingPlaylistRefresh = false;
        if (visibleItem == null) {
          _currentIndex = 0;
        } else {
          _currentIndex = currentPosition == -1
              ? 0
              : (currentPosition + 1) % media.length;
        }
      } else {
        _currentIndex = (_currentIndex + 1) % media.length;
      }
    });
    _prepareCurrentMedia();
  }

  void _disposeVideo() {
    final controller = _videoController;
    _videoController = null;
    controller?.dispose();
  }

  void _syncOfflineCache(List<MediaItem> items) {
    _mediaCache.syncAssignedMedia(items);
    _mediaCache.pruneToAssignedMedia(items);
  }

  @override
  Widget build(BuildContext context) {
    final screen = widget.controller.activeScreen;
    if (screen == null) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final current = _visibleItem;
    final videoController = _videoController;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPress: widget.controller.logout,
        child: SizedBox.expand(
          child: current == null
              ? const Center(
                  child: Text(
                    'No media assigned yet.',
                    style: TextStyle(color: Colors.white54, fontSize: 20),
                  ),
                )
              : current.kind == MediaKind.image
              ? _buildImage(current)
              : (videoController != null && videoController.value.isInitialized)
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: videoController.value.size.width,
                      height: videoController.value.size.height,
                      child: VideoPlayer(videoController),
                    ),
                  ),
                )
              : _buildFallback(current),
        ),
      ),
    );
  }

  Widget _buildImage(MediaItem item) {
    final provider = _imageProvider;
    if (provider == null) {
      return _buildFallback(item);
    }

    return Image(
      image: provider,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _buildFallback(item),
    );
  }

  Widget _buildFallback(MediaItem item) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.ondemand_video_outlined,
            size: 72,
            color: Colors.white30,
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
