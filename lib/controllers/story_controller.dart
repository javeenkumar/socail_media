// story_controller.dart - Fixed with all missing properties and methods
import 'dart:io';

import 'package:get/get.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/story_model.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Filter model for UI
class StoryFilter {
  final String name;
  final String preview;

  StoryFilter({required this.name, required this.preview});
}

// Selected media model
class SelectedMedia {
  final String path;
  final String type; // 'image' or 'video'

  SelectedMedia({required this.path, required this.type});
}

class StoryController extends GetxController {
  var stories = <Story>[].obs;
  var currentStoryIndex = 0.obs;
  var currentItemIndex = 0.obs;

  // ADDED: Selected media for creation
  var selectedMedia = <SelectedMedia>[].obs;

  // ADDED: Filters for UI
  var filters = <StoryFilter>[
    StoryFilter(name: 'Normal', preview: 'assets/filters/normal.png'),
    StoryFilter(name: 'Paris', preview: 'assets/filters/paris.png'),
    StoryFilter(name: 'Tokyo', preview: 'assets/filters/tokyo.png'),
    StoryFilter(name: 'Lagos', preview: 'assets/filters/lagos.png'),
    StoryFilter(name: 'Retro', preview: 'assets/filters/retro.png'),
  ].obs;

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchStories();
  }

  void fetchStories() {
    FirebaseService.getActiveStories().listen((data) {
      stories.value = data;
    }, onError: (e) {
      print('Error fetching stories: $e');
    });
  }

  // ADDED: Add media to story creation
  void addStoryMedia(String path, String type) {
    selectedMedia.add(SelectedMedia(path: path, type: type));
  }

  // ADDED: Publish story
  Future<void> publishStory() async {
    try {
      if (selectedMedia.isEmpty) {
        Get.snackbar('Error', 'No media selected');
        return;
      }

      // Upload media to Firebase Storage first
      final media = selectedMedia.first; // For single story, take first
      final downloadUrl = await FirebaseService.uploadFile(
        media.path as String,
        'stories',
      );

      // Create story items
      final storyItem = StoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mediaUrl: downloadUrl!,
        thumbnailUrl: media.type == 'video' ? downloadUrl : null,
        mediaType: media.type,
        timestamp: DateTime.now(),
      );

      // Create story
      final story = Story(
        id: '',
        userId: currentUserId,
        userName: 'Current User', // Get from user profile
        userProfilePic: null, // Get from user profile
        mediaUrl: downloadUrl,
        thumbnailUrl: media.type == 'video' ? downloadUrl : null,
        mediaType: media.type,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 24)),
        items: [storyItem],
      );

      await FirebaseService.createStory(story);
      selectedMedia.clear();
      Get.back();
      Get.snackbar('Success', 'Story published!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to publish story: $e');
    }
  }

  Future<void> uploadStory(Story story) async {
    await FirebaseService.createStory(story);
  }

  Future<String?> _generateVideoThumbnail(String videoPath) async {
    // Optional: Use video_thumbnail package
    final thumbnail = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 300,
      quality: 75,
    );
    return await FirebaseService.uploadFile(thumbnail, 'story_thumbnails');
  }

  // void viewStory(Story story, String userId) async {
  //   if (story.items.isNotEmpty && currentItemIndex.value < story.items.length) {
  //     await FirebaseService.markStoryViewed(
  //         story.id,
  //         story.items[currentItemIndex.value].id,
  //         userId
  //     );
  //   } else if (story.items.isEmpty && story.mediaUrl.isNotEmpty) {
  //     // Fallback for legacy stories without items
  //     await FirebaseService.markStoryViewed(
  //         story.id,
  //         'default',
  //         userId
  //     );
  //   }
  // }


  // Change the signature so the screen passes its own index
  void viewStory(Story story, String userId, {int itemIndex = 0}) async {
    if (story.items.isNotEmpty && itemIndex < story.items.length) {
      await FirebaseService.markStoryViewed(
        story.id,
        story.items[itemIndex].id,
        userId,
      );
    } else if (story.items.isEmpty && story.mediaUrl.isNotEmpty) {
      await FirebaseService.markStoryViewed(story.id, 'default', userId);
    }
  }

  void nextItem() {
    if (currentStoryIndex.value >= stories.length) return;

    if (currentItemIndex.value < stories[currentStoryIndex.value].items.length - 1) {
      currentItemIndex.value++;
    } else {
      nextStory();
    }
  }

  void previousItem() {
    if (currentItemIndex.value > 0) {
      currentItemIndex.value--;
    } else {
      previousStory();
    }
  }

  void nextStory() {
    if (currentStoryIndex.value < stories.length - 1) {
      currentStoryIndex.value++;
      currentItemIndex.value = 0;
    } else {
      // Close story viewer when reaching end
      Get.back();
    }
  }

  void previousStory() {
    if (currentStoryIndex.value > 0) {
      currentStoryIndex.value--;
      currentItemIndex.value = 0;
    }
  }
}