import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../services/firebase_service.dart';
import '../models/reel_model.dart';
import 'reels_controller.dart';

class CreateReelController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  Rx<File?> selectedVideo = Rx<File?>(null);
  RxString thumbnailPath = ''.obs;
  RxBool isUploading = false.obs;
  RxDouble uploadProgress = 0.0.obs;
  RxBool isProcessing = false.obs;

  RxString caption = ''.obs;
  RxString audioTitle = 'Original Audio'.obs;
  RxBool allowComments = true.obs;
  RxBool allowDuet = true.obs;
  RxList<String> hashtags = <String>[].obs;

  RxInt videoDuration = 0.obs;
  RxInt videoWidth = 0.obs;
  RxInt videoHeight = 0.obs;

  static const int maxVideoDuration = 60;
  static const int maxCaptionLength = 2200;

  Future<void> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: maxVideoDuration),
      );
      if (video != null) {
        await _processSelectedVideo(File(video.path));
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick video: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: maxVideoDuration),
        preferredCameraDevice: CameraDevice.rear,
      );
      if (video != null) {
        await _processSelectedVideo(File(video.path));
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to record video: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _processSelectedVideo(File videoFile) async {
    isProcessing.value = true;
    try {
      selectedVideo.value = videoFile;

      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        quality: 75,
      );
      thumbnailPath.value = thumbnail ?? '';

      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      videoDuration.value = controller.value.duration.inSeconds;
      videoWidth.value = controller.value.size.width.toInt();
      videoHeight.value = controller.value.size.height.toInt();
      await controller.dispose();

      // ✅ FIX: Navigate to the PREVIEW/EDIT screen, not the ReelsScreen viewer.
      // The preview screen (CreateReelPreviewScreen) lives at '/create-reel-preview'.
      // It shows the video, caption input, hashtags, and the "Share" button.
      Get.toNamed('/create-reel-preview');
    } catch (e) {
      Get.snackbar('Error', 'Failed to process video: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isProcessing.value = false;
    }
  }

  void addHashtag(String tag) {
    final cleanTag = tag.replaceAll('#', '').trim();
    if (cleanTag.isNotEmpty && !hashtags.contains(cleanTag)) {
      hashtags.add(cleanTag);
    }
  }

  void removeHashtag(String tag) => hashtags.remove(tag);

  void updateCaption(String value) {
    if (value.length <= maxCaptionLength) caption.value = value;
  }

  Future<void> uploadReel() async {
    print('🚀 === STARTING REEL UPLOAD ===');

    if (selectedVideo.value == null) {
      Get.snackbar('Error', 'No video selected',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final videoFile = selectedVideo.value!;
    if (!await videoFile.exists()) {
      Get.snackbar('Error', 'Video file not found',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    isUploading.value = true;
    uploadProgress.value = 0.0;

    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null || userId.isEmpty) throw Exception('User not authenticated');

      final userData = await FirebaseService.getUser(userId);
      if (userData == null) throw Exception('User data not found');

      // Upload video
      print('☁️ Uploading video...');
      final videoUrl = await FirebaseService.uploadFile(
        videoFile,
        'reels/$userId',
        onProgress: (progress) {
          uploadProgress.value = progress;
          print('📤 Progress: ${(progress * 100).toInt()}%');
        },
      );

      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception('Video upload failed - no URL returned');
      }
      print('✅ Video URL: $videoUrl');

      // Upload thumbnail
      String? thumbnailUrl;
      if (thumbnailPath.value.isNotEmpty) {
        final thumbFile = File(thumbnailPath.value);
        if (await thumbFile.exists()) {
          thumbnailUrl = await FirebaseService.uploadFile(
            thumbFile,
            'reels/thumbnails/$userId',
          );
        }
      }

      // ✅ FIX: Use a server-generated ID so Firestore acknowledges it immediately.
      final docRef = FirebaseService.reels.doc();
      final reelId = docRef.id;

      final reel = Reel(
        id: reelId,
        userId: userId,
        userName: userData.name,
        userProfilePic: userData.profilePic ?? '',
        videoUrl: videoUrl,
        caption: caption.value.trim().isEmpty ? 'No caption' : caption.value.trim(),
        audioTitle: audioTitle.value,
        thumbnailUrl: thumbnailUrl,
        likes: [],
        commentsCount: 0,
        comments: [],
        views: [],
        timestamp: DateTime.now(),
        hashtags: hashtags.toList(),
        allowComments: allowComments.value,
        allowDuet: allowDuet.value,
      );

      // Write directly to the pre-generated doc ref
      await docRef.set(reel.toMap());
      print('✅ Reel saved to Firestore: $reelId');

      // ✅ FIX: The realtime stream in ReelsController will automatically pick up
      // the new document. We only call refreshReels() as a safety net after a
      // short delay to let Firestore propagate the write.
      clear();

      Get.snackbar('Success', 'Reel uploaded!',
          backgroundColor: Colors.green, colorText: Colors.white);

      // ✅ FIX: Navigate back to /home (which shows ReelsScreen via the tab bar).
      // Use Get.offAllNamed so the back-stack is clean.
      Get.offAllNamed('/home');

      // Safety-net refresh after navigation settles
      await Future.delayed(const Duration(milliseconds: 800));
      try {
        final reelsController = Get.find<ReelsController>();
        await reelsController.refreshReels();
        print('✅ Post-navigation refresh complete');
      } catch (e) {
        print('⚠️ Post-navigation refresh skipped: $e');
      }
    } catch (e, stackTrace) {
      print('❌ UPLOAD FAILED: $e');
      print('❌ Stack: $stackTrace');
      Get.snackbar(
        'Upload Failed',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 10),
      );
    } finally {
      isUploading.value = false;
    }
  }

  void clear() {
    selectedVideo.value = null;
    thumbnailPath.value = '';
    caption.value = '';
    audioTitle.value = 'Original Audio';
    allowComments.value = true;
    allowDuet.value = true;
    hashtags.clear();
    uploadProgress.value = 0.0;
  }

  @override
  void onClose() {
    clear();
    super.onClose();
  }
}