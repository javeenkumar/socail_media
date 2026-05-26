// import 'dart:math' as math;
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class UserModel {
//   final String id;
//   final String name;
//   final String email;
//   final String? profilePic;
//   final String? bio;
//   final String? phone;
//   final DateTime? dateOfBirth;
//   final String gender; // 'male', 'female', 'other', 'prefer_not_to_say'
//   final List<String> interests;
//   final List<String> followers;
//   final List<String> following;
//   final List<String> friends; // ✅ ADDED: Friends list for chat functionality
//   final List<String> friendRequestsSent; // ✅ ADDED
//   final List<String> friendRequestsReceived; // ✅ ADDED
//   final Map<String, dynamic>? location; // {'latitude': double, 'longitude': double}
//   final bool isOnline;
//   final DateTime lastSeen;
//   final String? fcmToken;
//   final bool isVerified;
//   final String accountType; // 'user', 'creator', 'admin'
//   final Map<String, dynamic>? socialLinks;
//   final List<String> blockedUsers;
//   final bool isPrivate;
//   final Map<String, dynamic>? settings;
//
//   UserModel({
//     required this.id,
//     required this.name,
//     required this.email,
//     this.profilePic,
//     this.bio,
//     this.phone,
//     this.dateOfBirth,
//     this.gender = 'prefer_not_to_say',
//     this.interests = const [],
//     this.followers = const [],
//     this.following = const [],
//     this.friends = const [], // ✅ ADDED
//     this.friendRequestsSent = const [], // ✅ ADDED
//     this.friendRequestsReceived = const [], // ✅ ADDED
//     this.location,
//     this.isOnline = false,
//     required this.lastSeen,
//     this.fcmToken,
//     this.isVerified = false,
//     this.accountType = 'user',
//     this.socialLinks,
//     this.blockedUsers = const [],
//     this.isPrivate = false,
//     this.settings,
//   });
//
//   factory UserModel.fromFirestore(DocumentSnapshot doc) {
//     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//
//     // 🔧 FIXED: Safe list parsing helper
//     List<String> parseList(dynamic value) {
//       if (value == null) return [];
//       if (value is List) return List<String>.from(value);
//       if (value is int) return []; // Handle legacy count fields
//       return [];
//     }
//
//     return UserModel(
//       id: doc.id,
//       name: data['name'] ?? '',
//       email: data['email'] ?? '',
//       profilePic: data['profilePic'],
//       bio: data['bio'],
//       phone: data['phone'],
//       dateOfBirth: data['dateOfBirth'] != null
//           ? (data['dateOfBirth'] as Timestamp).toDate()
//           : null,
//       gender: data['gender'] ?? 'prefer_not_to_say',
//       interests: parseList(data['interests']),
//       followers: parseList(data['followers']),
//       following: parseList(data['following']),
//       friends: parseList(data['friends']), // ✅ ADDED
//       friendRequestsSent: parseList(data['friendRequestsSent']), // ✅ ADDED
//       friendRequestsReceived: parseList(data['friendRequestsReceived']), // ✅ ADDED
//       location: data['location'],
//       isOnline: data['isOnline'] ?? false,
//       lastSeen: data['lastSeen'] != null
//           ? (data['lastSeen'] as Timestamp).toDate()
//           : DateTime.now(),
//       fcmToken: data['fcmToken'],
//       isVerified: data['isVerified'] ?? false,
//       accountType: data['accountType'] ?? 'user',
//       socialLinks: data['socialLinks'],
//       blockedUsers: parseList(data['blockedUsers']),
//       isPrivate: data['isPrivate'] ?? false,
//       settings: data['settings'],
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'name': name,
//       'email': email,
//       'profilePic': profilePic,
//       'bio': bio,
//       'phone': phone,
//       'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
//       'gender': gender,
//       'interests': interests,
//       'followers': followers,
//       'following': following,
//       'friends': friends, // ✅ ADDED
//       'friendRequestsSent': friendRequestsSent, // ✅ ADDED
//       'friendRequestsReceived': friendRequestsReceived, // ✅ ADDED
//       'location': location,
//       'isOnline': isOnline,
//       'lastSeen': Timestamp.fromDate(lastSeen),
//       'fcmToken': fcmToken,
//       'isVerified': isVerified,
//       'accountType': accountType,
//       'socialLinks': socialLinks,
//       'blockedUsers': blockedUsers,
//       'isPrivate': isPrivate,
//       'settings': settings,
//     };
//   }
//
//   // ==================== FRIENDS HELPERS ====================
//
//   /// Check if user is friends with given user ID
//   bool isFriend(String userId) => friends.contains(userId);
//
//   /// Check if friend request sent to user
//   bool hasSentRequestTo(String userId) => friendRequestsSent.contains(userId);
//
//   /// Check if friend request received from user
//   bool hasReceivedRequestFrom(String userId) => friendRequestsReceived.contains(userId);
//
//   /// Get mutual friends count with another user
//   int mutualFriendsCount(UserModel other) {
//     return friends.where((id) => other.friends.contains(id)).length;
//   }
//
//   // ==================== LOCATION HELPERS ====================
//
//   double? get latitude => location?['latitude']?.toDouble();
//   double? get longitude => location?['longitude']?.toDouble();
//
//   double? distanceFrom(double lat, double lng) {
//     if (latitude == null || longitude == null) return null;
//
//     const R = 6371.0;
//     final lat1Rad = lat * (math.pi / 180.0);
//     final lat2Rad = latitude! * (math.pi / 180.0);
//     final dLat = (latitude! - lat) * (math.pi / 180.0);
//     final dLon = (longitude! - lng) * (math.pi / 180.0);
//
//     final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(lat1Rad) * math.cos(lat2Rad) * math.sin(dLon / 2) * math.sin(dLon / 2);
//     final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
//
//     return R * c;
//   }
//
//   // ==================== AGE HELPER ====================
//
//   int? get age {
//     if (dateOfBirth == null) return null;
//     final now = DateTime.now();
//     int age = now.year - dateOfBirth!.year;
//     if (now.month < dateOfBirth!.month ||
//         (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
//       age--;
//     }
//     return age;
//   }
//
//   // ==================== SOCIAL HELPERS ====================
//
//   int get followersCount => followers.length;
//   int get followingCount => following.length;
//   int get friendsCount => friends.length; // ✅ ADDED
//
//   bool isFollowing(String userId) => following.contains(userId);
//   bool isFollower(String userId) => followers.contains(userId);
//   bool hasBlocked(String userId) => blockedUsers.contains(userId);
//
//   // ==================== COPY WITH ====================
//
//   UserModel copyWith({
//     String? id,
//     String? name,
//     String? email,
//     String? profilePic,
//     String? bio,
//     String? phone,
//     DateTime? dateOfBirth,
//     String? gender,
//     List<String>? interests,
//     List<String>? followers,
//     List<String>? following,
//     List<String>? friends, // ✅ ADDED
//     List<String>? friendRequestsSent, // ✅ ADDED
//     List<String>? friendRequestsReceived, // ✅ ADDED
//     Map<String, dynamic>? location,
//     bool? isOnline,
//     DateTime? lastSeen,
//     String? fcmToken,
//     bool? isVerified,
//     String? accountType,
//     Map<String, dynamic>? socialLinks,
//     List<String>? blockedUsers,
//     bool? isPrivate,
//     Map<String, dynamic>? settings,
//   }) {
//     return UserModel(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       email: email ?? this.email,
//       profilePic: profilePic ?? this.profilePic,
//       bio: bio ?? this.bio,
//       phone: phone ?? this.phone,
//       dateOfBirth: dateOfBirth ?? this.dateOfBirth,
//       gender: gender ?? this.gender,
//       interests: interests ?? this.interests,
//       followers: followers ?? this.followers,
//       following: following ?? this.following,
//       friends: friends ?? this.friends, // ✅ ADDED
//       friendRequestsSent: friendRequestsSent ?? this.friendRequestsSent, // ✅ ADDED
//       friendRequestsReceived: friendRequestsReceived ?? this.friendRequestsReceived, // ✅ ADDED
//       location: location ?? this.location,
//       isOnline: isOnline ?? this.isOnline,
//       lastSeen: lastSeen ?? this.lastSeen,
//       fcmToken: fcmToken ?? this.fcmToken,
//       isVerified: isVerified ?? this.isVerified,
//       accountType: accountType ?? this.accountType,
//       socialLinks: socialLinks ?? this.socialLinks,
//       blockedUsers: blockedUsers ?? this.blockedUsers,
//       isPrivate: isPrivate ?? this.isPrivate,
//       settings: settings ?? this.settings,
//     );
//   }
// }

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profilePic;
  final String? bio;
  final String? phone;
  final DateTime? dateOfBirth;
  final String gender;
  final List<String> interests;
  final List<String> followers;
  final List<String> following;
  final List<String> friends;
  final List<String> friendRequestsSent;
  final List<String> friendRequestsReceived;
  final Map<String, dynamic>? location;
  final bool isOnline;
  final DateTime lastSeen;
  final String? fcmToken;
  final bool isVerified;
  final String accountType;
  final Map<String, dynamic>? socialLinks;
  final List<String> blockedUsers;
  final bool isPrivate;
  final Map<String, dynamic>? settings;

  // ADDED: Runtime properties (not stored in Firestore)
  double? distance;
  DateTime? get lastActive => isOnline ? DateTime.now() : lastSeen;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePic,
    this.bio,
    this.phone,
    this.dateOfBirth,
    this.gender = 'prefer_not_to_say',
    this.interests = const [],
    this.followers = const [],
    this.following = const [],
    this.friends = const [],
    this.friendRequestsSent = const [],
    this.friendRequestsReceived = const [],
    this.location,
    this.isOnline = false,
    required this.lastSeen,
    this.fcmToken,
    this.isVerified = false,
    this.accountType = 'user',
    this.socialLinks,
    this.blockedUsers = const [],
    this.isPrivate = false,
    this.settings,
    this.distance,
  });

  /// ✅ FIXED: Properly cast Firestore document data
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    // ✅ CRITICAL FIX: Handle null data and properly cast to Map<String, dynamic>
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // ✅ FIXED: Safe list parsing helper with null check
    List<String> parseList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        // ✅ Ensure all items are converted to String safely
        return value.where((item) => item != null).map((item) => item.toString()).toList();
      }
      if (value is int) return []; // Handle legacy count fields
      return [];
    }

    // ✅ FIXED: Safe string getter with null check
    String? getString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      return value.toString();
    }

    // ✅ FIXED: Safe bool getter
    bool getBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      return defaultValue;
    }

    return UserModel(
      id: doc.id,
      name: getString(data['name']) ?? 'Unknown User', // ✅ Default value for null
      email: getString(data['email']) ?? '',
      profilePic: getString(data['profilePic']),
      bio: getString(data['bio']),
      phone: getString(data['phone']),
      dateOfBirth: data['dateOfBirth'] != null && data['dateOfBirth'] is Timestamp
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      gender: getString(data['gender']) ?? 'prefer_not_to_say',
      interests: parseList(data['interests']),
      followers: parseList(data['followers']),
      following: parseList(data['following']),
      friends: parseList(data['friends']),
      friendRequestsSent: parseList(data['friendRequestsSent']),
      friendRequestsReceived: parseList(data['friendRequestsReceived']),
      location: data['location'] is Map<String, dynamic>
          ? data['location'] as Map<String, dynamic>
          : null,
      isOnline: getBool(data['isOnline'], false),
      lastSeen: data['lastSeen'] != null && data['lastSeen'] is Timestamp
          ? (data['lastSeen'] as Timestamp).toDate()
          : DateTime.now(),
      fcmToken: getString(data['fcmToken']),
      isVerified: getBool(data['isVerified'], false),
      accountType: getString(data['accountType']) ?? 'user',
      socialLinks: data['socialLinks'] is Map<String, dynamic>
          ? data['socialLinks'] as Map<String, dynamic>
          : null,
      blockedUsers: parseList(data['blockedUsers']),
      isPrivate: getBool(data['isPrivate'], false),
      settings: data['settings'] is Map<String, dynamic>
          ? data['settings'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profilePic': profilePic,
      'bio': bio,
      'phone': phone,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'interests': interests,
      'followers': followers,
      'following': following,
      'friends': friends,
      'friendRequestsSent': friendRequestsSent,
      'friendRequestsReceived': friendRequestsReceived,
      'location': location,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'fcmToken': fcmToken,
      'isVerified': isVerified,
      'accountType': accountType,
      'socialLinks': socialLinks,
      'blockedUsers': blockedUsers,
      'isPrivate': isPrivate,
      'settings': settings,
    };
  }

  // Helper methods remain the same...
  bool isFriend(String userId) => friends.contains(userId);
  bool hasSentRequestTo(String userId) => friendRequestsSent.contains(userId);
  bool hasReceivedRequestFrom(String userId) => friendRequestsReceived.contains(userId);

  int mutualFriendsCount(UserModel other) {
    return friends.where((id) => other.friends.contains(id)).length;
  }

  double? get latitude => location?['latitude']?.toDouble();
  double? get longitude => location?['longitude']?.toDouble();

  double? distanceFrom(double lat, double lng) {
    if (latitude == null || longitude == null) return null;

    const R = 6371.0;
    final lat1Rad = lat * (math.pi / 180.0);
    final lat2Rad = latitude! * (math.pi / 180.0);
    final dLat = (latitude! - lat) * (math.pi / 180.0);
    final dLon = (longitude! - lng) * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  int get followersCount => followers.length;
  int get followingCount => following.length;
  int get friendsCount => friends.length;

  bool isFollowing(String userId) => following.contains(userId);
  bool isFollower(String userId) => followers.contains(userId);
  bool hasBlocked(String userId) => blockedUsers.contains(userId);

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePic,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    List<String>? interests,
    List<String>? followers,
    List<String>? following,
    List<String>? friends,
    List<String>? friendRequestsSent,
    List<String>? friendRequestsReceived,
    Map<String, dynamic>? location,
    bool? isOnline,
    DateTime? lastSeen,
    String? fcmToken,
    bool? isVerified,
    String? accountType,
    Map<String, dynamic>? socialLinks,
    List<String>? blockedUsers,
    bool? isPrivate,
    Map<String, dynamic>? settings,
    double? distance,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      interests: interests ?? this.interests,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      friends: friends ?? this.friends,
      friendRequestsSent: friendRequestsSent ?? this.friendRequestsSent,
      friendRequestsReceived: friendRequestsReceived ?? this.friendRequestsReceived,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      isVerified: isVerified ?? this.isVerified,
      accountType: accountType ?? this.accountType,
      socialLinks: socialLinks ?? this.socialLinks,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      isPrivate: isPrivate ?? this.isPrivate,
      settings: settings ?? this.settings,
      distance: distance ?? this.distance,
    );
  }
}