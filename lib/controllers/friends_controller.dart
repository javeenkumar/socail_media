import 'dart:async';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class FriendsController extends GetxController {
  var friends = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  StreamSubscription? _friendsSubscription;

  @override
  void onInit() {
    super.onInit();
    loadFriends();
  }

  @override
  void onClose() {
    _friendsSubscription?.cancel();
    super.onClose();
  }

  void loadFriends() {
    isLoading.value = true;
    errorMessage.value = '';

    _friendsSubscription?.cancel(); // cancel any existing subscription

    _friendsSubscription = FirebaseService.getFriendsWithChatInfo().listen(
          (friendsList) {
        print('✅ Friends loaded: ${friendsList.length}');
        friends.value = friendsList;
        isLoading.value = false;
      },
      onError: (error) {
        print('❌ Error loading friends: $error');
        errorMessage.value = error.toString();
        isLoading.value = false;
      },
    );
  }

  Future<void> markAsRead(String chatId) async {
    await FirebaseService.markMessagesAsRead(chatId);
  }

  Future<void> addFriend(String userId) async {
    try {
      await FirebaseService.acceptFriendRequest(userId);
      Get.snackbar('Success', 'Friend added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add friend: $e');
    }
  }
}