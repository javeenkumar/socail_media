import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type; // 'like', 'comment', 'follow', 'mention', 'message', 'live'
  final String senderId;
  final String senderName;
  final String? senderProfilePic;
  final String? postId;
  final String? postImage;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.senderId,
    required this.senderName,
    this.senderProfilePic,
    this.postId,
    this.postImage,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      type: data['type'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderProfilePic: data['senderProfilePic'],
      postId: data['postId'],
      postImage: data['postImage'],
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfilePic': senderProfilePic,
      'postId': postId,
      'postImage': postImage,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  String get notificationText {
    switch (type) {
      case 'like':
        return '$senderName liked your post';
      case 'comment':
        return '$senderName commented: $content';
      case 'follow':
        return '$senderName started following you';
      case 'mention':
        return '$senderName mentioned you in a comment';
      case 'message':
        return '$senderName sent you a message';
      case 'live':
        return '$senderName is live now: $content';
      default:
        return content;
    }
  }
}