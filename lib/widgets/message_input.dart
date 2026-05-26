// message_input.dart - Widget implementation
import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final Function(String) onSend;
  final VoidCallback onAttachment;
  final VoidCallback onVoiceRecord;

  const MessageInput({
    Key? key,
    required this.onSend,
    required this.onAttachment,
    required this.onVoiceRecord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add, color: Colors.blue),
              onPressed: onAttachment,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    onSend(text);
                    controller.clear();
                  }
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.mic, color: Colors.blue),
              onPressed: onVoiceRecord,
            ),
            IconButton(
              icon: Icon(Icons.send, color: Colors.blue),
              onPressed: () {
                final text = controller.text;
                if (text.trim().isNotEmpty) {
                  onSend(text);
                  controller.clear();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}