import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../controllers/create_reel_controller.dart';

/// This is the screen shown AFTER a video is selected/recorded.
/// The user can preview the clip, write a caption, add hashtags, then tap Share.
///
/// Register it in main.dart getPages:
///   GetPage(name: '/create-reel-preview', page: () => CreateReelPreviewScreen()),
class CreateReelPreviewScreen extends StatefulWidget {
  const CreateReelPreviewScreen({Key? key}) : super(key: key);

  @override
  State<CreateReelPreviewScreen> createState() => _CreateReelPreviewScreenState();
}

class _CreateReelPreviewScreenState extends State<CreateReelPreviewScreen> {
  // Use Get.find() — controller is already put() in HomeScreen.initState()
  final CreateReelController controller = Get.find<CreateReelController>();

  VideoPlayerController? _videoController;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  bool _isPlaying = true;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _captionController.addListener(() {
      controller.updateCaption(_captionController.text);
    });
  }

  Future<void> _initVideo() async {
    final file = controller.selectedVideo.value;
    if (file == null) return;

    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.play();

    if (mounted) setState(() => _videoReady = true);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_videoController == null) return;
    setState(() {
      _isPlaying = !_isPlaying;
      _isPlaying ? _videoController!.play() : _videoController!.pause();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // ── Upload progress overlay ──────────────────────────────────────────
      body: Obx(() {
        if (controller.isUploading.value) return _buildUploadProgress();

        return Column(
          children: [
            // ── Video preview (top 55 %) ─────────────────────────────────
            Expanded(
              flex: 55,
              child: GestureDetector(
                onTap: _togglePlay,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _videoReady && _videoController != null
                        ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                        : const Center(
                        child: CircularProgressIndicator(color: Colors.white)),

                    // Back button
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Get.back(),
                        ),
                      ),
                    ),

                    // Play/pause icon
                    if (!_isPlaying)
                      const Center(
                        child: Icon(Icons.play_arrow, size: 72, color: Colors.white70),
                      ),

                    // Duration badge
                    Positioned(
                      bottom: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Obx(() => Text(
                          '${controller.videoDuration.value}s',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        )),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Edit panel (bottom 45 %) ──────────────────────────────────
            Expanded(
              flex: 45,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Caption
                      TextField(
                        controller: _captionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        maxLength: 2200,
                        decoration: InputDecoration(
                          hintText: 'Write a caption...',
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          border: InputBorder.none,
                          counterStyle: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),

                      Divider(color: Colors.grey.shade800),

                      // Hashtag input
                      Row(
                        children: [
                          const Icon(Icons.tag, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _hashtagController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Add hashtag...',
                                hintStyle: TextStyle(color: Colors.grey.shade600),
                                border: InputBorder.none,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.add, color: Colors.blue),
                                  onPressed: () {
                                    controller.addHashtag(_hashtagController.text);
                                    _hashtagController.clear();
                                  },
                                ),
                              ),
                              onSubmitted: (v) {
                                controller.addHashtag(v);
                                _hashtagController.clear();
                              },
                            ),
                          ),
                        ],
                      ),

                      // Hashtag chips
                      Obx(() {
                        if (controller.hashtags.isEmpty) return const SizedBox.shrink();
                        return Wrap(
                          spacing: 8,
                          children: controller.hashtags
                              .map((tag) => Chip(
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            label: Text('#$tag',
                                style: const TextStyle(color: Colors.blue)),
                            deleteIcon: const Icon(Icons.close,
                                size: 14, color: Colors.blue),
                            onDeleted: () => controller.removeHashtag(tag),
                          ))
                              .toList(),
                        );
                      }),

                      const SizedBox(height: 8),
                      Divider(color: Colors.grey.shade800),

                      // Comments toggle
                      Obx(() => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary:
                        const Icon(Icons.comment, color: Colors.white70),
                        title: const Text('Comments',
                            style: TextStyle(color: Colors.white)),
                        value: controller.allowComments.value,
                        activeColor: Colors.blue,
                        onChanged: (v) => controller.allowComments.value = v,
                      )),

                      // Duet toggle
                      Obx(() => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary:
                        const Icon(Icons.people, color: Colors.white70),
                        title: const Text('Allow Duet',
                            style: TextStyle(color: Colors.white)),
                        value: controller.allowDuet.value,
                        activeColor: Colors.blue,
                        onChanged: (v) => controller.allowDuet.value = v,
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),

      // ── Bottom action bar ──────────────────────────────────────────────
      bottomSheet: Obx(() => controller.isUploading.value
          ? const SizedBox.shrink()
          : _buildBottomBar()),
    );
  }

  Widget _buildUploadProgress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Obx(() => CircularProgressIndicator(
              value: controller.uploadProgress.value,
              strokeWidth: 8,
              backgroundColor: Colors.grey.shade800,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            )),
          ),
          const SizedBox(height: 24),
          Obx(() => Text(
            '${(controller.uploadProgress.value * 100).toInt()}%',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          )),
          const SizedBox(height: 8),
          const Text('Uploading your reel...',
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () {
                  Get.snackbar('Drafts', 'Saved to drafts',
                      backgroundColor: Colors.grey.shade800,
                      colorText: Colors.white);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Drafts',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                // ✅ Calls uploadReel() which fixes the Firestore ID + navigation
                onPressed: () => controller.uploadReel(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Share',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}