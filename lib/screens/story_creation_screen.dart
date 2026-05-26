import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../controllers/story_controller.dart';

class StoryCreationScreen extends StatefulWidget {
  @override
  _StoryCreationScreenState createState() => _StoryCreationScreenState();
}

class _StoryCreationScreenState extends State<StoryCreationScreen> {
  final StoryController controller = Get.put(StoryController());
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _cameraController!.initialize();
    if (mounted) {
      setState(() => _isCameraInitialized = true);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized)
            CameraPreview(_cameraController!)
          else
            Center(child: CircularProgressIndicator()),

          // Close Button
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  IconButton(
                    icon: Icon(Icons.flash_off, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
              children: [
                Container(
                  height: 85, // Increased from 80 to 85
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.filters.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox( // Wrap in SizedBox with fixed height
                          height: 80,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56, // Reduced from 60
                                height: 56, // Reduced from 60
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white),
                                  image: controller.filters[index].preview != null
                                      ? DecorationImage(
                                    image: AssetImage(controller.filters[index].preview!),
                                    fit: BoxFit.cover,
                                    onError: (_, __) {}, // Silently handle missing assets
                                  )
                                      : null,
                                  color: Colors.grey[800],
                                ),
                                child: controller.filters[index].preview == null
                                    ? Icon(Icons.filter_b_and_w, color: Colors.white, size: 28)
                                    : null,
                              ),
                              SizedBox(height: 2), // Reduced from 4
                              Text(
                                controller.filters[index].name,
                                style: TextStyle(color: Colors.white, fontSize: 10), // Reduced from 12
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery Button
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white),
                        ),
                        child: Icon(Icons.photo_library, color: Colors.white),
                      ),
                    ),

                    // Capture Button
                    GestureDetector(
                      onTap: _takePhoto,
                      onLongPressStart: (_) => _startRecording(),
                      onLongPressEnd: (_) => _stopRecording(),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecording ? Colors.red : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Switch Camera
                    GestureDetector(
                      onTap: _switchCamera,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white),
                        ),
                        child: Icon(Icons.flip_camera_ios, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Tap for photo, hold for video',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          // Text Overlay Input
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 20,
            right: 20,
            child: TextField(
              style: TextStyle(color: Colors.white, fontSize: 24),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Add text...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _takePhoto() async {
    try {
      final XFile photo = await _cameraController!.takePicture();
      controller.addStoryMedia(photo.path, 'image');
      _previewStory();
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  void _startRecording() async {
    try {
      await _cameraController!.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  void _stopRecording() async {
    try {
      final XFile video = await _cameraController!.stopVideoRecording();
      setState(() => _isRecording = false);
      controller.addStoryMedia(video.path, 'video');
      _previewStory();
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  void _switchCamera() async {
    final cameras = await availableCameras();
    final lensDirection = _cameraController!.description.lensDirection;
    CameraDescription newCamera;

    if (lensDirection == CameraLensDirection.back) {
      newCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
      );
    } else {
      newCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
      );
    }

    await _cameraController!.setDescription(newCamera);
  }

  void _pickFromGallery() async {
    final XFile? media = await _picker.pickImage(source: ImageSource.gallery);
    if (media != null) {
      controller.addStoryMedia(media.path, 'image');
      _previewStory();
    }
  }

  void _previewStory() {
    Get.to(() => StoryPreviewScreen());
  }
}

// Story Preview Screen
class StoryPreviewScreen extends StatelessWidget {
  final StoryController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Preview Content - FIXED: Use FileImage and FileVideo
          Center(
            child: Obx(() {
              final media = controller.selectedMedia.last;
              if (media.type == 'video') {
                return VideoPlayerWidget(path: media.path); // Changed from url to path
              }
              // FIX: Use Image.file for local file paths instead of Image.network
              return Image.file(
                File(media.path),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error, color: Colors.red, size: 50);
                },
              );
            }),
          ),

          // Top Actions
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.text_fields, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.emoji_emotions, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.draw, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Actions
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_emotions, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Send message...',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: () => controller.publishStory(),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.pink],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String path; // Changed from url to path
  VideoPlayerWidget({required this.path});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // FIX: Use file() constructor for local file paths
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
          _controller.setLooping(true);
        }
      }).catchError((error) {
        print('Error initializing video player: $error');
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    )
        : CircularProgressIndicator();
  }
}