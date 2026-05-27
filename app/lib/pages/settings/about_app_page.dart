import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class _VideoItem {
  final String assetPath;
  final String name;

  const _VideoItem({required this.assetPath, required this.name});
}

const List<_VideoItem> _videos = [
  _VideoItem(assetPath: 'assets/nl', name: '奶龙唐笑'),
  _VideoItem(assetPath: 'assets/emeifeng', name: '峨眉峰'),
];

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPlayer(_currentIndex);
  }

  Future<void> _initPlayer(int index) async {
    _controller?.dispose();

    setState(() {
      _isInitialized = false;
      _isPlaying = false;
      _isSwitching = true;
    });

    WakelockPlus.disable();

    _controller = VideoPlayerController.asset(_videos[index].assetPath);
    await _controller!.initialize();
    _controller!.setLooping(true);

    if (!mounted) return;

    setState(() {
      _isInitialized = true;
      _isSwitching = false;
    });
  }

  void _switchVideo(int direction) {
    final newIndex = (_currentIndex + direction) % _videos.length;
    final actualIndex = newIndex < 0 ? _videos.length - 1 : newIndex;

    if (actualIndex == _currentIndex) return;

    _currentIndex = actualIndex;
    _initPlayer(_currentIndex);
  }

  void _togglePlayPause() {
    if (!_isInitialized || _controller == null) return;

    setState(() {
      if (_isPlaying) {
        _controller!.pause();
        _controller!.seekTo(Duration.zero);
        _isPlaying = false;
        WakelockPlus.disable();
      } else {
        _controller!.play();
        _isPlaying = true;
        WakelockPlus.enable();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized || _controller == null) return;

    if (state == AppLifecycleState.paused) {
      _controller!.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TopNavBar(
        title: '关于APP',
        showBack: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                if (_isInitialized && _controller != null)
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                if (_isInitialized && _controller != null) ...[
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _videos[_currentIndex].name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _switchVideo(-1),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A)
                                  .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _switchVideo(1),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A)
                                  .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Material(
                      color: const Color(0xFF1A1A1A).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: _togglePlayPause,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          child: Text(
                            _isPlaying ? '停止' : '循环播放',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isSwitching)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingM,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '地铁跑酷换乘助手',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Subway Surfers Transfer Helper',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingM),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: AppTheme.borderRadiusM,
                    ),
                    child: Text(
                      '版本 1.0.2',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
