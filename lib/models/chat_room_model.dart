// models/chat_room_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final bool isGroup;
  final String? groupName;
  final String? groupPhoto;
  final Map<String, dynamic>? participantNames;
  final Map<String, dynamic>? participantPhotos;
  final Map<String, int>? unreadCount;

  ChatRoom({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
    this.isGroup = false,
    this.groupName,
    this.groupPhoto,
    this.participantNames,
    this.participantPhotos,
    this.unreadCount,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGroup: data['isGroup'] ?? false,
      groupName: data['groupName'],
      groupPhoto: data['groupPhoto'],
      participantNames: data['participantNames'],
      participantPhotos: data['participantPhotos'],
      unreadCount: data['unreadCount']?.cast<String, int>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'isGroup': isGroup,
      'groupName': groupName,
      'groupPhoto': groupPhoto,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'unreadCount': unreadCount,
    };
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId);
  }
}