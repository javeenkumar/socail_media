// Updated ChatScreen with proper controller initialization
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatelessWidget {
  final String? chatId;
  final String? otherUserId;
  late final ChatController controller;

  ChatScreen({this.chatId, this.otherUserId}) {
    controller = Get.put(ChatController(
      initialChatId: chatId,
      otherUserId: otherUserId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Row(
          children: [
            CircleAvatar(
              backgroundImage: controller.otherUser.value?.profilePic != null
                  ? NetworkImage(controller.otherUser.value!.profilePic!)
                  : null,
              child: controller.otherUser.value?.profilePic == null
                  ? Icon(Icons.person)
                  : null,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(controller.otherUser.value?.name ?? 'Chat'),
                Text(
                  controller.isOnline.value ? 'Online' : 'Offline',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        )),
        actions: [
          IconButton(icon: Icon(Icons.video_call), onPressed: () {}),
          IconButton(icon: Icon(Icons.call), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                reverse: true,
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  return ChatBubble(
                    message: message,
                    onTap: () => controller.playMessageAudio(message),
                  );
                },
              );
            }),
          ),
          MessageInput(
            onSend: (text) => controller.sendMessage(text),
            onAttachment: () => _showAttachmentOptions(),
            onVoiceRecord: () => controller.startVoiceRecording(),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: Get.context!,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.image, color: Colors.blue),
              title: Text('Photo'),
              onTap: () {
                Get.back();
                controller.pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.video_library, color: Colors.red),
              title: Text('Video'),
              onTap: () {
                Get.back();
                controller.pickVideo();
              },
            ),
            ListTile(
              leading: Icon(Icons.location_on, color: Colors.green),
              title: Text('Location'),
              onTap: () {
                Get.back();
                controller.shareLocation();
              },
            ),
            ListTile(
              leading: Icon(Icons.contacts, color: Colors.orange),
              title: Text('Contact'),
              onTap: () {
                Get.back();
                controller.shareContact();
              },
            ),
          ],
        ),
      ),
    );
  }
}