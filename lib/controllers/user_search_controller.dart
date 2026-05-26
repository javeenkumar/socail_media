import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class UserSearchController extends GetxController {
  var allUsers = <UserModel>[].obs;
  var filteredUsers = <UserModel>[].obs;
  var pendingRequests = <UserModel>[].obs;

  var friendIds = <String>[].obs;
  var receivedRequestIds = <String>[].obs;
  var sentRequestIds = <String>[].obs;

  var isLoadingUsers = true.obs;
  var isLoadingRequests = true.obs;
  var searchQuery = ''.obs;
  var selectedTab = 0.obs;
  var errorMessage = ''.obs;

  StreamSubscription? _currentUserSub;
  Timer? _debounce;

  String get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _listenToCurrentUser();
    loadAllUsers();
  }

  @override
  void onClose() {
    _currentUserSub?.cancel();
    _debounce?.cancel();
    super.onClose();
  }

  // ── Listen to current user doc live ────────────────────────────────────────
  void _listenToCurrentUser() {
    if (currentUserId.isEmpty) {
      print('❌ _listenToCurrentUser: no logged-in user');
      isLoadingRequests.value = false;
      return;
    }

    print('👂 Listening to user doc: $currentUserId');

    _currentUserSub = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .listen(
          (doc) async {
        if (!doc.exists) {
          print('❌ User doc does not exist: $currentUserId');
          isLoadingRequests.value = false;
          return;
        }

        final data = doc.data() as Map<String, dynamic>;

        final newFriends =
        List<String>.from(data['friends'] ?? []);
        final newReceived =
        List<String>.from(data['friendRequestsReceived'] ?? []);
        final newSent =
        List<String>.from(data['friendRequestsSent'] ?? []);

        print('👥 friends: $newFriends');
        print('📩 receivedRequests: $newReceived');
        print('📤 sentRequests: $newSent');

        friendIds.value = newFriends;
        receivedRequestIds.value = newReceived;
        sentRequestIds.value = newSent;

        // Load user objects for the received requests
        await _loadPendingRequests(newReceived);

        isLoadingRequests.value = false;

        // Refresh filter so action buttons update live
        _applyFilter(searchQuery.value);
      },
      onError: (e) {
        print('❌ _listenToCurrentUser error: $e');
        isLoadingRequests.value = false;
      },
    );
  }

  // ── Load UserModel objects for each pending request ─────────────────────────
  Future<void> _loadPendingRequests(List<String> ids) async {
    print('📩 _loadPendingRequests: ${ids.length} ids — $ids');

    if (ids.isEmpty) {
      pendingRequests.value = [];
      return;
    }

    try {
      final users = await FirebaseService.getUsersByIds(ids);
      print('✅ pendingRequests loaded: ${users.length}');
      pendingRequests.value = users;
    } catch (e) {
      print('❌ _loadPendingRequests error: $e');
      pendingRequests.value = [];
    }
  }

  // ── Load all users ──────────────────────────────────────────────────────────
  Future<void> loadAllUsers() async {
    isLoadingUsers.value = true;
    errorMessage.value = '';
    try {
      final result =
      await FirebaseService.getAllUsers(currentUserId);
      allUsers.value = result;
      filteredUsers.value = result;
      print('✅ loadAllUsers: ${result.length} users');
    } catch (e) {
      print('❌ loadAllUsers error: $e');
      errorMessage.value = e.toString();
    } finally {
      isLoadingUsers.value = false;
    }
  }

  // ── Search ──────────────────────────────────────────────────────────────────
  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      searchQuery.value = query;
      _applyFilter(query);
    });
  }

  void _applyFilter(String query) {
    final base = allUsers
        .where((u) => u.id != currentUserId)
        .toList();

    if (query.trim().isEmpty) {
      filteredUsers.value = base;
    } else {
      filteredUsers.value = base.where((u) {
        final q = query.toLowerCase();
        return u.name.toLowerCase().contains(q) ||
            (u.email?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
  }

  // ── Relation helper ─────────────────────────────────────────────────────────
  UserRelation getRelation(String userId) {
    if (friendIds.contains(userId)) {
      return UserRelation.friend;
    }
    if (sentRequestIds.contains(userId)) {
      return UserRelation.requestSent;
    }
    if (receivedRequestIds.contains(userId)) {
      return UserRelation.requestReceived;
    }
    return UserRelation.none;
  }

  // ── Actions ─────────────────────────────────────────────────────────────────
  Future<void> sendRequest(String userId) async {
    try {
      await FirebaseService.sendFriendRequest(userId);
      Get.snackbar('Sent', 'Friend request sent',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Could not send request: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> cancelRequest(String userId) async {
    try {
      await FirebaseService.cancelFriendRequest(userId);
      Get.snackbar('Cancelled', 'Friend request cancelled',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Could not cancel: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> acceptRequest(String userId) async {
    try {
      await FirebaseService.acceptFriendRequest(userId);
      Get.snackbar('✅ Accepted', 'You are now friends!',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Could not accept: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> declineRequest(String userId) async {
    try {
      await FirebaseService.declineFriendRequest(userId);
      Get.snackbar('Declined', 'Friend request declined',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Could not decline: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}

enum UserRelation { none, requestSent, requestReceived, friend }