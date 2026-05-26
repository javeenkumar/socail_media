// models/live_stream_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveStreamStatus {
  static const String live = 'live';
  static const String ended = 'ended';
  static const String scheduled = 'scheduled';
}

class LiveComment {
  final String userId;
  final String userName;
  final String userPic;
  final String text;
  final DateTime timestamp;

  LiveComment({
    required this.userId,
    required this.userName,
    required this.userPic,
    required this.text,
    required this.timestamp,
  });

  factory LiveComment.fromMap(Map<String, dynamic> map) {
    return LiveComment(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPic: map['userPic'] ?? '',
      text: map['text'] ?? '',
      timestamp: _parseDateTime(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPic': userPic,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
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
}

class LiveStream {
  final String id;
  final String userId;
  final String userName;
  final String? userProfilePic;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isLive;
  final String status;
  final int viewerCount;
  final List<String> viewers;
  final List<LiveComment> comments;
  final String? thumbnailUrl;
  final String? streamUrl;
  final String? playbackUrl;
  final String? category;
  final bool allowComments;
  final bool isPrivate;
  final List<String> bannedUsers;
  final String? recordingUrl;      // ✅ ADDED
  final String? recordingStatus; // ✅ ADDED

  LiveStream({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfilePic,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.isLive = true,
    this.status = LiveStreamStatus.live,
    this.viewerCount = 0,
    this.viewers = const [],
    this.comments = const [],
    this.thumbnailUrl,
    this.streamUrl,
    this.playbackUrl,
    this.category,
    this.allowComments = true,
    this.isPrivate = false,
    this.bannedUsers = const [],
    this.recordingUrl,      // ✅ ADDED
    this.recordingStatus,   // ✅ ADDED
  });

  factory LiveStream.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<LiveComment> parsedComments = [];
    if (data['comments'] != null) {
      parsedComments = (data['comments'] as List)
          .map((c) => LiveComment.fromMap(c as Map<String, dynamic>))
          .toList();
    }

    return LiveStream(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userProfilePic: data['userProfilePic'],
      title: data['title'] ?? '',
      description: data['description'],
      startTime: _parseDateTime(data['startTime']),
      endTime: data['endTime'] != null ? _parseDateTime(data['endTime']) : null,
      isLive: data['isLive'] ?? false,
      status: data['status'] ?? LiveStreamStatus.ended,
      viewerCount: data['viewerCount'] ?? 0,
      viewers: List<String>.from(data['viewers'] ?? []),
      comments: parsedComments,
      thumbnailUrl: data['thumbnailUrl'],
      streamUrl: data['streamUrl'],
      playbackUrl: data['playbackUrl'],
      category: data['category'],
      allowComments: data['allowComments'] ?? true,
      isPrivate: data['isPrivate'] ?? false,
      bannedUsers: List<String>.from(data['bannedUsers'] ?? []),
      recordingUrl: data['recordingUrl'],      // ✅ ADDED
      recordingStatus: data['recordingStatus'], // ✅ ADDED
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfilePic': userProfilePic,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'isLive': isLive,
      'status': status,
      'viewerCount': viewerCount,
      'viewers': viewers,
      'comments': comments.map((c) => c.toMap()).toList(),
      'thumbnailUrl': thumbnailUrl,
      'streamUrl': streamUrl,
      'playbackUrl': playbackUrl,
      'category': category,
      'allowComments': allowComments,
      'isPrivate': isPrivate,
      'bannedUsers': bannedUsers,
      'recordingUrl': recordingUrl,      // ✅ ADDED
      'recordingStatus': recordingStatus, // ✅ ADDED
    };
  }

  // ✅ Computed properties (read-only, no business logic)
  String get hostName => userName;
  String? get thumbnail => thumbnailUrl ?? userProfilePic;
  bool get isViewer => !isLive && playbackUrl != null;
  Duration? get duration => endTime?.difference(startTime);

  static DateTime _parseDateTime(dynamic value) {
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

  LiveStream copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfilePic,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isLive,
    String? status,
    int? viewerCount,
    List<String>? viewers,
    List<LiveComment>? comments,
    String? thumbnailUrl,
    String? streamUrl,
    String? playbackUrl,
    String? category,
    bool? allowComments,
    bool? isPrivate,
    List<String>? bannedUsers,
    String? recordingUrl,
    String? recordingStatus,
  }) {
    return LiveStream(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePic: userProfilePic ?? this.userProfilePic,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isLive: isLive ?? this.isLive,
      status: status ?? this.status,
      viewerCount: viewerCount ?? this.viewerCount,
      viewers: viewers ?? this.viewers,
      comments: comments ?? this.comments,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      playbackUrl: playbackUrl ?? this.playbackUrl,
      category: category ?? this.category,
      allowComments: allowComments ?? this.allowComments,
      isPrivate: isPrivate ?? this.isPrivate,
      bannedUsers: bannedUsers ?? this.bannedUsers,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      recordingStatus: recordingStatus ?? this.recordingStatus,
    );
  }
}