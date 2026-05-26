import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderProfilePic;
  final String content;
  final String type; // 'text', 'image', 'video', 'audio', 'location', 'file'
  final DateTime timestamp;
  final bool isRead;
  final String? mediaUrl;
  final String? audioDuration;
  final Map<String, dynamic>? location; // {'latitude': double, 'longitude': double, 'address': String}
  final String? fileName;
  final String? fileSize;
  final List<String> reactions; // Emoji reactions

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderProfilePic,
    required this.content,
    this.type = 'text',
    required this.timestamp,
    this.isRead = false,
    this.mediaUrl,
    this.audioDuration,
    this.location,
    this.fileName,
    this.fileSize,
    this.reactions = const [],
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderProfilePic: data['senderProfilePic'],
      content: data['content'] ?? '',
      type: data['type'] ?? 'text',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      mediaUrl: data['mediaUrl'],
      audioDuration: data['audioDuration'],
      location: data['location'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      reactions: List<String>.from(data['reactions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderProfilePic': senderProfilePic,
      'content': content,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'mediaUrl': mediaUrl,
      'audioDuration': audioDuration,
      'location': location,
      'fileName': fileName,
      'fileSize': fileSize,
      'reactions': reactions,
    };
  }

  // FIXED: Moved isMe getter here where senderId is defined
  bool get isMe {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && senderId == currentUser.uid;
  }

  // DEPRECATED: Remove this old property
  // bool get isSender => senderId == 'current_user_id';

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderProfilePic,
    String? content,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    String? mediaUrl,
    String? audioDuration,
    Map<String, dynamic>? location,
    String? fileName,
    String? fileSize,
    List<String>? reactions,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderProfilePic: senderProfilePic ?? this.senderProfilePic,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      audioDuration: audioDuration ?? this.audioDuration,
      location: location ?? this.location,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      reactions: reactions ?? this.reactions,
    );
  }
}

// Chat Room Model
class ChatRoom {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final Map<String, dynamic> participantNames;
  final Map<String, dynamic> participantPhotos;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.participantNames,
    required this.participantPhotos,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      unreadCount: data['unreadCount'] ?? 0,
      participantNames: data['participantNames'] ?? {},
      participantPhotos: data['participantPhotos'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
    };
  }

  // REMOVED: isMe getter from here - it doesn't belong in ChatRoom
  // If you need to check if current user is in this chat, use this instead:
  bool containsUser(String userId) => participants.contains(userId);

  // Get other participant ID (for 1-on-1 chats)
  String? getOtherParticipantId(String currentUserId) {
    if (participants.length != 2) return null;
    return participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => '',
    );
  }
}