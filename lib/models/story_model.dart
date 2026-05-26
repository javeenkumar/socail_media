// story_model.dart - Updated with items list support
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryItem {
  final String id;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String mediaType;
  final List<String> viewers;
  final DateTime timestamp;

  StoryItem({
    required this.id,
    required this.mediaUrl,
    this.thumbnailUrl,
    required this.mediaType,
    this.viewers = const [],
    required this.timestamp,
  });

  factory StoryItem.fromMap(Map<String, dynamic> data) {
    return StoryItem(
      id: data['id'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      mediaType: data['mediaType'] ?? 'image',
      viewers: List<String>.from(data['viewers'] ?? []),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'mediaType': mediaType,
      'viewers': viewers,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class Story {
  final String id;
  final String userId;
  final String userName;
  final String? userProfilePic;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String mediaType;
  final DateTime timestamp;
  final DateTime expiresAt;
  final List<String> viewers;
  final String? caption;
  final List<String> stickers;
  final String? backgroundColor;
  final String? textOverlay;
  final String? musicTrackId;
  final List<StoryItem> items; // ADDED: Support for multiple items

  Story({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfilePic,
    required this.mediaUrl,
    this.thumbnailUrl,
    required this.mediaType,
    required this.timestamp,
    required this.expiresAt,
    this.viewers = const [],
    this.caption,
    this.stickers = const [],
    this.backgroundColor,
    this.textOverlay,
    this.musicTrackId,
    this.items = const [], // ADDED
  });

  factory Story.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse items if they exist
    List<StoryItem> parsedItems = [];
    if (data['items'] != null) {
      parsedItems = (data['items'] as List)
          .map((item) => StoryItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return Story(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userProfilePic: data['userProfilePic'],
      mediaUrl: data['mediaUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      mediaType: data['mediaType'] ?? 'image',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      viewers: List<String>.from(data['viewers'] ?? []),
      caption: data['caption'],
      stickers: List<String>.from(data['stickers'] ?? []),
      backgroundColor: data['backgroundColor'],
      textOverlay: data['textOverlay'],
      musicTrackId: data['musicTrackId'],
      items: parsedItems,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfilePic': userProfilePic,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'mediaType': mediaType,
      'timestamp': Timestamp.fromDate(timestamp),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewers': viewers,
      'caption': caption,
      'stickers': stickers,
      'backgroundColor': backgroundColor,
      'textOverlay': textOverlay,
      'musicTrackId': musicTrackId,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool isViewedBy(String userId) => viewers.contains(userId);
}