import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_reel_controller.dart';

class CreateReelScreen extends StatelessWidget {
  // Use Get.find() instead of Get.put() - controller should be initialized elsewhere
  final CreateReelController controller = Get.find<CreateReelController>();

  CreateReelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Create Reel',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isProcessing.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Processing video...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }

        return _buildSelectionUI();
      }),
    );
  }

  Widget _buildSelectionUI() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          child: const Text(
            'Select or record a video up to 60 seconds',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const Spacer(),

        // Main Options
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Gallery Option
            _buildOptionCard(
              icon: Icons.photo_library,
              label: 'Gallery',
              color: Colors.purple,
              onTap: () => controller.pickVideoFromGallery(),
            ),

            // Camera Option
            _buildOptionCard(
              icon: Icons.videocam,
              label: 'Camera',
              color: Colors.red,
              onTap: () => controller.recordVideo(),
            ),
          ],
        ),

        const Spacer(),

        // Tips
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildTip(Icons.timer, 'Max duration: 60 seconds'),
              const SizedBox(height: 8),
              _buildTip(Icons.aspect_ratio, 'Aspect ratio: 9:16 recommended'),
              const SizedBox(height: 8),
              _buildTip(Icons.high_quality, 'Min resolution: 720p'),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ],
    );
  }
}