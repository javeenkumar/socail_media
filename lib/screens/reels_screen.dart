// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:video_player/video_player.dart';
// import '../controllers/create_reel_controller.dart';
//
// class ReelsScreen extends StatefulWidget {
//   final CreateReelController controller;
//
//   const ReelsScreen({
//     Key? key,
//     required this.controller,
//   }) : super(key: key);
//
//   @override
//   State<ReelsScreen> createState() => _ReelsScreenState();
// }
//
// class _ReelsScreenState extends State<ReelsScreen> {
//   late VideoPlayerController _videoController;
//   final TextEditingController _captionController = TextEditingController();
//   final TextEditingController _hashtagController = TextEditingController();
//   bool _isPlaying = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeVideo();
//     _captionController.addListener(() {
//       widget.controller.updateCaption(_captionController.text);
//     });
//   }
//
//   void _initializeVideo() {
//     _videoController = VideoPlayerController.file(widget.controller.selectedVideo.value!)
//       ..initialize().then((_) {
//         setState(() {});
//         _videoController.play();
//         _videoController.setLooping(true);
//       });
//   }
//
//   @override
//   void dispose() {
//     _videoController.dispose();
//     _captionController.dispose();
//     _hashtagController.dispose();
//     super.dispose();
//   }
//
//   void _togglePlay() {
//     setState(() {
//       _isPlaying = !_isPlaying;
//       if (_isPlaying) {
//         _videoController.play();
//       } else {
//         _videoController.pause();
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Obx(() {
//         if (widget.controller.isUploading.value) {
//           return _buildUploadProgress();
//         }
//
//         return Column(
//           children: [
//             // Video Preview
//             Expanded(
//               flex: 3,
//               child: GestureDetector(
//                 onTap: _togglePlay,
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     // Video
//                     _videoController.value.isInitialized
//                         ? AspectRatio(
//                       aspectRatio: _videoController.value.aspectRatio,
//                       child: VideoPlayer(_videoController),
//                     )
//                         : const Center(child: CircularProgressIndicator()),
//
//                     // Play/Pause Overlay
//                     if (!_isPlaying)
//                       Container(
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.5),
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(
//                           Icons.play_arrow,
//                           size: 60,
//                           color: Colors.white,
//                         ),
//                       ),
//
//                     // Top Controls
//                     Positioned(
//                       top: 40,
//                       left: 16,
//                       child: IconButton(
//                         icon: const Icon(Icons.arrow_back, color: Colors.white),
//                         onPressed: () => Get.back(),
//                       ),
//                     ),
//
//                     // Video Info Overlay
//                     Positioned(
//                       bottom: 16,
//                       right: 16,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.6),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: Text(
//                           '${widget.controller.videoDuration.value}s',
//                           style: const TextStyle(color: Colors.white, fontSize: 12),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             // Edit Controls
//             Expanded(
//               flex: 2,
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFF1A1A1A),
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//                 ),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Caption Input
//                       TextField(
//                         controller: _captionController,
//                         style: const TextStyle(color: Colors.white),
//                         maxLines: 3,
//                         maxLength: 2200,
//                         decoration: InputDecoration(
//                           hintText: 'Write a caption...',
//                           hintStyle: TextStyle(color: Colors.grey.shade600),
//                           border: InputBorder.none,
//                           counterStyle: TextStyle(color: Colors.grey.shade600),
//                         ),
//                       ),
//
//                       const Divider(color: Colors.grey),
//
//                       // Hashtags
//                       Row(
//                         children: [
//                           const Icon(Icons.tag, color: Colors.blue, size: 20),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: TextField(
//                               controller: _hashtagController,
//                               style: const TextStyle(color: Colors.white),
//                               decoration: InputDecoration(
//                                 hintText: 'Add hashtags...',
//                                 hintStyle: TextStyle(color: Colors.grey.shade600),
//                                 border: InputBorder.none,
//                                 suffixIcon: IconButton(
//                                   icon: const Icon(Icons.add, color: Colors.blue),
//                                   onPressed: () {
//                                     widget.controller.addHashtag(_hashtagController.text);
//                                     _hashtagController.clear();
//                                   },
//                                 ),
//                               ),
//                               onSubmitted: (value) {
//                                 widget.controller.addHashtag(value);
//                                 _hashtagController.clear();
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       // Display hashtags
//                       Obx(() {
//                         if (widget.controller.hashtags.isEmpty) {
//                           return const SizedBox.shrink();
//                         }
//                         return Container(
//                           margin: const EdgeInsets.only(top: 8),
//                           height: 40,
//                           child: ListView.builder(
//                             scrollDirection: Axis.horizontal,
//                             itemCount: widget.controller.hashtags.length,
//                             itemBuilder: (context, index) {
//                               final tag = widget.controller.hashtags[index];
//                               return Container(
//                                 margin: const EdgeInsets.only(right: 8),
//                                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue.withOpacity(0.2),
//                                   borderRadius: BorderRadius.circular(20),
//                                 ),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Text(
//                                       '#$tag',
//                                       style: const TextStyle(color: Colors.blue),
//                                     ),
//                                     const SizedBox(width: 4),
//                                     GestureDetector(
//                                       onTap: () => widget.controller.removeHashtag(tag),
//                                       child: const Icon(Icons.close, size: 14, color: Colors.blue),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           ),
//                         );
//                       }),
//
//                       const SizedBox(height: 16),
//
//                       // Settings
//                       _buildSettingTile(
//                         icon: Icons.music_note,
//                         title: 'Audio',
//                         subtitle: widget.controller.audioTitle.value,
//                         onTap: () => _showAudioPicker(),
//                       ),
//
//                       _buildSettingTile(
//                         icon: Icons.comment,
//                         title: 'Comments',
//                         subtitle: widget.controller.allowComments.value ? 'On' : 'Off',
//                         trailing: Obx(() => Switch(
//                           value: widget.controller.allowComments.value,
//                           onChanged: (value) => widget.controller.allowComments.value = value,
//                           activeColor: Colors.blue,
//                         )),
//                       ),
//
//                       _buildSettingTile(
//                         icon: Icons.people,
//                         title: 'Allow Duet',
//                         subtitle: widget.controller.allowDuet.value ? 'On' : 'Off',
//                         trailing: Obx(() => Switch(
//                           value: widget.controller.allowDuet.value,
//                           onChanged: (value) => widget.controller.allowDuet.value = value,
//                           activeColor: Colors.blue,
//                         )),
//                       ),
//
//                       const SizedBox(height: 80),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       }),
//       bottomSheet: _buildBottomBar(),
//     );
//   }
//
//   Widget _buildUploadProgress() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           SizedBox(
//             width: 100,
//             height: 100,
//             child: Obx(() => CircularProgressIndicator(
//               value: widget.controller.uploadProgress.value,
//               strokeWidth: 8,
//               backgroundColor: Colors.grey.shade800,
//               valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
//             )),
//           ),
//           const SizedBox(height: 24),
//           Obx(() => Text(
//             '${(widget.controller.uploadProgress.value * 100).toInt()}%',
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           )),
//           const SizedBox(height: 8),
//           const Text(
//             'Uploading your reel...',
//             style: TextStyle(color: Colors.white70),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSettingTile({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     Widget? trailing,
//     VoidCallback? onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.white70),
//       title: Text(title, style: const TextStyle(color: Colors.white)),
//       subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
//       trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.white70),
//       onTap: onTap,
//     );
//   }
//
//   Widget _buildBottomBar() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1A1A1A),
//         border: Border(top: BorderSide(color: Colors.grey.shade800)),
//       ),
//       child: SafeArea(
//         child: Row(
//           children: [
//             // Drafts Button
//             Expanded(
//               flex: 1,
//               child: OutlinedButton(
//                 onPressed: () {
//                   Get.snackbar(
//                     'Drafts',
//                     'Saved to drafts',
//                     backgroundColor: Colors.grey.shade800,
//                     colorText: Colors.white,
//                   );
//                 },
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Colors.white),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                 ),
//                 child: const Text(
//                   'Drafts',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//
//             const SizedBox(width: 16),
//
//             // Share Button
//             Expanded(
//               flex: 2,
//               child: ElevatedButton(
//                 onPressed: () => widget.controller.uploadReel(),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                 ),
//                 child: const Text(
//                   'Share',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showAudioPicker() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: 300,
//         decoration: const BoxDecoration(
//           color: Color(0xFF1A1A1A),
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           children: [
//             Container(
//               margin: const EdgeInsets.only(top: 8),
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const Padding(
//               padding: EdgeInsets.all(16),
//               child: Text(
//                 'Select Audio',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             Expanded(
//               child: ListView(
//                 children: [
//                   _buildAudioOption('Original Audio', true),
//                   _buildAudioOption('Trending Song 1', false),
//                   _buildAudioOption('Trending Song 2', false),
//                   _buildAudioOption('My Music', false),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAudioOption(String title, bool isOriginal) {
//     return ListTile(
//       leading: Container(
//         width: 50,
//         height: 50,
//         decoration: BoxDecoration(
//           color: Colors.grey.shade800,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: const Icon(Icons.music_note, color: Colors.white),
//       ),
//       title: Text(title, style: const TextStyle(color: Colors.white)),
//       subtitle: isOriginal
//           ? const Text('Your original audio', style: TextStyle(color: Colors.grey))
//           : null,
//       trailing: Obx(() => widget.controller.audioTitle.value == title
//           ? const Icon(Icons.check_circle, color: Colors.blue)
//           : const SizedBox.shrink()),
//       onTap: () {
//         widget.controller.audioTitle.value = title;
//         Get.back();
//       },
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reels_controller.dart';
import '../models/reel_model.dart';
import '../widgets/reel_card.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({Key? key}) : super(key: key);

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}


class _ReelsScreenState extends State<ReelsScreen> {
  late final ReelsController controller;
  final PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    controller = Get.find<ReelsController>();

    // Refresh when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshReels();
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await controller.refreshReels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Reels',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.refreshReels(),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () => _navigateToCreateReel(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.reels.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        if (controller.reels.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.video_library,
                  size: 64,
                  color: Colors.white54,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No reels yet',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _navigateToCreateReel(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Create First Reel'),
                ),
              ],
            ),
          );
        }

        // Pull to refresh wrapper
        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: Colors.white,
          backgroundColor: Colors.black,
          child: PageView.builder(
            scrollDirection: Axis.vertical,
            controller: pageController,
            itemCount: controller.reels.length,
            onPageChanged: (index) {
              controller.onPageChanged(index);
            },
            itemBuilder: (context, index) {
              final reel = controller.reels[index];
              return ReelCard(
                reel: reel,
                isCurrentPage: index == controller.currentIndex.value,
                onLike: () => controller.likeReel(reel),
                onComment: () => _showComments(reel),
                onShare: () => controller.shareReel(reel),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.white,
        onPressed: () => _navigateToCreateReel(),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Create',
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  void _navigateToCreateReel() {
    try {
      Get.toNamed('/create-reel');
    } catch (e) {
      debugPrint('Navigation error: $e');
      Get.snackbar(
        'Error',
        'Cannot open create reel screen',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showComments(Reel reel) {
    final currentUserId = controller.currentUserId;
    if (currentUserId.isEmpty) {
      Get.snackbar('Error', 'Please login to comment',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${reel.commentsCount} Comments',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: reel.comments.isEmpty
                    ? const Center(
                  child: Text(
                    'No comments yet.\nBe the first to comment!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: reel.comments.length,
                  itemBuilder: (context, index) {
                    final comment = reel.comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(comment.userPic),
                        onBackgroundImageError: (_, __) {},
                      ),
                      title: Text(
                        comment.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        comment.text,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Text(
                        _formatTimestamp(comment.timestamp),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade800),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () {
                          final text = commentController.text.trim();
                          if (text.isNotEmpty) {
                            controller.addComment(
                              reel,
                              text,
                              currentUserId,
                              'Current User',
                              'https://example.com/pic.jpg',
                            );
                            commentController.clear();
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }
}