import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../data/models/video_model.dart';
import '../services/video_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

/// Full-featured cinematic YouTube video screen.
/// Playlist is loaded live from Firestore `videos` collection via [VideoService].
class HistoryVideoScreen extends StatefulWidget {
  final int initialIndex;

  const HistoryVideoScreen({super.key, this.initialIndex = 0});

  @override
  State<HistoryVideoScreen> createState() => _HistoryVideoScreenState();
}

class _HistoryVideoScreenState extends State<HistoryVideoScreen> {
  final _videoService = VideoService();

  List<VideoModel> _playlist = [];
  bool _loaded = false;
  StreamSubscription<List<VideoModel>>? _sub;

  YoutubePlayerController? _controller;
  int _currentIndex = 0;
  bool _isFullscreen = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _sub = _videoService.watchVideos().listen(
      (videos) {
        if (!mounted) return;
        final wasEmpty = _playlist.isEmpty;
        setState(() {
          _playlist = videos;
          _loaded = true;
          _currentIndex =
              _currentIndex.clamp(0, videos.isEmpty ? 0 : videos.length - 1);
        });
        if (wasEmpty && videos.isNotEmpty) {
          _initPlayer(videos[_currentIndex].youtubeId);
          _checkSavedStatus();
        }
      },
      onError: (_) {
        if (mounted) setState(() => _loaded = true);
      },
    );
  }

  void _checkSavedStatus() async {
    if (_playlist.isEmpty) return;
    final videoId = _playlist[_currentIndex].youtubeId;
    final saved = await UserService.isVideoSaved(videoId);
    if (mounted) setState(() => _isSaved = saved);
  }

  void _initPlayer(String videoId) {
    _controller?.removeListener(_onPlayerStateChange);
    _controller?.dispose();
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        controlsVisibleAtStart: true,
      ),
    )..addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (!mounted || _controller == null) return;
    final isFS = _controller!.value.isFullScreen;
    if (isFS != _isFullscreen) {
      setState(() => _isFullscreen = isFS);
      SystemChrome.setPreferredOrientations(isFS
          ? [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : [DeviceOrientation.portraitUp]);
    }
  }

  void _switchVideo(int index) {
    if (index == _currentIndex || _controller == null) return;
    setState(() => _currentIndex = index);
    _controller!.load(_playlist[index].youtubeId);
    _checkSavedStatus();
  }

  Future<void> _toggleSaveVideo() async {
    final video = _playlist[_currentIndex];
    try {
      if (_isSaved) {
        await UserService.removeSavedVideo(video.youtubeId);
        if (mounted) {
          setState(() => _isSaved = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Видео хадгалалтаас хасагдлаа'),
              backgroundColor: AppTheme.surface,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await UserService.saveVideo(video.youtubeId, video.title);
        if (mounted) {
          setState(() => _isSaved = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Видео амжилттай хадгалагдлаа'),
              backgroundColor: AppTheme.accentGold,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Алдаа гарлаа: $e'),
            backgroundColor: AppTheme.crimson,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _shareVideo() {
    final video = _playlist[_currentIndex];
    final youtubeLink = 'https://www.youtube.com/watch?v=${video.youtubeId}';
    Clipboard.setData(ClipboardData(text: youtubeLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied'),
        backgroundColor: AppTheme.accentGold,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller?.removeListener(_onPlayerStateChange);
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentGold),
        ),
      );
    }

    if (_playlist.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: const Center(
          child: Text('Видео олдсонгүй.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    return YoutubePlayerBuilder(
      onEnterFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      },
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      },
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppTheme.accentGold,
        progressColors: const ProgressBarColors(
          playedColor: AppTheme.accentGold,
          handleColor: AppTheme.accentGold,
          bufferedColor: Color(0x40F4C84A),
          backgroundColor: Color(0x20FFFFFF),
        ),
        topActions: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _playlist[_currentIndex].title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      builder: (context, player) => _buildScaffold(player),
    );
  }

  Widget _buildScaffold(Widget player) {
    final current = _playlist[_currentIndex];
    final accent = VideoModel.colorFromHex(current.accentHex);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildPlayerSection(player),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.pagePadding, 18, AppTheme.pagePadding, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVideoMeta(current, accent),
                  const SizedBox(height: 24),
                  _buildPlaylistSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Player + back button ──────────────────────────────────────
  Widget _buildPlayerSection(Widget player) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          player,
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.55),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15), width: 1),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Current video title + meta ────────────────────────────────
  Widget _buildVideoMeta(VideoModel current, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_outline_rounded, color: accent, size: 13),
              const SizedBox(width: 4),
              Text(
                current.duration,
                style: AppTheme.caption.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(current.title,
            style: AppTheme.h2.copyWith(fontSize: 19, height: 1.3)),
        const SizedBox(height: 6),
        Text(current.subtitle, style: AppTheme.body.copyWith(height: 1.6)),
        const SizedBox(height: 14),
        Row(
          children: [
            _ActionChip(
                icon: _isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: 'Хадгалах',
                accent: _isSaved ? AppTheme.accentGold : AppTheme.textSecondary,
                active: _isSaved,
                activeColor: AppTheme.accentGold,
                onTap: _toggleSaveVideo),
            const SizedBox(width: 10),
            _ActionChip(
                icon: Icons.share_outlined,
                label: 'Хуваалцах',
                accent: AppTheme.textSecondary,
                onTap: _shareVideo),
          ],
        ),
      ],
    );
  }

  // ── Playlist ─────────────────────────────────────────────────
  Widget _buildPlaylistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.video_library_rounded,
                color: AppTheme.accentGold, size: 18),
            const SizedBox(width: 8),
            Text('Хичээлүүд', style: AppTheme.sectionTitle),
            const Spacer(),
            Text('${_playlist.length} видео', style: AppTheme.caption),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_playlist.length, (i) {
          final v = _playlist[i];
          final accent = VideoModel.colorFromHex(v.accentHex);
          final icon = VideoModel.iconFromName(v.iconName);
          final isActive = i == _currentIndex;
          return GestureDetector(
            onTap: () => _switchVideo(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? accent.withValues(alpha: 0.10)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isActive
                      ? accent.withValues(alpha: 0.40)
                      : AppTheme.cardBorder,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.25)),
                    ),
                    child: isActive
                        ? Icon(Icons.pause_circle_filled_rounded,
                            color: accent, size: 28)
                        : Icon(icon, color: accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.title,
                          style: AppTheme.captionBold.copyWith(
                            fontSize: 13,
                            color: isActive ? accent : AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 11, color: AppTheme.textSecondary),
                            const SizedBox(width: 3),
                            Text(v.duration,
                                style: AppTheme.caption.copyWith(fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 6,
                      height: 24,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Small action chip ──────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool active;
  final Color? activeColor;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.accent,
    this.active = false,
    this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? (activeColor ?? accent).withValues(alpha: 0.14)
        : AppTheme.surfaceLight;
    final border = active
        ? (activeColor ?? accent).withValues(alpha: 0.45)
        : AppTheme.cardBorder;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
