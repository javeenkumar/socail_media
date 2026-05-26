// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class Reel {
//   final String id;
//   final String userId;
//   final String userName;
//   final String userProfilePic;
//   final String videoUrl;
//   final String caption;
//   final String audioTitle;
//   final String? audioUrl;
//   final List<String> likes;
//   final int commentsCount;
//   final List<String> views;
//   final DateTime timestamp;
//   final List<String> hashtags;
//   final bool allowComments;
//   final bool allowDuet;
//   final String? thumbnailUrl;
//   final bool isLiked; // Local property
//
//   Reel({
//     required this.id,
//     required this.userId,
//     required this.userName,
//     required this.userProfilePic,
//     required this.videoUrl,
//     required this.caption,
//     required this.audioTitle,
//     this.audioUrl,
//     this.likes = const [],
//     this.commentsCount = 0,
//     this.views = const [],
//     required this.timestamp,
//     this.hashtags = const [],
//     this.allowComments = true,
//     this.allowDuet = true,
//     this.thumbnailUrl,
//     this.isLiked = false,
//   });
//
//   factory Reel.fromFirestore(DocumentSnapshot doc) {
//     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//
//     return Reel(
//       id: doc.id,
//       userId: data['userId'] ?? '',
//       userName: data['userName'] ?? '',
//       userProfilePic: data['userProfilePic'] ?? '',
//       videoUrl: data['videoUrl'] ?? '',
//       caption: data['caption'] ?? '',
//       audioTitle: data['audioTitle'] ?? 'Original Audio',
//       audioUrl: data['audioUrl'],
//       likes: List<String>.from(data['likes'] ?? []),
//       commentsCount: data['commentsCount'] ?? 0,
//       views: List<String>.from(data['views'] ?? []),
//       timestamp: (data['timestamp'] as Timestamp).toDate(),
//       hashtags: List<String>.from(data['hashtags'] ?? []),
//       allowComments: data['allowComments'] ?? true,
//       allowDuet: data['allowDuet'] ?? true,
//       thumbnailUrl: data['thumbnailUrl'],
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'userId': userId,
//       'userName': userName,
//       'userProfilePic': userProfilePic,
//       'videoUrl': videoUrl,
//       'caption': caption,
//       'audioTitle': audioTitle,
//       'audioUrl': audioUrl,
//       'likes': likes,
//       'commentsCount': commentsCount,
//       'views': views,
//       'timestamp': Timestamp.fromDate(timestamp),
//       'hashtags': hashtags,
//       'allowComments': allowComments,
//       'allowDuet': allowDuet,
//       'thumbnailUrl': thumbnailUrl,
//     };
//   }
//
//   Reel copyWith({
//     String? id,
//     String? userId,
//     String? userName,
//     String? userProfilePic,
//     String? videoUrl,
//     String? caption,
//     String? audioTitle,
//     String? audioUrl,
//     List<String>? likes,
//     int? commentsCount,
//     List<String>? views,
//     DateTime? timestamp,
//     List<String>? hashtags,
//     bool? allowComments,
//     bool? allowDuet,
//     String? thumbnailUrl,
//     bool? isLiked,
//   }) {
//     return Reel(
//       id: id ?? this.id,
//       userId: userId ?? this.userId,
//       userName: userName ?? this.userName,
//       userProfilePic: userProfilePic ?? this.userProfilePic,
//       videoUrl: videoUrl ?? this.videoUrl,
//       caption: caption ?? this.caption,
//       audioTitle: audioTitle ?? this.audioTitle,
//       audioUrl: audioUrl ?? this.audioUrl,
//       likes: likes ?? this.likes,
//       commentsCount: commentsCount ?? this.commentsCount,
//       views: views ?? this.views,
//       timestamp: timestamp ?? this.timestamp,
//       hashtags: hashtags ?? this.hashtags,
//       allowComments: allowComments ?? this.allowComments,
//       allowDuet: allowDuet ?? this.allowDuet,
//       thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
//       isLiked: isLiked ?? this.isLiked,
//     );
//   }
// }
//
//



