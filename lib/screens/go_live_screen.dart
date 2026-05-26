// views/go_live_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../controllers/live_controller.dart';

class GoLiveScreen extends StatefulWidget {
  @override
  _GoLiveScreenState createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  final LiveController controller = Get.find();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String _selectedCategory = 'Talk Show';
  bool _allowComments = true;
  bool _isPrivate = false;

  @override
  void initState() {
    super.initState();
    // ✅ Initialize camera after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeCamera();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope( // ✅ ADD THIS
        onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: Obx(() {
          // ✅ Show loading while camera initializes
          if (!controller.isCameraInitialized.value) {
            return Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Initializing camera...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }
      
          return Stack(
            fit: StackFit.expand,
            children: [
              // ✅ Camera Preview with null check
              Positioned.fill(
                child: controller.cameraController != null &&
                    controller.cameraController!.value.isInitialized
                    ? CameraPreview(controller.cameraController!)
                    : Container(color: Colors.black),
              ),
      
              // Top Bar
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIconButton(
                        Icons.close,
                        onTap: () => Get.back(),
                      ),
                      if (controller.isStreaming.value)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 12),
                              SizedBox(width: 8),
                              Obx(() => Text(
                                'LIVE • ${controller.elapsedTime.value}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                            ],
                          ),
                        ),
                      // ✅ Disable switch while switching
                      Obx(() => _buildIconButton(
                        Icons.cameraswitch,
                        onTap: controller.isSwitchingCamera.value
                            ? null
                            : controller.switchCamera,
                      )),
                    ],
                  ),
                ),
              ),
      
              // Bottom Panel
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    Spacer(),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.9),
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(20, 40, 20, 20),
                      child: controller.isStreaming.value
                          ? _buildStreamingControls()
                          : _buildPreStreamForm(),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey : Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildPreStreamForm() {
    return SingleChildScrollView( // ✅ Make scrollable
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            style: TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Stream Title',
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.title, color: Colors.white54),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          SizedBox(height: 12),

          TextField(
            controller: _descController,
            style: TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Description (optional)',
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.description, color: Colors.white54),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          SizedBox(height: 16),

          Text(
            'Category',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                'Gaming', 'Music', 'Talk Show', 'Sports',
                'Education', 'Fashion', 'Travel'
              ].map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: Colors.red,
                    backgroundColor: Colors.white10,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black ,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 16),

          Row(
            children: [
              _buildOption(
                icon: Icons.chat_bubble,
                label: 'Comments',
                value: _allowComments,
                onChanged: (v) => setState(() => _allowComments = v),
              ),
              SizedBox(width: 20),
              _buildOption(
                icon: Icons.lock,
                label: 'Private',
                value: _isPrivate,
                onChanged: (v) => setState(() => _isPrivate = v),
              ),
            ],
          ),
          SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: controller.isLoading.value ? null : _startStreaming,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 8,
                shadowColor: Colors.red.withOpacity(0.5),
              ),
              child: controller.isLoading.value
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                'GO LIVE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? icon : Icons.block,
            color: value ? Colors.green : Colors.grey,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: value ? Colors.black : Colors.grey,
            ),
          ),
          SizedBox(width: 4),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.red,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStat(
              Icons.visibility,
              '${controller.viewerCount.value}',
              'Viewers',
            ),
            _buildStat(
              Icons.chat,
              '${controller.liveComments.length}',
              'Comments',
            ),
            _buildStat(
              Icons.favorite,
              '0',
              'Likes',
            ),
          ],
        ),
        SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              controller.isMuted.value ? Icons.mic_off : Icons.mic,
              controller.isMuted.value ? Colors.red : Colors.white,
              controller.toggleMute,
            ),
            _buildControlButton(
              controller.isFlashOn.value ? Icons.flash_on : Icons.flash_off,
              controller.isFlashOn.value ? Colors.yellow : Colors.white,
              controller.toggleFlash,
            ),
            _buildControlButton(
              Icons.chat_bubble,
              controller.showComments.value ? Colors.white : Colors.grey,
                  () => controller.showComments.toggle(),
            ),
            _buildControlButton(
              Icons.share,
              Colors.white,
              controller.shareStream,
            ),
            _buildControlButton(
              Icons.call_end,
              Colors.red,
              _showEndStreamDialog,
              size: 70,
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildControlButton(
      IconData icon,
      Color color,
      VoidCallback onTap, {
        double size = 60,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color == Colors.red ? Colors.red : Colors.white10,
          shape: BoxShape.circle,
          border: color != Colors.red
              ? Border.all(color: color.withOpacity(0.5))
              : null,
        ),
        child: Icon(
          icon,
          color: color == Colors.red ? Colors.white : color,
          size: size == 70 ? 32 : 24,
        ),
      ),
    );
  }

  void _startStreaming() {
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please add a stream title');
      return;
    }

    controller.startLiveStream(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      allowComments: _allowComments,
      isPrivate: _isPrivate,
    );
  }

  void _showEndStreamDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('End Stream?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to end your live stream?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Close dialog first

              // ✅ Show loading
              Get.dialog(
                Center(child: CircularProgressIndicator(color: Colors.white)),
                barrierDismissible: false,
              );

              // ✅ End stream
              await controller.endLiveStream();

              // ✅ Close loading
              if (Get.isDialogOpen ?? false) {
                Get.back();
              }

              // ✅ CRITICAL: Actually close the screen
              if (Get.currentRoute == '/go-live' ||
                  Get.currentRoute.contains('GoLive')) {
                Get.back(); // Close GoLiveScreen
              }

              Get.snackbar('Success', 'Live stream ended');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('End Stream'),
          ),
        ],
      ),
    );
  }

// ✅ ADDED: Handle back button press
  Future<bool> _onWillPop() async {
    if (controller.isStreaming.value) {
      // Show confirmation if streaming
      final shouldEnd = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('End Stream?', style: TextStyle(color: Colors.white)),
          content: Text(
            'You are currently streaming. End stream and exit?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Keep Streaming'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('End & Exit'),
            ),
          ],
        ),
      );

      if (shouldEnd == true) {
        await controller.endLiveStream();
        return true; // Allow pop
      }
      return false; // Don't pop
    }
    return true; // Allow pop if not streaming
  }
}