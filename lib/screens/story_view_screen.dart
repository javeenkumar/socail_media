// // story_view_screen.dart - Create this missing file
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:video_player/video_player.dart';
// import '../controllers/story_controller.dart';
// import '../models/story_model.dart';
//
// class StoryViewScreen extends StatefulWidget {
//   final Story story;
//
//   const StoryViewScreen({Key? key, required this.story}) : super(key: key);
//
//   @override
//   State<StoryViewScreen> createState() => _StoryViewScreenState();
// }
//
// class _StoryViewScreenState extends State<StoryViewScreen> {
//   final StoryController controller = Get.find();
//   VideoPlayerController? _videoController;
//   int _currentItemIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeMedia();
//     // Mark as viewed
//     final userId = controller.currentUserId;
//     if (userId.isNotEmpty) {
//       controller.viewStory(widget.story, userId);
//     }
//   }
//
//   void _initializeMedia() {
//     if (widget.story.items.isNotEmpty) {
//       final item = widget.story.items[_currentItemIndex];
//       if (item.mediaType == 'video') {
//         _videoController = VideoPlayerController.network(item.mediaUrl)
//           ..initialize().then((_) {
//             setState(() {});
//             _videoController?.play();
//           });
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _videoController?.dispose();
//     super.dispose();
//   }
//
//   void _nextItem() {
//     if (_currentItemIndex < widget.story.items.length - 1) {
//       setState(() {
//         _currentItemIndex++;
//         _initializeMedia();
//       });
//     } else {
//       Get.back();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: GestureDetector(
//         onTap: _nextItem,
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             // Media Content
//             _buildMediaContent(),
//
//             // Progress Indicator
//             Positioned(
//               top: 40,
//               left: 10,
//               right: 10,
//               child: Row(
//                 children: widget.story.items.asMap().entries.map((entry) {
//                   return Expanded(
//                     child: Container(
//                       height: 2,
//                       margin: EdgeInsets.symmetric(horizontal: 2),
//                       color: entry.key <= _currentItemIndex
//                           ? Colors.white
//                           : Colors.white24,
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//
//             // User Info
//             Positioned(
//               top: 50,
//               left: 16,
//               child: Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 20,
//                     backgroundImage: widget.story.userProfilePic != null
//                         ? NetworkImage(widget.story.userProfilePic!)
//                         : null,
//                     child: widget.story.userProfilePic == null
//                         ? Icon(Icons.person)
//                         : null,
//                   ),
//                   SizedBox(width: 12),
//                   Text(
//                     widget.story.userName,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Close Button
//             Positioned(
//               top: 50,
//               right: 16,
//               child: IconButton(
//                 icon: Icon(Icons.close, color: Colors.white),
//                 onPressed: () => Get.back(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMediaContent() {
//     if (widget.story.items.isEmpty) {
//       // Legacy story without items
//       if (widget.story.mediaType == 'video') {
//         return VideoPlayerWidget(url: widget.story.mediaUrl);
//       }
//       return Image.network(
//         widget.story.mediaUrl,
//         fit: BoxFit.contain,
//       );
//     }
//
//     final item = widget.story.items[_currentItemIndex];
//
//     if (item.mediaType == 'video') {
//       return _videoController != null && _videoController!.value.isInitialized
//           ? AspectRatio(
//         aspectRatio: _videoController!.value.aspectRatio,
//         child: VideoPlayer(_videoController!),
//       )
//           : Center(child: CircularProgressIndicator());
//     }
//
//     return Image.network(
//       item.mediaUrl,
//       fit: BoxFit.contain,
//     );
//   }
// }
//
// class VideoPlayerWidget extends StatefulWidget {
//   final String url;
//
//   const VideoPlayerWidget({Key? key, required this.url}) : super(key: key);
//
//   @override
//   State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
// }
//
// class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
//   late VideoPlayerController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.network(widget.url)
//       ..initialize().then((_) {
//         setState(() {});
//         _controller.play();
//         _controller.setLooping(true);
//       });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return _controller.value.isInitialized
//         ? AspectRatio(
//       aspectRatio: _controller.value.aspectRatio,
//       child: VideoPlayer(_controller),
//     )
//         : Center(child: CircularProgressIndicator());
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../controllers/story_controller.dart';
import '../models/story_model.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Story> stories;   // all stories for this user
  final int startIndex;

  const StoryViewScreen({
    Key? key,
    required this.stories,
    this.startIndex = 0,
  }) : super(key: key);

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  final StoryController controller = Get.find();

  late int _storyIndex;   // which Story in the list
  int _itemIndex = 0;     // which StoryItem inside that Story

  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _storyIndex = widget.startIndex;
    _initMedia();
    _markViewed();
  }

  Story get _currentStory => widget.stories[_storyIndex];

  // Current item, falling back gracefully for legacy stories without items
  StoryItem? get _currentItem =>
      _currentStory.items.isNotEmpty ? _currentStory.items[_itemIndex] : null;

  String get _mediaUrl => _currentItem?.mediaUrl ?? _currentStory.mediaUrl;
  String get _mediaType => _currentItem?.mediaType ?? _currentStory.mediaType;

  void _initMedia() {
    _videoController?.dispose();
    _videoController = null;

    if (_mediaType == 'video') {
      _videoController = VideoPlayerController.network(_mediaUrl)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController?.play();
          }
        });
    }
  }

  void _markViewed() {
    final userId = controller.currentUserId;
    if (userId.isEmpty) return;
    controller.viewStory(
      _currentStory,
      userId,
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _goNext() {
    final items = _currentStory.items;
    final hasMoreItems = items.isNotEmpty && _itemIndex < items.length - 1;

    if (hasMoreItems) {
      setState(() => _itemIndex++);
      _initMedia();
    } else {
      _nextStory();
    }
  }

  void _goPrev() {
    if (_itemIndex > 0) {
      setState(() => _itemIndex--);
      _initMedia();
    } else {
      _prevStory();
    }
  }

  void _nextStory() {
    if (_storyIndex < widget.stories.length - 1) {
      setState(() {
        _storyIndex++;
        _itemIndex = 0;
      });
      _initMedia();
      _markViewed();
    } else {
      Get.back(); // end of all stories for this user
    }
  }

  void _prevStory() {
    if (_storyIndex > 0) {
      setState(() {
        _storyIndex--;
        _itemIndex = 0;
      });
      _initMedia();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            _goPrev();
          } else {
            _goNext();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMedia(),
            _buildProgressBars(),
            _buildUserInfo(),
            _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    if (_mediaType == 'video') {
      if (_videoController != null && _videoController!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        );
      }
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return Image.network(_mediaUrl, fit: BoxFit.contain);
  }

  Widget _buildProgressBars() {
    // Total segments = items count (or 1 for legacy stories)
    final total = _currentStory.items.isNotEmpty
        ? _currentStory.items.length
        : 1;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 10,
      right: 10,
      child: Row(
        children: List.generate(total, (i) {
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i <= _itemIndex ? Colors.white : Colors.white24,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 16,
      right: 60,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: _currentStory.userProfilePic != null
                ? NetworkImage(_currentStory.userProfilePic!)
                : null,
            child: _currentStory.userProfilePic == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentStory.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              // Show e.g. "2 / 3" when user has multiple stories
              if (widget.stories.length > 1)
                Text(
                  '${_storyIndex + 1} / ${widget.stories.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      right: 16,
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Get.back(),
      ),
    );
  }
}