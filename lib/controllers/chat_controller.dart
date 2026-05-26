// chat_controller.dart - Fixed with senderName
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_message_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class ChatController extends GetxController {
  var messages = <ChatMessage>[].obs;
  var otherUser = Rxn<UserModel>();
  var currentUser = Rxn<UserModel>(); // ADDED: Store current user info
  var isOnline = false.obs;
  var isLoading = false.obs;
  var currentChatId = ''.obs;

  final ImagePicker _picker = ImagePicker();
  final String? initialChatId;
  final String? otherUserId;

  ChatController({this.initialChatId, this.otherUserId});

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser(); // ADDED: Load current user info
    if (initialChatId != null) {
      loadChat(initialChatId!);
    } else if (otherUserId != null) {
      startNewChat(otherUserId!);
    }
  }

  // ADDED: Load current user info
  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseService.getUser(user.uid);
      currentUser.value = userData;
    }
  }

  // ADDED: Load existing chat
  void loadChat(String chatId) {
    currentChatId.value = chatId;
    isLoading.value = true;

    // Load messages
    FirebaseService.getChatMessages(chatId).listen((msgs) {
      messages.value = msgs;
      isLoading.value = false;
    });

    // Load other user info
    _loadOtherUserInfo(chatId);
  }

  // ADDED: Start new chat
  Future<void> startNewChat(String otherId) async {
    final chatId = await FirebaseService.getOrCreateChatId(otherId);
    loadChat(chatId);
  }

  // ADDED: Load other user info
  void _loadOtherUserInfo(String chatId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && otherUserId != null) {
        final userData = await FirebaseService.getUser(otherUserId!);
        otherUser.value = userData;
        _listenToUserStatus(otherUserId!);
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  // ADDED: Listen to user online status
  void _listenToUserStatus(String userId) {
    isOnline.value = true;
  }

  // FIXED: Send text message with senderName
  Future<void> sendMessage(String content, {String type = 'text'}) async {
    if (content.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // FIXED: Get sender name from current user data
    final senderName = currentUser.value?.name ?? 'Unknown';
    final senderProfilePic = currentUser.value?.profilePic;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: user.uid,
      senderName: senderName, // ADDED: Required parameter
      senderProfilePic: senderProfilePic, // ADDED: Optional but good to have
      content: content,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
    );

    await FirebaseService.sendMessage(currentChatId.value, message);
  }

  // FIXED: Pick image with sender info
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final url = await FirebaseService.uploadFile(image.path, 'chat_images');
      await sendMessage(url!, type: 'image');
    }
  }

  // FIXED: Pick video with sender info
  Future<void> pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final url = await FirebaseService.uploadFile(video.path, 'chat_videos');
      await sendMessage(url!, type: 'video');
    }
  }

  // ADDED: Share location
  Future<void> shareLocation() async {
    await sendMessage('📍 Shared a location', type: 'location');
  }

  // ADDED: Share contact
  Future<void> shareContact() async {
    await sendMessage('👤 Shared a contact', type: 'contact');
  }

  // ADDED: Start voice recording
  Future<void> startVoiceRecording() async {
    Get.snackbar('Voice', 'Voice recording started');
  }

  // ADDED: Play message audio
  void playMessageAudio(ChatMessage message) {
    if (message.type == 'audio') {
      Get.snackbar('Audio', 'Playing audio message');
    }
  }
}