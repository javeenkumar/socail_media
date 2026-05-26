import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reel_model.dart';
import '../services/firebase_service.dart';

class ReelsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxList<Reel> reels = <Reel>[].obs;
  RxBool isLoading = true.obs;
  RxInt currentIndex = 0.obs;
  RxString errorMessage = ''.obs;

  String get currentUserId => FirebaseService.currentUserId ?? '';

  @override
  void onInit() {
    super.onInit();
    print('🎬 ReelsController initialized');
    fetchReels();
  }

  void fetchReels() {
    print('📡 Fetching reels...');
    isLoading.value = true;
    errorMessage.value = '';

    try {
      FirebaseService.getReels().listen(
            (reelsList) {
          print('✅ Received ${reelsList.length} reels');

          // Check likes for current user
          final userId = currentUserId;
          final updatedReels = reelsList.map((reel) {
            final isLiked = reel.likes.contains(userId);
            return reel.copyWith(isLiked: isLiked);
          }).toList();

          reels.value = updatedReels;
          isLoading.value = false;
        },
        onError: (error) {
          print('❌ Stream error: $error');
          errorMessage.value = error.toString();
          isLoading.value = false;

          // Show error to user
          Get.snackbar(
            'Error Loading Reels',
            'Please check your internet connection and try again.\n\n$error',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        },
      );
    } catch (e) {
      print('❌ Error setting up stream: $e');
      errorMessage.value = e.toString();
      isLoading.value = false;
    }
  }

  /// Force refresh - call this after creating new reel
  Future<void> refreshReels() async {
    print('🔄 Refreshing reels...');
    isLoading.value = true;

    try {
      // Direct fetch instead of stream
      final snapshot = await _firestore
          .collection('reels')
          .orderBy('timestamp', descending: true)
          .get();

      print('📥 Fetched ${snapshot.docs.length} reels directly');

      final reelsList = snapshot.docs.map((doc) {
        try {
          return Reel.fromFirestore(doc);
        } catch (e) {
          print('❌ Error parsing reel ${doc.id}: $e');
          return null;
        }
      }).where((reel) => reel != null).cast<Reel>().toList();

      // Update likes
      final userId = currentUserId;
      final updatedReels = reelsList.map((reel) {
        final isLiked = reel.likes.contains(userId);
        return reel.copyWith(isLiked: isLiked);
      }).toList();

      reels.value = updatedReels;
      reels.refresh(); // Force UI update

      print('✅ Refreshed ${reels.length} reels');

    } catch (e) {
      print('❌ Error refreshing: $e');
      Get.snackbar('Error', 'Failed to refresh: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
  }

  Future<void> likeReel(Reel reel) async {
    try {
      final userId = currentUserId;
      if (userId.isEmpty) {
        Get.snackbar('Error', 'Please login first',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final isLiked = reel.likes.contains(userId);

      if (isLiked) {
        await FirebaseService.reels.doc(reel.id).update({
          'likes': FieldValue.arrayRemove([userId]),
        });
      } else {
        await FirebaseService.reels.doc(reel.id).update({
          'likes': FieldValue.arrayUnion([userId]),
        });
      }

      // Optimistic update
      final index = reels.indexWhere((r) => r.id == reel.id);
      if (index != -1) {
        final updatedLikes = List<String>.from(reel.likes);
        if (isLiked) {
          updatedLikes.remove(userId);
        } else {
          updatedLikes.add(userId);
        }
        reels[index] = reel.copyWith(
          likes: updatedLikes,
          isLiked: !isLiked,
        );
        reels.refresh();
      }
    } catch (e) {
      print('❌ Error liking reel: $e');
      Get.snackbar('Error', 'Failed to like reel',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> addComment(
      Reel reel,
      String text,
      String userId,
      String userName,
      String userPic,
      ) async {
    try {
      final comment = ReelComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        userName: userName,
        userPic: userPic,
        text: text,
        timestamp: DateTime.now(),
      );

      await FirebaseService.reels.doc(reel.id).update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
        'commentsCount': FieldValue.increment(1),
      });

      // Optimistic update
      final index = reels.indexWhere((r) => r.id == reel.id);
      if (index != -1) {
        final updatedComments = List<ReelComment>.from(reel.comments)..add(comment);
        reels[index] = reel.copyWith(
          comments: updatedComments,
          commentsCount: reel.commentsCount + 1,
        );
        reels.refresh();
      }
    } catch (e) {
      print('❌ Error adding comment: $e');
      Get.snackbar('Error', 'Failed to add comment',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void shareReel(Reel reel) {
    print('Sharing reel: ${reel.id}');
    // Implement share functionality
  }
}