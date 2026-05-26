// chat_bubble.dart - Fixed with proper isMe access
import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onTap;

  const ChatBubble({
    Key? key,
    required this.message,
    this.onTap,
  }) : super(key: key);

  // ADD: Getter to determine if message is from current user
  bool get _isMe => message.isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContent(),
            SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: _isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (message.type) {
      case 'image':
        return Image.network(
          message.content,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        );
      case 'video':
        return Container(
          width: 200,
          height: 200,
          color: Colors.black,
          child: Icon(Icons.play_circle, color: Colors.white),
        );
      case 'audio':
        return GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow, color: _isMe ? Colors.white : Colors.black),
              SizedBox(width: 8),
              Text(
                  'Audio message',
                  style: TextStyle(color: _isMe ? Colors.white : Colors.black)
              ),
            ],
          ),
        );
      case 'location':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: Colors.red),
            SizedBox(width: 4),
            Text(
                'Location',
                style: TextStyle(color: _isMe ? Colors.white : Colors.black)
            ),
          ],
        );
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: _isMe ? Colors.white : Colors.black,
          ),
        );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}