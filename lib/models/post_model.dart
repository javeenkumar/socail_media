// post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userProfilePic;
  final String content;
  final String? mediaUrl;
  final String mediaType; // 'image', 'video', 'none', 'live_replay'
  final String platform; // 'facebook', 'instagram', 'twitter', 'tiktok', 'linkedin', 'app'
  final List<String> likes;
  final int commentsCount;
  final DateTime timestamp;
  final String privacy; // 'public', 'friends', 'only_me'
  final List<String> tags;
  final String? location;
  final bool isLiked; // Local property for UI

  // Live replay fields
  final bool isLiveReplay;
  final String? originalStreamId;
  final DateTime? streamStartTime;
  final int? viewCount;
  final String? streamDuration; // e.g., "45:30" for 45 mins 30 secs

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfilePic,
    required this.content,
    this.mediaUrl,
    this.mediaType = 'none',
    this.platform = 'app',
    this.likes = const [],
    this.commentsCount = 0,
    required this.timestamp,
    this.privacy = 'public',
    this.tags = const [],
    this.location,
    this.isLiked = false,
    this.isLiveReplay = false,
    this.originalStreamId,
    this.streamStartTime,
    this.viewCount = 0,
    this.streamDuration,
  });

  // factory Post.fromFirestore(DocumentSnapshot doc) {
  //   Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //
  //   return Post(
  //     id: doc.id,
  //     userId: data['userId'] ?? '',
  //     userName: data['userName'] ?? '',
  //     userProfilePic: data['userProfilePic'],
  //     content: data['content'] ?? '',
  //     mediaUrl: data['mediaUrl'],
  //     mediaType: data['mediaType'] ?? 'none',
  //     platform: data['platform'] ?? 'app',
  //     likes: List<String>.from(data['likes'] ?? []),
  //     commentsCount: data['commentsCount'] ?? 0,
  //     timestamp: _parseTimestamp(data['timestamp']),
  //     privacy: data['privacy'] ?? 'public',
  //     tags: List<String>.from(data['tags'] ?? []),
  //     location: data['location'],
  //     isLiked: false,
  //     // ✅ FIXED: Parse live replay fields
  //     isLiveReplay: data['isLiveReplay'] ?? false,
  //     originalStreamId: data['originalStreamId'],
  //     streamStartTime: data['streamStartTime'] != null
  //         ? _parseTimestamp(data['streamStartTime'])
  //         : null,
  //     viewCount: data['viewCount'] ?? 0,
  //     streamDuration: data['streamDuration'],
  //   );
  // }

  // In post_model.dart, update the fromFirestore factory:

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // ✅ FIXED: Handle likes as either List or int
    List<String> likesList = [];
    if (data['likes'] is List) {
      likesList = List<String>.from(data['likes']);
    } else if (data['likes'] is int) {
      // If likes is stored as count, check 'likedBy' field for actual users
      likesList = data['likedBy'] != null
          ? List<String>.from(data['likedBy'])
          : [];
    }

    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userProfilePic: data['userProfilePic'],
      content: data['content'] ?? '',
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'] ?? 'none',
      platform: data['platform'] ?? 'app',
      likes: likesList, // ✅ Use the parsed list
      commentsCount: data['commentsCount'] ?? 0,
      timestamp: _parseTimestamp(data['timestamp']),
      privacy: data['privacy'] ?? 'public',
      tags: List<String>.from(data['tags'] ?? []),
      location: data['location'],
      isLiked: false,
      isLiveReplay: data['isLiveReplay'] ?? false,
      originalStreamId: data['originalStreamId'],
      streamStartTime: data['streamStartTime'] != null
          ? _parseTimestamp(data['streamStartTime'])
          : null,
      viewCount: data['viewCount'] ?? 0,
      streamDuration: data['streamDuration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfilePic': userProfilePic,
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'platform': platform,
      'likes': likes,
      'commentsCount': commentsCount,
      'timestamp': Timestamp.fromDate(timestamp),
      'privacy': privacy,
      'tags': tags,
      'location': location,
      // ✅ FIXED: Include live replay fields in map
      'isLiveReplay': isLiveReplay,
      'originalStreamId': originalStreamId,
      'streamStartTime': streamStartTime != null
          ? Timestamp.fromDate(streamStartTime!)
          : null,
      'viewCount': viewCount,
      'streamDuration': streamDuration,
    };
  }

  // ✅ ADDED: Helper method for safe timestamp parsing
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  // ✅ ADDED: Check if post has video content
  bool get hasVideo => mediaType == 'video' || mediaType == 'live_replay';

  // ✅ ADDED: Get display title for live replays
  String get displayTitle {
    if (isLiveReplay) {
      return content.replaceFirst('📺 Was LIVE: ', '').split('\n').first;
    }
    return content;
  }

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfilePic,
    String? content,
    String? mediaUrl,
    String? mediaType,
    String? platform,
    List<String>? likes,
    int? commentsCount,
    DateTime? timestamp,
    String? privacy,
    List<String>? tags,
    String? location,
    bool? isLiked,
    bool? isLiveReplay,
    String? originalStreamId,
    DateTime? streamStartTime,
    int? viewCount,
    String? streamDuration,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePic: userProfilePic ?? this.userProfilePic,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      platform: platform ?? this.platform,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      timestamp: timestamp ?? this.timestamp,
      privacy: privacy ?? this.privacy,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      isLiked: isLiked ?? this.isLiked,
      isLiveReplay: isLiveReplay ?? this.isLiveReplay,
      originalStreamId: originalStreamId ?? this.originalStreamId,
      streamStartTime: streamStartTime ?? this.streamStartTime,
      viewCount: viewCount ?? this.viewCount,
      streamDuration: streamDuration ?? this.streamDuration,
    );
  }
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String? userProfilePic;
  final String content;
  final DateTime timestamp;
  final List<String> likes;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfilePic,
    required this.content,
    required this.timestamp,
    this.likes = const [],
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Comment(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userProfilePic: data['userProfilePic'],
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: (data['likes'] is List)
          ? List<String>.from(data['likes'])
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfilePic': userProfilePic,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
    };
  }
}