// reel_model.dart - ADD ReelComment class
import 'package:cloud_firestore/cloud_firestore.dart';

class ReelComment {
  final String id;
  final String userId;
  final String userName;
  final String userPic;
  final String text;
  final DateTime timestamp;

  ReelComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPic,
    required this.text,
    required this.timestamp,
  });

  factory ReelComment.fromMap(Map<String, dynamic> map) {
    return ReelComment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPic: map['userPic'] ?? '',
      text: map['text'] ?? map['content'] ?? '',
      timestamp: _parseTimestamp(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPic': userPic,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else {
      return DateTime.now();
    }
  }
}

class Reel {
  final String id;
  final String userId;
  final String userName;
  final String userProfilePic;
  final String videoUrl;
  final String caption;
  final String audioTitle;
  final String? audioUrl;
  final List<String> likes;
  final int commentsCount;
  final List<ReelComment> comments;
  final List<String> views;
  final DateTime timestamp;
  final List<String> hashtags;
  final bool allowComments;
  final bool allowDuet;
  final String? thumbnailUrl;
  final bool isLiked;

  Reel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfilePic,
    required this.videoUrl,
    required this.caption,
    required this.audioTitle,
    this.audioUrl,
    this.likes = const [],
    this.commentsCount = 0,
    this.comments = const [],
    this.views = const [],
    required this.timestamp,
    this.hashtags = const [],
    this.allowComments = true,
    this.allowDuet = true,
    this.thumbnailUrl,
    this.isLiked = false,
  });

  factory Reel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<ReelComment> parsedComments = [];
    if (data['comments'] != null) {
      parsedComments = (data['comments'] as List)
          .map((c) => ReelComment.fromMap(c as Map<String, dynamic>))
          .toList();
    }

    return Reel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userProfilePic: data['userProfilePic'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      caption: data['caption'] ?? '',
      audioTitle: data['audioTitle'] ?? 'Original Audio',
      audioUrl: data['audioUrl'],
      likes: List<String>.from(data['likes'] ?? data['likedBy'] ?? []),
      commentsCount: data['commentsCount'] ?? 0,
      comments: parsedComments,
      views: List<String>.from(data['views'] ?? []),
      timestamp: ReelComment._parseTimestamp(data['timestamp']),
      hashtags: List<String>.from(data['hashtags'] ?? []),
      allowComments: data['allowComments'] ?? true,
      allowDuet: data['allowDuet'] ?? true,
      thumbnailUrl: data['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfilePic': userProfilePic,
      'videoUrl': videoUrl,
      'caption': caption,
      'audioTitle': audioTitle,
      'audioUrl': audioUrl,
      'likes': likes,
      'commentsCount': commentsCount,
      'comments': comments.map((c) => c.toMap()).toList(),
      'views': views,
      'timestamp': Timestamp.fromDate(timestamp),
      'hashtags': hashtags,
      'allowComments': allowComments,
      'allowDuet': allowDuet,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  Reel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfilePic,
    String? videoUrl,
    String? caption,
    String? audioTitle,
    String? audioUrl,
    List<String>? likes,
    int? commentsCount,
    List<ReelComment>? comments,
    List<String>? views,
    DateTime? timestamp,
    List<String>? hashtags,
    bool? allowComments,
    bool? allowDuet,
    String? thumbnailUrl,
    bool? isLiked,
  }) {
    return Reel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePic: userProfilePic ?? this.userProfilePic,
      videoUrl: videoUrl ?? this.videoUrl,
      caption: caption ?? this.caption,
      audioTitle: audioTitle ?? this.audioTitle,
      audioUrl: audioUrl ?? this.audioUrl,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      comments: comments ?? this.comments,
      views: views ?? this.views,
      timestamp: timestamp ?? this.timestamp,
      hashtags: hashtags ?? this.hashtags,
      allowComments: allowComments ?? this.allowComments,
      allowDuet: allowDuet ?? this.allowDuet,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}