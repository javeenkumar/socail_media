import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/reel_model.dart';
import '../models/story_model.dart';
import '../services/firebase_service.dart';

class ProfileController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Observables
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxList<Post> userPosts = <Post>[].obs;
  final RxList<Reel> userReels = <Reel>[].obs;
  final RxList<Story> userStories = <Story>[].obs;
  final RxList<Post> livedReplayPosts = <Post>[].obs; // live replays stored as posts

  final RxBool isLoading = false.obs;
  final RxString selectedTab = 'posts'.obs; // 'posts', 'reels', 'stories', 'live'

  String? get userId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadAllUserData();
  }

  /// Load everything at once
  Future<void> loadAllUserData() async {
    if (userId == null) return;
    isLoading.value = true;
    try {
      await Future.wait([
        fetchUserProfile(),
        fetchUserPosts(),
        fetchUserReels(),
        fetchUserStories(),
        fetchLiveReplays(),
      ]);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch logged-in user profile
  Future<void> fetchUserProfile() async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        currentUser.value = UserModel.fromFirestore(doc);
      }
    } catch (e) {
      print('❌ Error fetching profile: $e');
    }
  }

  /// Fetch only this user's posts
  Future<void> fetchUserPosts() async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .where('isLiveReplay', isEqualTo: false) // exclude live replays
          .orderBy('timestamp', descending: true)
          .get();

      userPosts.value = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error fetching posts: $e');
    }
  }

  /// Real-time stream for user posts
  Stream<List<Post>> get userPostsStream => _firestore
      .collection('posts')
      .where('userId', isEqualTo: userId)
      .where('isLiveReplay', isEqualTo: false)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((s) => s.docs.map((doc) => Post.fromFirestore(doc)).toList());

  /// Fetch only this user's reels
  Future<void> fetchUserReels() async {
    try {
      final snapshot = await _firestore
          .collection('reels')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      userReels.value = snapshot.docs.map((doc) => Reel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error fetching reels: $e');
    }
  }

  /// Fetch only this user's active stories
  Future<void> fetchUserStories() async {
    try {
      final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));
      final snapshot = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo))
          .orderBy('timestamp', descending: true)
          .get();

      userStories.value = snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error fetching stories: $e');
    }
  }

  /// Fetch live replay posts
  Future<void> fetchLiveReplays() async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .where('isLiveReplay', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      livedReplayPosts.value = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error fetching live replays: $e');
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      userPosts.removeWhere((p) => p.id == postId);
      Get.snackbar('Done', 'Post deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete post');
    }
  }

  /// Delete a reel
  Future<void> deleteReel(String reelId) async {
    try {
      await _firestore.collection('reels').doc(reelId).delete();
      userReels.removeWhere((r) => r.id == reelId);
      Get.snackbar('Done', 'Reel deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete reel');
    }
  }

  // Computed stats
  int get totalLikes =>
      userPosts.fold(0, (sum, p) => sum + (p.likes?.length ?? 0)) +
          userReels.fold(0, (sum, r) => sum + (r.likes?.length ?? 0));

  int get totalViews =>
      userReels.fold(0, (sum, r) => sum + (r.views?.length ?? 0)) +
          livedReplayPosts.fold(0, (sum, p) => sum + (p.viewCount ?? 0));
}