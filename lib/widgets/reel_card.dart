// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:visibility_detector/visibility_detector.dart';
// import '../models/reel_model.dart';
//
// class ReelCard extends StatefulWidget {
//   final Reel reel;
//   final VoidCallback onLike;
//   final VoidCallback onComment;
//   final VoidCallback onShare;
//   final bool isCurrentPage;
//
//   const ReelCard({
//     Key? key,
//     required this.reel,
//     required this.onLike,
//     required this.onComment,
//     required this.onShare,
//     this.isCurrentPage = false,
//   }) : super(key: key);
//
//   @override
//   State<ReelCard> createState() => _ReelCardState();
// }
//
// class _ReelCardState extends State<ReelCard> {
//   VideoPlayerController? _controller;
//   bool _isPlaying = true;
//   bool _showHeart = false;
//   bool _isInitialized = false;
//   bool _hasError = false;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeVideo();
//   }
//
//   Future<void> _initializeVideo() async {
//     if (widget.reel.videoUrl.isEmpty) {
//       setState(() {
//         _hasError = true;
//         _errorMessage = 'Video URL is empty';
//       });
//       return;
//     }
//
//     try {
//       // Dispose old controller if exists
//       await _controller?.dispose();
//
//       _controller = VideoPlayerController.networkUrl(
//         Uri.parse(widget.reel.videoUrl),
//         videoPlayerOptions: VideoPlayerOptions(
//           mixWithOthers: true,
//         ),
//       );
//
//       // Add listener for video updates
//       _controller!.addListener(_onVideoUpdate);
//
//       await _controller!.initialize();
//
//       if (mounted) {
//         setState(() {
//           _isInitialized = true;
//           _hasError = false;
//         });
//
//         // Auto-play if this is the current page
//         if (widget.isCurrentPage) {
//           _controller!.play();
//           _controller!.setLooping(true);
//         }
//       }
//     } catch (error) {
//       debugPrint('❌ Video initialization error: $error');
//       if (mounted) {
//         setState(() {
//           _hasError = true;
//           _errorMessage = error.toString();
//         });
//       }
//     }
//   }
//
//   void _onVideoUpdate() {
//     // Rebuild when video state changes
//     if (mounted && _controller != null) {
//       // Check if video completed and restart if needed
//       if (_controller!.value.position >= _controller!.value.duration) {
//         _controller!.seekTo(Duration.zero);
//         _controller!.play();
//       }
//     }
//   }
//
//   @override
//   void didUpdateWidget(ReelCard oldWidget) {
//     super.didUpdateWidget(oldWidget);
//
//     // Handle play/pause based on visibility
//     if (oldWidget.isCurrentPage != widget.isCurrentPage) {
//       if (widget.isCurrentPage) {
//         _controller?.play();
//         _controller?.setLooping(true);
//       } else {
//         _controller?.pause();
//       }
//     }
//
//     // Handle URL changes
//     if (oldWidget.reel.videoUrl != widget.reel.videoUrl) {
//       _initializeVideo();
//     }
//   }
//
//   @override
//   void dispose() {
//     _controller?.removeListener(_onVideoUpdate);
//     _controller?.dispose();
//     super.dispose();
//   }
//
//   void _togglePlay() {
//     if (_controller == null || !_isInitialized) return;
//
//     setState(() {
//       _isPlaying = !_isPlaying;
//       if (_isPlaying) {
//         _controller!.play();
//       } else {
//         _controller!.pause();
//       }
//     });
//   }
//
//   void _doubleTap() {
//     if (!widget.reel.isLiked) {
//       setState(() => _showHeart = true);
//       widget.onLike();
//       Future.delayed(const Duration(milliseconds: 800), () {
//         if (mounted) setState(() => _showHeart = false);
//       });
//     } else {
//       widget.onLike();
//     }
//   }
//
//   void _onVisibilityChanged(VisibilityInfo info) {
//     if (_controller == null || !_isInitialized) return;
//
//     var visiblePercentage = info.visibleFraction * 100;
//
//     if (visiblePercentage > 50) {
//       _controller!.play();
//       _controller!.setLooping(true);
//       setState(() => _isPlaying = true);
//     } else {
//       _controller!.pause();
//       setState(() => _isPlaying = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return VisibilityDetector(
//       key: Key(widget.reel.id),
//       onVisibilityChanged: _onVisibilityChanged,
//       child: GestureDetector(
//         onTap: _togglePlay,
//         onDoubleTap: _doubleTap,
//         child: Container(
//           color: Colors.black,
//           child: Stack(
//             fit: StackFit.expand,
//             children: [
//               // Video Player
//               _buildVideoPlayer(),
//
//               // Play/Pause Indicator
//               if (!_isPlaying && _isInitialized)
//                 const Center(
//                   child: Icon(
//                     Icons.play_arrow,
//                     size: 80,
//                     color: Colors.white70,
//                   ),
//                 ),
//
//               // Double Tap Heart Animation
//               if (_showHeart)
//                 Center(
//                   child: TweenAnimationBuilder(
//                     tween: Tween<double>(begin: 0, end: 1),
//                     duration: const Duration(milliseconds: 400),
//                     builder: (context, value, child) {
//                       return Transform.scale(
//                         scale: value,
//                         child: const Icon(
//                           Icons.favorite,
//                           size: 100,
//                           color: Colors.red,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//
//               // Right Side Actions
//               _buildActionButtons(),
//
//               // Bottom Info
//               _buildBottomInfo(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildVideoPlayer() {
//     if (_hasError) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, color: Colors.white, size: 48),
//             const SizedBox(height: 8),
//             Text(
//               'Failed to load video',
//               style: const TextStyle(color: Colors.white),
//             ),
//             if (_errorMessage != null)
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Text(
//                   _errorMessage!,
//                   style: const TextStyle(color: Colors.grey, fontSize: 12),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//           ],
//         ),
//       );
//     }
//
//     if (!_isInitialized || _controller == null) {
//       return const Center(
//         child: CircularProgressIndicator(
//           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//         ),
//       );
//     }
//
//     return AspectRatio(
//       aspectRatio: _controller!.value.aspectRatio,
//       child: VideoPlayer(_controller!),
//     );
//   }
//
//   Widget _buildActionButtons() {
//     return Positioned(
//       right: 10,
//       bottom: 100,
//       child: Column(
//         children: [
//           _buildActionButton(
//             icon: widget.reel.isLiked ? Icons.favorite : Icons.favorite_border,
//             color: widget.reel.isLiked ? Colors.red : Colors.white,
//             label: '${widget.reel.likes.length}',
//             onTap: widget.onLike,
//           ),
//           const SizedBox(height: 20),
//           _buildActionButton(
//             icon: Icons.comment,
//             color: Colors.white,
//             label: '${widget.reel.commentsCount}',
//             onTap: widget.onComment,
//           ),
//           const SizedBox(height: 20),
//           _buildActionButton(
//             icon: Icons.share,
//             color: Colors.white,
//             label: 'Share',
//             onTap: widget.onShare,
//           ),
//           const SizedBox(height: 20),
//           _buildActionButton(
//             icon: Icons.more_vert,
//             color: Colors.white,
//             onTap: () => _showMoreOptions(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     String? label,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           Icon(icon, color: color, size: 35),
//           if (label != null) ...[
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBottomInfo() {
//     return Positioned(
//       left: 16,
//       right: 80,
//       bottom: 20,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               CircleAvatar(
//                 radius: 20,
//                 backgroundImage: NetworkImage(widget.reel.userProfilePic),
//                 onBackgroundImageError: (_, __) {},
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   widget.reel.userName,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.white),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: const Text(
//                   'Follow',
//                   style: TextStyle(color: Colors.white, fontSize: 12),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             widget.reel.caption,
//             style: const TextStyle(color: Colors.white, fontSize: 14),
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               const Icon(Icons.music_note, color: Colors.white, size: 16),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   widget.reel.audioTitle,
//                   style: const TextStyle(color: Colors.white70, fontSize: 12),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showMoreOptions() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         decoration: const BoxDecoration(
//           color: Colors.black87,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.flag, color: Colors.white),
//                 title: const Text('Report', style: TextStyle(color: Colors.white)),
//                 onTap: () => Navigator.pop(context),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.block, color: Colors.white),
//                 title: const Text('Not Interested', style: TextStyle(color: Colors.white)),
//                 onTap: () => Navigator.pop(context),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.link, color: Colors.white),
//                 title: const Text('Copy Link', style: TextStyle(color: Colors.white)),
//                 onTap: () => Navigator.pop(context),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/reel_model.dart';

class ReelCard extends StatefulWidget {
  final Reel reel;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final bool isCurrentPage;

  const ReelCard({
    Key? key,
    required this.reel,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.isCurrentPage = false,
  }) : super(key: key);

  @override
  State<ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends State<ReelCard> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isPlaying = false; // Start as false - don't auto-play
  bool _showHeart = false;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isAppInForeground = true;
  bool _isUserPaused = false; // Track if user manually paused

  @override
  void initState() {
    super.initState();
    // Register for app lifecycle events (background/foreground)
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onVideoUpdate);
    _controller?.dispose();
    super.dispose();
  }

  // Handle app going to background/foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized || _controller == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        // Only play if visible and user hasn't manually paused
        if (widget.isCurrentPage && !_isUserPaused) {
          _controller?.play();
          setState(() => _isPlaying = true);
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        _controller?.pause();
        setState(() => _isPlaying = false);
        break;
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.reel.videoUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Video URL is empty';
      });
      return;
    }

    try {
      await _controller?.dispose();

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.reel.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      _controller!.addListener(_onVideoUpdate);
      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
        // DON'T auto-play here - wait for visibility check
        // Video stays paused until visibility detector says it's >50% visible
      }
    } catch (error) {
      debugPrint('❌ Video initialization error: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = error.toString();
        });
      }
    }
  }

  void _onVideoUpdate() {
    if (!mounted || _controller == null) return;

    // Loop video when it ends
    if (_controller!.value.position >= _controller!.value.duration) {
      _controller!.seekTo(Duration.zero);
      if (_isPlaying && _isAppInForeground) {
        _controller!.play();
      }
    }
  }

  @override
  void didUpdateWidget(ReelCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle page changes
    if (oldWidget.isCurrentPage != widget.isCurrentPage) {
      if (widget.isCurrentPage && _isAppInForeground && !_isUserPaused) {
        _controller?.play();
        setState(() => _isPlaying = true);
      } else {
        _controller?.pause();
        setState(() => _isPlaying = false);
      }
    }

    // Handle URL changes
    if (oldWidget.reel.videoUrl != widget.reel.videoUrl) {
      _initializeVideo();
    }
  }

  void _togglePlay() {
    if (_controller == null || !_isInitialized) return;

    setState(() {
      if (_isPlaying) {
        _controller!.pause();
        _isUserPaused = true; // Remember user paused it
      } else {
        _controller!.play();
        _isUserPaused = false;
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _doubleTap() {
    if (!widget.reel.isLiked) {
      setState(() => _showHeart = true);
      widget.onLike();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showHeart = false);
      });
    } else {
      widget.onLike();
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_controller == null || !_isInitialized) return;

    final visiblePercentage = info.visibleFraction * 100;
    final wasVisible = _isPlaying;

    // Only play if >50% visible, app is in foreground, and user hasn't paused
    if (visiblePercentage > 50 && _isAppInForeground && !_isUserPaused) {
      if (!wasVisible) {
        _controller!.play();
        setState(() => _isPlaying = true);
      }
    } else {
      // Pause if not visible enough or app in background
      if (wasVisible) {
        _controller!.pause();
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('reel_${widget.reel.id}'), // More unique key
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: _togglePlay,
        onDoubleTap: _doubleTap,
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildVideoPlayer(),
              if (!_isPlaying && _isInitialized)
                const Center(
                  child: Icon(Icons.play_arrow, size: 80, color: Colors.white70),
                ),
              if (_showHeart)
                Center(
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: const Icon(Icons.favorite, size: 100, color: Colors.red),
                      );
                    },
                  ),
                ),
              _buildActionButtons(),
              _buildBottomInfo(),
            ],
          ),
        ),
      ),
    );
  }

  // ... keep _buildVideoPlayer(), _buildActionButtons(), _buildBottomInfo(), _showMoreOptions() same as before
  Widget _buildVideoPlayer() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 8),
            const Text('Failed to load video', style: TextStyle(color: Colors.white)),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
              ),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)));
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      right: 10,
      bottom: 100,
      child: Column(
        children: [
          _buildActionButton(
            icon: widget.reel.isLiked ? Icons.favorite : Icons.favorite_border,
            color: widget.reel.isLiked ? Colors.red : Colors.white,
            label: '${widget.reel.likes.length}',
            onTap: widget.onLike,
          ),
          const SizedBox(height: 20),
          _buildActionButton(icon: Icons.comment, color: Colors.white, label: '${widget.reel.commentsCount}', onTap: widget.onComment),
          const SizedBox(height: 20),
          _buildActionButton(icon: Icons.share, color: Colors.white, label: 'Share', onTap: widget.onShare),
          const SizedBox(height: 20),
          _buildActionButton(icon: Icons.more_vert, color: Colors.white, onTap: _showMoreOptions),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, String? label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 35),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Positioned(
      left: 16,
      right: 80,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundImage: NetworkImage(widget.reel.userProfilePic), onBackgroundImageError: (_, __) {}),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.reel.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(4)),
                child: const Text('Follow', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(widget.reel.caption, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.reel.audioTitle, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: const Icon(Icons.flag, color: Colors.white), title: const Text('Report', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
              ListTile(leading: const Icon(Icons.block, color: Colors.white), title: const Text('Not Interested', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
              ListTile(leading: const Icon(Icons.link, color: Colors.white), title: const Text('Copy Link', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}