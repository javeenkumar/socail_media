// timeline_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/post_model.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TimelineController extends GetxController {
  var posts = <Post>[].obs;
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMorePosts = true.obs;

  final int postsPerPage = 10;

  StreamSubscription<List<Post>>? _streamSubscription;

  // ✅ FIX: Track in-flight like operations to prevent double-fire
  final Set<String> _pendingLikes = {};

  String get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    loadPosts();
  }

  @override
  void onClose() {
    _streamSubscription?.cancel();
    super.onClose();
  }

  void loadPosts() {
    isLoading.value = true;

    // ✅ FIX: Cancel previous subscription before creating a new one
    _streamSubscription?.cancel();

    _streamSubscription =
        FirebaseService.getTimelinePostsStream().listen(
              (newPosts) {
            final userId = currentUserId;

            // ✅ FIX: Rebuild posts with correct isLiked state.
            // Preserve optimistic like state for posts that have a pending operation.
            final updatedPosts = newPosts.map((post) {
              final isLiked = post.likes.contains(userId);

              // If there's a pending like operation for this post, keep the
              // optimistic state instead of overwriting with server data.
              if (_pendingLikes.contains(post.id)) {
                final currentPost =
                posts.firstWhereOrNull((p) => p.id == post.id);
                if (currentPost != null) {
                  return post.copyWith(isLiked: currentPost.isLiked);
                }
              }

              return post.copyWith(isLiked: isLiked);
            }).toList();

            posts.assignAll(updatedPosts);
            isLoading.value = false;
            hasMorePosts.value = newPosts.length >= postsPerPage;
          },
          onError: (e) {
            print('🔴 Error loading posts: $e');
            isLoading.value = false;
            Get.snackbar(
              'Error',
              'Failed to load posts',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          },
        );
  }

  Future<void> refreshPosts() async {
    _streamSubscription?.cancel();
    hasMorePosts.value = true;
    loadPosts();
  }

  void loadMorePosts() {
    if (isLoadingMore.value || !hasMorePosts.value) return;
    isLoadingMore.value = true;
    Future.delayed(const Duration(seconds: 1), () {
      isLoadingMore.value = false;
      hasMorePosts.value = false;
    });
  }

  Future<void> likePost(Post post) async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      Get.snackbar('Error', 'Please login to like posts',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // ✅ FIX: Guard against double-taps while request is in-flight
    if (_pendingLikes.contains(post.id)) return;

    final index = posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final currentPost = posts[index];
    final wasLiked = currentPost.isLiked;

    // ✅ FIX: Build new likes list without mutating the original (which is
    // a const/final list on the model). Use copyWith with a fresh list.
    final newLikes = List<String>.from(currentPost.likes);
    if (wasLiked) {
      newLikes.remove(userId);
    } else {
      if (!newLikes.contains(userId)) newLikes.add(userId);
    }

    // Mark as pending BEFORE updating UI
    _pendingLikes.add(post.id);

    // Optimistic UI update
    posts[index] = currentPost.copyWith(
      likes: newLikes,
      isLiked: !wasLiked,
    );
    posts.refresh();

    try {
      if (wasLiked) {
        await FirebaseService.unlikePost(post.id, userId);
      } else {
        await FirebaseService.likePost(post.id, userId);
      }
    } catch (e) {
      print('🔴 Like error: $e');

      // ✅ Revert optimistic update on failure
      if (index < posts.length) {
        posts[index] = currentPost; // restore original
        posts.refresh();
      }

      Get.snackbar('Error', 'Failed to update like',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      // Remove pending flag — stream will now reconcile correctly
      _pendingLikes.remove(post.id);
    }
  }

  void sharePost(Post post) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share to...'),
                onTap: () => Get.back(),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy link'),
                onTap: () {
                  Get.back();
                  Get.snackbar('Copied', 'Post link copied to clipboard');
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancel'),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> deletePost(String postId) async {
    try {
      await FirebaseService.deletePost(postId);
      Get.snackbar('Success', 'Post deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete post: $e');
    }
  }
}