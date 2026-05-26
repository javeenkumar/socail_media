// post_creation_controller.dart
import 'dart:io';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class MediaItem {
  final String path;
  final String type;

  MediaItem({required this.path, required this.type});
}

class PostCreationController extends GetxController {
  var caption = ''.obs;
  var selectedMedia = <MediaItem>[].obs;
  var selectedPrivacy = 'Public'.obs;
  var isUploading = false.obs;
  var isRecording = false.obs;
  var isGeneratingCaption = false.obs; // ✅ ADDED: For AI caption loading state
  var currentMediaIndex = 0.obs;
  var currentUserName = ''.obs;
  var currentUserProfilePic = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userData = await FirebaseService.getUser(user.uid);
        if (userData != null) {
          currentUserName.value = userData.name;
          currentUserProfilePic.value = userData.profilePic ?? '';
        }
      } catch (e) {
        print('Error loading user: $e');
        currentUserName.value = 'User';
        currentUserProfilePic.value = '';
      }
    }
  }

  void addMedia(String path, String type) {
    selectedMedia.add(MediaItem(path: path, type: type));
  }

  void removeMedia(int index) {
    if (index >= 0 && index < selectedMedia.length) {
      selectedMedia.removeAt(index);
      if (currentMediaIndex.value >= selectedMedia.length && selectedMedia.isNotEmpty) {
        currentMediaIndex.value = selectedMedia.length - 1;
      }
    }
  }

  void startRecording() {
    isRecording.value = true;
    Get.snackbar('Recording', 'Voice recording started (placeholder)');
  }

  void stopRecording() {
    isRecording.value = false;
    Get.snackbar('Recording', 'Voice recording stopped (placeholder)');
  }

  // ✅ UPDATED: Added loading state management
  Future<void> generateAICaption() async {
    if (selectedMedia.isEmpty) {
      Get.snackbar('No Media', 'Please select an image or video first');
      return;
    }

    try {
      isGeneratingCaption.value = true; // Show loading
      Get.snackbar('AI', 'Generating AI caption...');

      await Future.delayed(Duration(seconds: 2)); // Simulate API call

      // TODO: Replace with actual AI API integration
      caption.value = "AI-generated caption for this amazing post! ✨";

    } catch (e) {
      print('🔴 AI Caption error: $e');
      Get.snackbar('Error', 'Failed to generate caption');
    } finally {
      isGeneratingCaption.value = false; // Hide loading
    }
  }

  Future<bool> publishPost() async {
    if (caption.value.isEmpty && selectedMedia.isEmpty) {
      Get.snackbar('Error', 'Please add caption or media');
      return false;
    }

    isUploading.value = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'Please login first');
        return false;
      }

      String? mediaUrl;
      String mediaType = 'none';

      if (selectedMedia.isNotEmpty) {
        final media = selectedMedia.first;
        final folder = media.type == 'image' ? 'post_images'
            : media.type == 'video' ? 'post_videos'
            : 'post_audio';

        mediaUrl = await FirebaseService.uploadFile(media.path, folder);
        mediaType = media.type;
      }

      final userData = await FirebaseService.getUser(user.uid);

      final post = Post(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        userName: userData?.name ?? 'Unknown',
        userProfilePic: userData?.profilePic,
        content: caption.value,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        platform: 'app',
        likes: [],
        commentsCount: 0,
        timestamp: DateTime.now(),
        privacy: selectedPrivacy.value.toLowerCase(),
        tags: _extractTags(caption.value),
        location: null,
        isLiked: false,
      );

      await FirebaseService.createPost(post);

      caption.value = '';
      selectedMedia.clear();

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to publish: $e');
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  List<String> _extractTags(String text) {
    final regex = RegExp(r'#(\w+)');
    return regex.allMatches(text).map((m) => m.group(1)!).toList();
  }
}