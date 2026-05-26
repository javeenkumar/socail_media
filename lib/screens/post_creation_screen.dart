// post_creation_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/post_creation_controller.dart';

class PostCreationScreen extends StatefulWidget {
  @override
  _PostCreationScreenState createState() => _PostCreationScreenState();
}

class _PostCreationScreenState extends State<PostCreationScreen>
    with SingleTickerProviderStateMixin {
  final PostCreationController controller = Get.put(PostCreationController());
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;

  // Focus node for caption field
  final FocusNode _captionFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          _buildSliverAppBar(),

          // Main Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // User Header Card
                _buildUserHeaderCard(),

                // Caption Input Area
                _buildCaptionInput(),

                // AI Caption Button (when media selected)
                _buildAICaptionButton(),

                // Media Preview Area
                _buildMediaPreview(),

                // Bottom Spacing
                SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // Floating Bottom Action Bar
      bottomNavigationBar: _buildFloatingActionBar(),
    );
  }

  // ==================== SLIVER APP BAR ====================
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      floating: true,
      pinned: true,
      elevation: 0,
      actionsPadding: EdgeInsets.only(top: 30),
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 16, bottom: 8),
        title: Text(
          'Create Post',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.purple.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Obx(() => AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.only(right: 8),
          child: MaterialButton(
            onPressed: controller.isUploading.value ? null : _publishPost,
            color: controller.isUploading.value ? Colors.grey : Colors.blue,
            disabledColor: Colors.grey[300],
            elevation: controller.isUploading.value ? 0 : 2,
            highlightElevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: controller.isUploading.value
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.send, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Post',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  // ==================== USER HEADER CARD ====================
  Widget _buildUserHeaderCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated Profile Picture
          Hero(
            tag: 'user_profile',
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),

              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: controller.currentUserProfilePic.value.isNotEmpty
                      ? CachedNetworkImageProvider(controller.currentUserProfilePic.value)
                      : null,
                  child: controller.currentUserProfilePic.value.isEmpty
                      ? Icon(Icons.person, size: 28, color: Colors.grey)
                      : null,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.currentUserName.value.isNotEmpty
                      ? controller.currentUserName.value
                      : 'Loading...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),

                // Privacy Selector
                Obx(() => GestureDetector(
                  onTap: () => _showPrivacyBottomSheet(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPrivacyIcon(controller.selectedPrivacy.value),
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 6),
                        Text(
                          controller.selectedPrivacy.value,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CAPTION INPUT ====================
  Widget _buildCaptionInput() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _captionController,
            focusNode: _captionFocus,
            maxLines: null,
            minLines: 3,
            maxLength: 500,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              border: InputBorder.none,
              counterText: '',
            ),
            onChanged: (text) {
              controller.caption.value = text;
              // Animate character count
              setState(() {});
            },
          ),

          // Character count indicator
          Align(
            alignment: Alignment.bottomRight,
            child: AnimatedBuilder(
              animation: _captionController,
              builder: (context, child) {
                final length = _captionController.text.length;
                return Text(
                  '$length/500',
                  style: TextStyle(
                    color: length > 450
                        ? Colors.orange
                        : length > 480
                        ? Colors.red
                        : Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== AI CAPTION BUTTON ====================
  Widget _buildAICaptionButton() {
    return Obx(() {
      if (controller.selectedMedia.isEmpty) return SizedBox.shrink();

      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: controller.isGeneratingCaption.value
                ? null
                : () => controller.generateAICaption(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.1),
                    Colors.blue.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  controller.isGeneratingCaption.value
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    ),
                  )
                      : Icon(
                    Icons.auto_awesome,
                    color: Colors.purple,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    controller.isGeneratingCaption.value
                        ? 'Generating...'
                        : 'Generate AI Caption',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ==================== MEDIA PREVIEW ====================
  Widget _buildMediaPreview() {
    return Obx(() {
      if (controller.selectedMedia.isEmpty) return SizedBox.shrink();

      final media = controller.selectedMedia.first;

      return Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Media Content
              AspectRatio(
                aspectRatio: 16 / 9,
                child: media.type == 'video'
                    ? _buildVideoPreview(media.path)
                    : Image.file(
                  File(media.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),

              // Gradient Overlay for controls
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Media count badge
                      if (controller.selectedMedia.length > 1)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.collections,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '${controller.selectedMedia.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox.shrink(),

                      // Delete button
                      GestureDetector(
                        onTap: () => _showDeleteConfirmation(),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Media type indicator
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        media.type == 'video'
                            ? Icons.videocam
                            : Icons.photo,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        media.type == 'video' ? 'VIDEO' : 'PHOTO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ==================== VIDEO PREVIEW ====================
  Widget _buildVideoPreview(String path) {
    return _VideoPreviewWidget(path: path);
  }

  // ==================== FLOATING ACTION BAR ====================
  Widget _buildFloatingActionBar() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.photo_library,
                  color: Colors.green,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                _buildActionButton(
                  icon: Icons.camera_alt,
                  color: Colors.blue,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildActionButton(
                  icon: Icons.videocam,
                  color: Colors.red,
                  label: 'Video',
                  onTap: () => _pickVideo(),
                ),
                _buildActionButton(
                  icon: Icons.mic,
                  color: Colors.orange,
                  label: 'Voice',
                  onTap: () => _showVoiceRecorder(),
                ),
                _buildActionButton(
                  icon: Icons.emoji_emotions,
                  color: Colors.amber,
                  label: 'Mood',
                  onTap: () => _showMoodSelector(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== ACTION BUTTON ====================
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== BOTTOM SHEETS ====================
  void _showPrivacyBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Who can see this?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildPrivacyOption('Public', Icons.public, Colors.green,
                'Anyone can see this post'),
            _buildPrivacyOption('Friends', Icons.people, Colors.blue,
                'Only friends can see this'),
            _buildPrivacyOption('Only Me', Icons.lock, Colors.orange,
                'Only you can see this'),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(
      String privacy,
      IconData icon,
      Color color,
      String subtitle,
      ) {
    return Obx(() => ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(privacy),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12),
      ),
      trailing: controller.selectedPrivacy.value == privacy
          ? Icon(Icons.check_circle, color: Colors.blue)
          : null,
      onTap: () {
        controller.selectedPrivacy.value = privacy;
        Get.back();
      },
    ));
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Remove Media?'),
        content: Text('Are you sure you want to remove this media?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.removeMedia(0);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showVoiceRecorder() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            SizedBox(height: 20),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Hold to Record',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 30),
            Obx(() => GestureDetector(
              onLongPressStart: (_) {
                _animationController.forward();
                controller.startRecording();
              },
              onLongPressEnd: (_) {
                _animationController.reverse();
                controller.stopRecording();
                Get.back();
              },
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    width: 100 + (_animationController.value * 20),
                    height: 100 + (_animationController.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: controller.isRecording.value
                            ? [Colors.red, Colors.redAccent]
                            : [Colors.blue, Colors.purple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (controller.isRecording.value
                              ? Colors.red
                              : Colors.blue)
                              .withOpacity(0.3 + (_animationController.value * 0.3)),
                          blurRadius: 20 + (_animationController.value * 20),
                          spreadRadius: 2 + (_animationController.value * 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      controller.isRecording.value
                          ? Icons.mic
                          : Icons.mic_none,
                      color: Colors.white,
                      size: 40,
                    ),
                  );
                },
              ),
            )),
            SizedBox(height: 20),
            Obx(() => Text(
              controller.isRecording.value
                  ? 'Recording...'
                  : 'Tap and hold to record',
              style: TextStyle(
                color: controller.isRecording.value ? Colors.red : Colors.grey,
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showMoodSelector() {
    final moods = [
      {'emoji': '😊', 'label': 'Happy', 'color': Colors.yellow},
      {'emoji': '😢', 'label': 'Sad', 'color': Colors.blue},
      {'emoji': '😡', 'label': 'Angry', 'color': Colors.red},
      {'emoji': '😍', 'label': 'Loved', 'color': Colors.pink},
      {'emoji': '😎', 'label': 'Cool', 'color': Colors.purple},
      {'emoji': '🤔', 'label': 'Thinking', 'color': Colors.orange},
    ];

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'How are you feeling?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: moods.map((mood) => GestureDetector(
                onTap: () {
                  controller.caption.value =
                  '${controller.caption.value} Feeling ${mood['label']} ${mood['emoji']}';
                  _captionController.text = controller.caption.value;
                  Get.back();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: (mood['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (mood['color'] as Color).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${mood['emoji']} ${mood['label']}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPERS ====================
  IconData _getPrivacyIcon(String privacy) {
    switch (privacy) {
      case 'Public':
        return Icons.public;
      case 'Friends':
        return Icons.people;
      case 'Only Me':
        return Icons.lock;
      default:
        return Icons.public;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      controller.addMedia(image.path, 'image');
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      controller.addMedia(video.path, 'video');
    }
  }

  void _publishPost() async {
    if (_captionController.text.isEmpty && controller.selectedMedia.isEmpty) {
      Get.snackbar(
        'Empty Post',
        'Add a caption or media to create a post',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        borderRadius: 12,
        margin: EdgeInsets.all(16),
      );
      return;
    }

    final success = await controller.publishPost();
    if (success) {
      Get.back();
      Get.snackbar(
        'Success! 🎉',
        'Your post has been published',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        borderRadius: 12,
        margin: EdgeInsets.all(16),
        icon: Icon(Icons.check_circle, color: Colors.white),
      );
    } else {
      Get.snackbar(
        'Oops!',
        'Failed to publish post. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 12,
        margin: EdgeInsets.all(16),
      );
    }
  }
}

// ==================== VIDEO PREVIEW WIDGET ====================
class _VideoPreviewWidget extends StatefulWidget {
  final String path;

  const _VideoPreviewWidget({required this.path});

  @override
  _VideoPreviewWidgetState createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<_VideoPreviewWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(_controller),

          // Play/Pause overlay
          GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _controller.value.isPlaying ? 0 : 1,
                  duration: Duration(milliseconds: 200),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Video progress indicator
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Colors.red,
                bufferedColor: Colors.white54,
                backgroundColor: Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}