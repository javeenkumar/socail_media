import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import '../controllers/nearby_controller.dart';
import '../models/post_model.dart';
import '../models/reel_model.dart';
import '../models/story_model.dart';
import '../models/chat_message_model.dart';
import '../models/live_stream_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const Uuid _uuid = Uuid();

  // Get current user
  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;

  // Collections
  static CollectionReference get posts => _firestore.collection('posts');
  static CollectionReference get stories => _firestore.collection('stories');
  static CollectionReference get reels => _firestore.collection('reels');
  static CollectionReference get users => _firestore.collection('users');
  static CollectionReference get chats => _firestore.collection('chats');
  static CollectionReference get liveStreams => _firestore.collection('live_streams');

  // ==================== AUTH ====================

  /// ✅ FIXED: Added comprehensive error handling for sign in
  static Future<UserCredential?> signIn(String email, String password) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Email and password cannot be empty',
        );
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Update last active timestamp
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).update({
          'lastActive': Timestamp.now(),
          'isOnline': true,
        });
      }

      return credential;

    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors [^2^][^6^]
      switch (e.code) {
        case 'user-not-found':
          print('❌ No user found for that email.');
          throw FirebaseAuthException(
            code: e.code,
            message: 'No account found with this email. Please register first.',
          );
        case 'wrong-password':
          print('❌ Wrong password provided.');
          throw FirebaseAuthException(
            code: e.code,
            message: 'Incorrect password. Please try again.',
          );
        case 'invalid-email':
          print('❌ Invalid email format.');
          throw FirebaseAuthException(
            code: e.code,
            message: 'Please enter a valid email address.',
          );
        case 'user-disabled':
          print('❌ User account has been disabled.');
          throw FirebaseAuthException(
            code: e.code,
            message: 'This account has been disabled. Contact support.',
          );
        case 'too-many-requests':
          print('❌ Too many failed attempts.');
          throw FirebaseAuthException(
            code: e.code,
            message: 'Too many failed login attempts. Please try again later.',
          );
        case 'network-request-failed':
          print('❌ Network error.');
          throw FirebaseAuthException(
            code: e.code,
            message: 'Network error. Please check your internet connection.',
          );
        default:
          print('❌ Auth Error: ${e.code} - ${e.message}');
          throw FirebaseAuthException(
            code: e.code,
            message: e.message ?? 'An unknown error occurred during sign in.',
          );
      }
    } catch (e) {
      print('❌ Unexpected error during sign in: $e');
      throw Exception('Failed to sign in: $e');
    }
  }

  /// ✅ FIXED: Added comprehensive error handling for sign up
  static Future<UserCredential?> signUp(String email, String password, String name) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'All fields are required',
        );
      }

      // Password strength validation
      if (password.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password must be at least 6 characters long',
        );
      }

      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Failed to create user account',
        );
      }

      // Send email verification (optional but recommended) [^3^]
      await credential.user!.sendEmailVerification();

      // Create user document in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'id': credential.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'role': 'user',
        'createdAt': Timestamp.now(),
        'lastActive': Timestamp.now(),
        'isOnline': true,
        'emailVerified': false,
      });

      // Update display name in Firebase Auth
      await credential.user!.updateDisplayName(name.trim());

      return credential;

    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors [^5^][^9^]
      switch (e.code) {
        case 'email-already-in-use':
          print('❌ Email already registered.');
          throw FirebaseAuthException(
            code: e.code,
            message: 'An account already exists with this email. Please login instead.',
          );
        case 'invalid-email':
          print('❌ Invalid email format.');
          throw FirebaseAuthException(
            code: e.code,
            message: 'Please enter a valid email address.',
          );
        case 'weak-password':
          print('❌ Password too weak.');
          throw FirebaseAuthException(
            code: e.code,
            message: 'Password is too weak. Use at least 6 characters with mixed case.',
          );
        case 'operation-not-allowed':
          print('❌ Email/password auth not enabled.');
          throw FirebaseAuthException(
            code: e.code,
            message: 'Email/password authentication is not enabled. Please enable it in Firebase Console.',
          );
        case 'network-request-failed':
          print('❌ Network error.');
          throw FirebaseAuthException(
            code: e.code,
            message: 'Network error. Please check your internet connection.',
          );
        default:
          print('❌ Auth Error: ${e.code} - ${e.message}');
          throw FirebaseAuthException(
            code: e.code,
            message: e.message ?? 'An unknown error occurred during registration.',
          );
      }
    } catch (e) {
      print('❌ Unexpected error during sign up: $e');

      // If user was created but Firestore failed, clean up by deleting the auth user
      try {
        final user = _auth.currentUser;
        if (user != null) {
          await user.delete();
        }
      } catch (cleanupError) {
        print('⚠️ Failed to cleanup auth user after Firestore error: $cleanupError');
      }

      throw Exception('Failed to create account: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      // Update online status before signing out
      final userId = currentUserId;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'isOnline': false,
          'lastActive': Timestamp.now(),
        });
      }

      await _auth.signOut();
    } catch (e) {
      print('❌ Error during sign out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // ==================== USER MANAGEMENT ====================

  static Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await users.doc(userId).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    } catch (e) {
      print('❌ Error fetching user: $e');
      return null;
    }
  }

  static Future<UserModel> getUserData(String userId) async {
    try {
      final doc = await users.doc(userId).get();
      if (!doc.exists) {
        throw Exception('User not found');
      }
      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('❌ Error fetching user data: $e');
      throw Exception('Failed to load user data: $e');
    }
  }

  static Future<void> updateUser(UserModel user) async {
    try {
      await users.doc(user.id).update(user.toMap());
    } catch (e) {
      print('❌ Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  static Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await users.doc(userId).update(data);
    } catch (e) {
      print('❌ Error updating user data: $e');
      throw Exception('Failed to update user data: $e');
    }
  }

  /// ✅ FIXED: Added transaction support for atomic follow operation
  static Future<void> followUser(String userId, String targetUserId) async {
    if (userId == targetUserId) {
      throw Exception('Cannot follow yourself');
    }

    try {
      // Use batch write for atomic operation
      final batch = _firestore.batch();

      final currentUserRef = users.doc(userId);
      final targetUserRef = users.doc(targetUserId);

      // Check if already following
      final currentUserDoc = await currentUserRef.get();

      // ✅ CRITICAL FIX: Properly cast the data to Map<String, dynamic>
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>?;

      // ✅ FIXED: Safe access to the 'following' field with proper null handling
      final following = List<String>.from(currentUserData?['following'] ?? []);

      if (following.contains(targetUserId)) {
        // Unfollow logic
        batch.update(currentUserRef, {
          'following': FieldValue.arrayRemove([targetUserId]),
        });
        batch.update(targetUserRef, {
          'followers': FieldValue.arrayRemove([userId]),
        });
      } else {
        // Follow logic
        batch.update(currentUserRef, {
          'following': FieldValue.arrayUnion([targetUserId]),
        });
        batch.update(targetUserRef, {
          'followers': FieldValue.arrayUnion([userId]),
        });
      }

      await batch.commit();

    } catch (e, stackTrace) {
      print('❌ Error following user: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to follow user: $e');
    }
  }

  // ==================== NEARBY USERS ====================
  static Stream<List<UserModel>> getNearbyUsers(double lat, double lng, double radiusInKm) {
    return users
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where((user) {
      if (user.latitude == null || user.longitude == null) return false;
      final distance = _calculateDistance(lat, lng, user.latitude!, user.longitude!);
      return distance <= radiusInKm;
    }).toList());
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degree) => degree * (pi / 180);


  // ==================== OPTIMIZED NEARBY QUERIES ====================

  static Future<PaginatedUsers> getNearbyUsersPaginated({
    required double lat,
    required double lng,
    required double radiusInKm,
    required int limit,
    dynamic lastDocument,
    UserFilters? filters,
  }) async {
    // Use geohash for efficient querying (implement geoflutterfire or similar)
    // This is a simplified version - consider using geoflutterfire package

    Query query = users
        .where('isOnline', isEqualTo: true)
        .orderBy('lastActive', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    List<UserModel> filteredUsers = [];

    for (var doc in snapshot.docs) {
      final user = UserModel.fromFirestore(doc);

      // Server-side distance calculation would be better with geohash
      if (user.latitude != null && user.longitude != null) {
        final distance = _calculateDistance(lat, lng, user.latitude!, user.longitude!);

        if (distance <= radiusInKm) {
          // Apply additional filters
          if (filters != null) {
            if (user.age != null &&
                (user.age! < filters.minAge || user.age! > filters.maxAge)) {
              continue;
            }
            if (filters.interests != null &&
                !user.interests.any((i) => filters.interests!.contains(i))) {
              continue;
            }
          }

          // Add distance to user object
          user.distance = distance;
          filteredUsers.add(user);
        }
      }
    }

    return PaginatedUsers(
      users: filteredUsers,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  static Future<bool> likeUser({
    required String targetUserId,
    required String currentUserId,
    required bool isSuperLike,
  }) async {
    final batch = _firestore.batch();

    // Add to liked users
    batch.update(users.doc(currentUserId), {
      'likedUsers': FieldValue.arrayUnion([targetUserId]),
      isSuperLike ? 'superLikesSent' : 'likesSent': FieldValue.increment(1),
    });

    // Check if target user already liked current user (match)
    final targetUserDoc = await users.doc(targetUserId).get();
    final targetData = targetUserDoc.data() as Map<String, dynamic>?;
    final likedUsers = List<String>.from(targetData?['likedUsers'] ?? []);

    final isMatch = likedUsers.contains(currentUserId);

    if (isMatch) {
      // Create match
      final matchId = _uuid.v4();
      final matchRef = _firestore.collection('matches').doc(matchId);

      batch.set(matchRef, {
        'id': matchId,
        'users': [currentUserId, targetUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'superLikeInitiator': isSuperLike ? currentUserId : null,
      });

      // Update both users' matches
      batch.update(users.doc(currentUserId), {
        'matches': FieldValue.arrayUnion([targetUserId]),
      });
      batch.update(users.doc(targetUserId), {
        'matches': FieldValue.arrayUnion([currentUserId]),
      });
    }

    await batch.commit();
    return isMatch;
  }


  // ==================== FILE UPLOAD ====================
  // Add to FirebaseService class

  /// Upload file with progress tracking
  static Future<String?> uploadFile(
      dynamic file,
      String folder, {
        Function(double)? onProgress,
      }) async {
    try {
      print('☁️ Starting upload to folder: $folder');

      String filePath;
      if (file is File) {
        filePath = file.path;
      } else if (file is String) {
        filePath = file;
      } else {
        throw ArgumentError('File must be File or String path');
      }

      print('📁 File path: $filePath');

      // Check if file exists
      final fileObj = File(filePath);
      if (!await fileObj.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      print('📊 File size: ${await fileObj.length()} bytes');

      final fileName = '${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}';
      final extension = filePath.split('.').last;
      final ref = _storage.ref().child('$folder/$fileName.$extension');

      print('☁️ Storage reference: ${ref.fullPath}');

      final uploadTask = ref.putFile(
        fileObj,
        SettableMetadata(
          contentType: _getContentType(extension),
        ),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Upload complete: $downloadUrl');
      return downloadUrl;

    } catch (e, stackTrace) {
      print('❌ Upload error: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Create reel in Firestore
  // static Future<void> createReel(Reel reel) async {
  //   try {
  //     await reels.doc(reel.id).set(reel.toMap());
  //   } catch (e) {
  //     print('❌ Error creating reel: $e');
  //     throw Exception('Failed to create reel: $e');
  //   }
  // }
  // ==================== FRIENDS ====================
  static Stream<List<UserModel>> getFriends() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return users.doc(currentUserId).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists) return [];
      final userData = userDoc.data() as Map<String, dynamic>;
      final friendIds = List<String>.from(userData['friends'] ?? []);
      if (friendIds.isEmpty) return [];

      final friendDocs = await Future.wait(
        friendIds.map((id) => users.doc(id).get()),
      );

      return friendDocs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    });
  }

  static Stream<List<Map<String, dynamic>>> getFriendsWithChatInfo() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('❌ getFriendsWithChatInfo: no logged in user');
      return Stream.value([]);
    }

    return users.doc(currentUserId).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists) {
        print('❌ getFriendsWithChatInfo: user doc does not exist for $currentUserId');
        return <Map<String, dynamic>>[];
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final friendIds = List<String>.from(userData['friends'] ?? []);

      print('👥 Friend IDs found: $friendIds');

      if (friendIds.isEmpty) {
        print('ℹ️ No friends in friends array');
        return <Map<String, dynamic>>[];
      }

      final List<Map<String, dynamic>> friendsWithInfo = [];

      for (final friendId in friendIds) {
        try {
          final friendDoc = await users.doc(friendId).get();
          if (!friendDoc.exists) {
            print('⚠️ Friend doc not found for $friendId');
            continue;
          }

          final friend = UserModel.fromFirestore(friendDoc);
          final chatId = await _getChatIdForFriend(friendId);
          final chatInfo = await _getChatInfo(chatId, currentUserId);

          friendsWithInfo.add({
            'user': friend,
            'chatId': chatId,
            'lastMessage': chatInfo['lastMessage'],
            'lastMessageTime': chatInfo['lastMessageTime'],
            'unreadCount': chatInfo['unreadCount'] ?? 0,
          });
        } catch (e) {
          print('❌ Error loading friend $friendId: $e');
        }
      }

      friendsWithInfo.sort((a, b) {
        final timeA = a['lastMessageTime'] as DateTime?;
        final timeB = b['lastMessageTime'] as DateTime?;
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA);
      });

      print('✅ Returning ${friendsWithInfo.length} friends with chat info');
      return friendsWithInfo;
    });
  }

  static Future<String> _getChatIdForFriend(String friendId) async {
    final currentUserId = _auth.currentUser!.uid;
    final chatQuery = await chats
        .where('participants', arrayContains: currentUserId)
        .where('isGroup', isEqualTo: false)
        .get();

    for (var doc in chatQuery.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.contains(friendId) && participants.length == 2) {
        return doc.id;
      }
    }

    final newChat = await chats.add({
      'participants': [currentUserId, friendId],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageTime': null,
      'isGroup': false,
      'unreadCount': {currentUserId: 0, friendId: 0},
    });

    return newChat.id;
  }

  static Future<Map<String, dynamic>> _getChatInfo(String chatId, String currentUserId) async {
    final chatDoc = await chats.doc(chatId).get();
    if (!chatDoc.exists) {
      return {'unreadCount': 0};
    }

    final data = chatDoc.data() as Map<String, dynamic>;
    final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[currentUserId] ?? 0;

    return {
      'lastMessage': data['lastMessage'],
      'lastMessageTime': data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      'unreadCount': unreadCount,
    };
  }

  static Future<void> sendFriendRequest(String targetUserId) async {
    final currentUserId = _auth.currentUser!.uid;
    await users.doc(targetUserId).update({
      'friendRequestsReceived': FieldValue.arrayUnion([currentUserId]),
    });
    await users.doc(currentUserId).update({
      'friendRequestsSent': FieldValue.arrayUnion([targetUserId]),
    });
  }

  // static Future<void> acceptFriendRequest(String requesterId) async {
  //   final currentUserId = _auth.currentUser!.uid;
  //   final batch = _firestore.batch();
  //
  //   batch.update(users.doc(currentUserId), {
  //     'friends': FieldValue.arrayUnion([requesterId]),
  //     'friendRequestsReceived': FieldValue.arrayRemove([requesterId]),
  //   });
  //
  //   batch.update(users.doc(requesterId), {
  //     'friends': FieldValue.arrayUnion([currentUserId]),
  //     'friendRequestsSent': FieldValue.arrayRemove([currentUserId]),
  //   });
  //
  //   await batch.commit();
  // }

  // ==================== POSTS ====================
  static Future<List<Post>> getTimelinePosts() async {
    final snapshot = await posts
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
  }

  static Stream<List<Post>> getTimelinePostsStream() {
    return posts
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      print('📄 Firestore snapshot: ${snapshot.docs.length} posts');
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  static Future<void> createPost(Post post) async {
    await posts.doc(post.id).set(post.toMap());
  }

  static Future<void> updatePost(Post post) async {
    await posts.doc(post.id).update(post.toMap());
  }

  static Future<void> deletePost(String postId) async {
    await posts.doc(postId).delete();
  }

  static Future<void> likePost(String postId, String userId) async {
    await posts.doc(postId).update({
      'likedBy': FieldValue.arrayUnion([userId]),
      'likesCount': FieldValue.increment(1),
    });
  }

  static Future<void> unlikePost(String postId, String userId) async {
    await posts.doc(postId).update({
      'likedBy': FieldValue.arrayRemove([userId]),
      'likesCount': FieldValue.increment(-1),
    });
  }

  static Future<void> addComment(String postId, Comment comment) async {
    await posts.doc(postId).collection('comments').add(comment.toMap());
  }

  // ==================== REELS ====================
  // ==================== REELS ====================

  /// Get reels stream - FIXED with error handling
  static Stream<List<Reel>> getReels() {
    print('📡 Setting up reels stream...');
    return reels
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
      print('❌ Error in reels stream: $error');
      // Return empty list on error so UI doesn't crash
      return <Reel>[];
    })
        .map((snapshot) {
      print('📥 Firestore snapshot: ${snapshot.docs.length} reels');
      return snapshot.docs.map((doc) {
        try {
          return Reel.fromFirestore(doc);
        } catch (e) {
          print('❌ Error parsing reel ${doc.id}: $e');
          return null;
        }
      }).where((reel) => reel != null).cast<Reel>().toList();
    });
  }

  /// Create reel - FIXED with validation and logging
  static Future<void> createReel(Reel reel) async {
    try {
      print('📝 Creating reel in Firestore...');
      print('📝 Reel ID: ${reel.id}');
      print('📝 User ID: ${reel.userId}');
      print('📝 Video URL: ${reel.videoUrl}');

      // Validate data before saving
      if (reel.videoUrl.isEmpty) {
        throw Exception('Video URL cannot be empty');
      }
      if (reel.userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      final data = reel.toMap();
      print('📝 Data to save: $data');

      await reels.doc(reel.id).set(data);
      print('✅ Reel created successfully: ${reel.id}');

    } catch (e, stackTrace) {
      print('❌ Error creating reel: $e');
      print('❌ Stack trace: $stackTrace');
      throw Exception('Failed to create reel: $e');
    }
  }

  static Future<void> updateReel(Reel reel) async {
    try {
      await reels.doc(reel.id).update(reel.toMap());
      print('✅ Reel updated: ${reel.id}');
    } catch (e) {
      print('❌ Error updating reel: $e');
      throw Exception('Failed to update reel: $e');
    }
  }

  static Future<void> likeReel(String reelId, String userId) async {
    try {
      await reels.doc(reelId).update({
        'likes': FieldValue.arrayUnion([userId]),
      });
      print('✅ Reel liked: $reelId by $userId');
    } catch (e) {
      print('❌ Error liking reel: $e');
      throw Exception('Failed to like reel: $e');
    }
  }

  static Future<void> viewReel(String reelId, String userId) async {
    try {
      await reels.doc(reelId).update({
        'views': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('❌ Error viewing reel: $e');
    }
  }

  // ==================== STORIES ====================
  static Stream<List<Story>> getActiveStories() {
    final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));
    return stories
        .where('timestamp', isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList());
  }

  static Future<void> createStory(Story story) async {
    final docRef = stories.doc();
    final storyWithId = Story(
      id: docRef.id,
      userId: story.userId,
      userName: story.userName,
      userProfilePic: story.userProfilePic,
      mediaUrl: story.mediaUrl,
      thumbnailUrl: story.thumbnailUrl,
      mediaType: story.mediaType,
      timestamp: story.timestamp,
      expiresAt: story.expiresAt,
      viewers: story.viewers,
      caption: story.caption,
      stickers: story.stickers,
      backgroundColor: story.backgroundColor,
      textOverlay: story.textOverlay,
      musicTrackId: story.musicTrackId,
      items: story.items,
    );
    await docRef.set(storyWithId.toMap());
  }

  static Future<void> markStoryViewed(String storyId, String itemId, String userId) async {
    await stories.doc(storyId).update({
      'viewers': FieldValue.arrayUnion([userId]),
    });

    try {
      final storyDoc = await stories.doc(storyId).get();
      if (storyDoc.exists) {
        final data = storyDoc.data() as Map<String, dynamic>?;
        if (data != null && data['items'] != null) {
          final items = List<Map<String, dynamic>>.from(data['items']);
          final itemIndex = items.indexWhere((item) => item['id'] == itemId);
          if (itemIndex != -1) {
            final viewers = List<String>.from(items[itemIndex]['viewers'] ?? []);
            if (!viewers.contains(userId)) {
              viewers.add(userId);
              items[itemIndex]['viewers'] = viewers;
              await stories.doc(storyId).update({'items': items});
            }
          }
        }
      }
    } catch (e) {
      print('Error marking item as viewed: $e');
    }
  }

  // ==================== CHAT ====================
  static Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return chats
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  static Stream<List<ChatMessage>> getMessages(String chatId) {
    return chats
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<ChatMessage>> getChatMessages(String chatId) => getMessages(chatId);

  static Future<void> sendMessage(String chatId, ChatMessage message) async {
    final batch = _firestore.batch();
    final messageRef = chats.doc(chatId).collection('messages').doc(message.id);
    final chatRef = chats.doc(chatId);

    batch.set(messageRef, message.toMap());
    batch.update(chatRef, {
      'lastMessage': message.content,
      'lastMessageTime': Timestamp.fromDate(message.timestamp),
    });

    await batch.commit();
  }

  static Future<String> getOrCreateChatId(String otherUserId) async {
    final currentUserId = _auth.currentUser!.uid;
    final chatQuery = await chats
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in chatQuery.docs) {
      List participants = doc['participants'];
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    final newChat = await chats.add({
      'participants': [currentUserId, otherUserId],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'unreadCount': 0,
    });

    return newChat.id;
  }

  static Future<String> createChat(List<String> participants) async {
    final chatId = _uuid.v4();
    await chats.doc(chatId).set({
      'id': chatId,
      'participants': participants,
      'createdAt': Timestamp.now(),
      'isGroup': participants.length > 2,
    });
    return chatId;
  }

  static Future<void> markMessagesAsRead(String chatId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await chats.doc(chatId).update({
      'unreadCount.$currentUserId': 0,
    });
  }

  // ==================== LIVE STREAMING ====================
  static Future<void> startLiveStream(LiveStream stream) async {
    await liveStreams.doc(stream.id).set(stream.toMap());
  }

  static Stream<List<LiveStream>> getActiveLiveStreams() {
    return liveStreams
        .where('isLive', isEqualTo: true)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => LiveStream.fromFirestore(doc))
        .toList());
  }

  static Stream<List<LiveStream>> getTrendingLiveStreams() {
    return liveStreams
        .where('isLive', isEqualTo: true)
        .orderBy('viewerCount', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => LiveStream.fromFirestore(doc))
        .toList());
  }

  static Stream<List<LiveStream>> getUserStreams(String userId) {
    return liveStreams
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => LiveStream.fromFirestore(doc))
        .toList());
  }

  static Stream<LiveStream?> getStreamUpdates(String streamId) {
    return liveStreams.doc(streamId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return LiveStream.fromFirestore(doc);
    });
  }

  static Future<void> joinLiveStream(String streamId, String userId) async {
    await liveStreams.doc(streamId).update({
      'viewers': FieldValue.arrayUnion([userId]),
      'viewerCount': FieldValue.increment(1),
    });
  }

  static Future<void> leaveLiveStream(String streamId, String userId) async {
    await liveStreams.doc(streamId).update({
      'viewers': FieldValue.arrayRemove([userId]),
      'viewerCount': FieldValue.increment(-1),
    });
  }

  static Future<void> addLiveComment(String streamId, LiveComment comment) async {
    await liveStreams.doc(streamId).update({
      'comments': FieldValue.arrayUnion([comment.toMap()]),
    });
  }

  static Future<String> generateStreamKey(String userId) async {
    return '${userId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<void> updateStreamSettings(String streamId, Map<String, dynamic> settings) async {
    await liveStreams.doc(streamId).update(settings);
  }

  static Future<void> deleteComment(String streamId, LiveComment comment) async {
    final doc = await liveStreams.doc(streamId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final comments = (data['comments'] as List)
        .where((c) => c['timestamp'] != Timestamp.fromDate(comment.timestamp))
        .toList();

    await liveStreams.doc(streamId).update({'comments': comments});
  }

  static Future<void> banUserFromStream(String streamId, String userId) async {
    await liveStreams.doc(streamId).update({
      'bannedUsers': FieldValue.arrayUnion([userId]),
    });
  }

  static Future<void> kickUserFromStream(String streamId, String userId) async {
    await liveStreams.doc(streamId).update({
      'viewers': FieldValue.arrayRemove([userId]),
      'viewerCount': FieldValue.increment(-1),
    });
  }

  static Future<void> addToWatchHistory(String userId, String streamId) async {
    await users.doc(userId).collection('watch_history').add({
      'streamId': streamId,
      'watchedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> sendStreamInvite(String userId, String streamId, String streamTitle) async {
    await users.doc(userId).collection('notifications').add({
      'type': 'stream_invite',
      'streamId': streamId,
      'streamTitle': streamTitle,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ==================== END STREAM WITH RECORDING (MERGED) ====================

  /// Main method: End stream + upload recording + create post (with compression)
  static Future<void> endLiveStreamWithRecording({
    required String streamId,
    required String localVideoPath,
    String? title,
    String? description,
    Function(double)? onUploadProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    try {
      // Validate video file
      final videoFile = File(localVideoPath);
      if (!await videoFile.exists()) {
        throw Exception('Video file not found at: $localVideoPath');
      }

      print('📹 Processing video: ${videoFile.lengthSync()} bytes');

      // 1. Compress video before upload (optional but recommended)
      String uploadPath = localVideoPath;
      try {
        final info = await VideoCompress.compressVideo(
          localVideoPath,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );
        if (info?.file != null) {
          uploadPath = info!.file!.path;
          print('✅ Video compressed: ${info.file!.lengthSync()} bytes');
        }
      } catch (e) {
        print('⚠️ Compression failed, using original: $e');
      }

      // 2. Upload to Firebase Storage with progress
      final videoUrl = await _uploadVideoToStorage(
        uploadPath,
        streamId,
        onProgress: onUploadProgress,
      );

      if (videoUrl == null) throw Exception('Video upload failed');

      // 3. Update stream document
      await liveStreams.doc(streamId).update({
        'isLive': false,
        'status': 'ended',
        'endTime': FieldValue.serverTimestamp(),
        'playbackUrl': videoUrl,
        'recordingUrl': videoUrl,
        'recordingStatus': 'uploaded',
      });

      // 4. Create post from stream
      await _createPostFromLiveStream(streamId, videoUrl);

      // 5. Cleanup temp files
      await _cleanupTempFiles(localVideoPath, uploadPath);

      print('✅ Stream ended and post created successfully');

    } catch (e) {
      print('🔴 Error in endLiveStreamWithRecording: $e');
      // Update stream as ended even if post creation fails
      await liveStreams.doc(streamId).update({
        'isLive': false,
        'status': 'ended',
        'endTime': FieldValue.serverTimestamp(),
      });
      rethrow;
    }
  }

  /// Legacy method: End stream without recording or with existing URL
  static Future<void> endLiveStream(String streamId, {String? playbackUrl}) async {
    final updates = {
      'isLive': false,
      'status': 'ended',
      'endTime': FieldValue.serverTimestamp(),
    };

    if (playbackUrl != null) {
      updates['playbackUrl'] = playbackUrl;
    }

    await liveStreams.doc(streamId).update(updates);

    if (playbackUrl != null) {
      await _createPostFromLiveStream(streamId, playbackUrl);
    }
  }

  /// Upload video to Firebase Storage
  static Future<String?> _uploadVideoToStorage(
      String videoPath,
      String streamId, {
        Function(double)? onProgress,
      }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final file = File(videoPath);
      final fileName = 'live_${streamId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ref = _storage.ref().child('live_replays/${user.uid}/$fileName');

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'video/mp4',
          customMetadata: {
            'streamId': streamId,
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Video uploaded: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      print('🔴 Upload error: $e');
      return null;
    }
  }

  /// Create post from live stream data
  static Future<void> _createPostFromLiveStream(String streamId, String playbackUrl) async {
    try {
      if (playbackUrl.contains('example.com')) {
        print('⚠️ No valid playback URL, skipping post creation');
        return;
      }

      final streamDoc = await liveStreams.doc(streamId).get();
      if (!streamDoc.exists) {
        print('⚠️ Stream document not found');
        return;
      }

      final streamData = streamDoc.data() as Map<String, dynamic>;
      final userId = streamData['userId'] as String?;

      if (userId == null) {
        print('⚠️ User ID not found in stream data');
        return;
      }

      final userDoc = await users.doc(userId).get();
      if (!userDoc.exists) {
        print('⚠️ User document not found');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Calculate stream duration
      String? durationStr;
      if (streamData['startTime'] != null) {
        final startTime = (streamData['startTime'] as Timestamp).toDate();
        final duration = DateTime.now().difference(startTime);
        final hours = duration.inHours;
        final mins = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
        final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
        durationStr = hours > 0 ? '$hours:$mins:$secs' : '$mins:$secs';
      }

      // Create post
      final postId = _uuid.v4();
      final post = Post(
        id: postId,
        userId: userId,
        userName: userData['name'] ?? 'Unknown',
        userProfilePic: userData['profilePic'],
        content: '📺 Was LIVE: ${streamData['title'] ?? 'Untitled Stream'}\n\n'
            '${streamData['description'] ?? ''}',
        mediaUrl: playbackUrl,
        mediaType: 'video',
        platform: 'app',
        likes: [],
        commentsCount: 0,
        timestamp: DateTime.now(),
        privacy: streamData['isPrivate'] == true ? 'only_me' : 'public',
        tags: streamData['category'] != null ? [streamData['category']] : [],
        location: null,
        isLiked: false,
        isLiveReplay: true,
        originalStreamId: streamId,
        streamStartTime: streamData['startTime'] != null
            ? (streamData['startTime'] as Timestamp).toDate()
            : null,
        viewCount: streamData['viewerCount'] ?? 0,
        streamDuration: durationStr,
      );

      await posts.doc(postId).set(post.toMap());

      // Update stream with post reference
      await liveStreams.doc(streamId).update({
        'postId': postId,
      });

      print('✅ Post created from live stream: $postId');

    } catch (e) {
      print('🔴 Error creating post from live stream: $e');
    }
  }

  /// Cleanup temporary files
  static Future<void> _cleanupTempFiles(String originalPath, String compressedPath) async {
    try {
      final originalFile = File(originalPath);
      if (await originalFile.exists() && originalPath != compressedPath) {
        await originalFile.delete();
        print('🗑️ Deleted original file');
      }

      if (compressedPath != originalPath) {
        final compressedFile = File(compressedPath);
        if (await compressedFile.exists()) {
          await compressedFile.delete();
          print('🗑️ Deleted compressed file');
        }
      }
    } catch (e) {
      print('⚠️ Error cleaning up files: $e');
    }
  }

  /// Alternative: Upload recorded video and create post (legacy support)
  static Future<String?> uploadRecordedVideo(
      String videoPath, {
        required String title,
        String? description,
        String? thumbnailPath,
      }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Upload video
      final videoFileName = '${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final videoRef = _storage.ref().child('live_videos/${user.uid}/$videoFileName');

      final videoUploadTask = videoRef.putFile(
        File(videoPath),
        SettableMetadata(contentType: 'video/mp4'),
      );

      videoUploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('📤 Video upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      final videoSnapshot = await videoUploadTask;
      final videoUrl = await videoSnapshot.ref.getDownloadURL();
      print('✅ Video uploaded: $videoUrl');

      // Upload thumbnail if provided
      String? thumbnailUrl;
      if (thumbnailPath != null && File(thumbnailPath).existsSync()) {
        final thumbFileName = '${_uuid.v4()}_thumb.jpg';
        final thumbRef = _storage.ref().child('live_thumbnails/${user.uid}/$thumbFileName');
        await thumbRef.putFile(File(thumbnailPath));
        thumbnailUrl = await thumbRef.getDownloadURL();
      }

      // Create post
      final userData = await getUser(user.uid);
      final postId = _uuid.v4();

      final post = Post(
        id: postId,
        userId: user.uid,
        userName: userData?.name ?? 'Unknown',
        userProfilePic: userData?.profilePic,
        content: '📺 Was LIVE: $title\n\n${description ?? ''}',
        mediaUrl: videoUrl,
        mediaType: 'video',
        platform: 'app',
        likes: [],
        commentsCount: 0,
        timestamp: DateTime.now(),
        privacy: 'public',
        tags: [],
        location: null,
        isLiked: false,
        isLiveReplay: true,
        originalStreamId: null,
        streamStartTime: DateTime.now(),
        viewCount: 0,
        streamDuration: null,
      );

      await posts.doc(postId).set(post.toMap());
      print('✅ Post created from recording: $postId');

      return videoUrl;
    } catch (e) {
      print('🔴 Error uploading recorded video: $e');
      return null;
    }
  }

  static Future<void> saveLocalRecordingAndUpload({
    required String videoPath,
    required String streamId,
    required String title,
  }) async {
    try {
      final videoUrl = await uploadRecordedVideo(
        videoPath,
        title: title,
      );

      if (videoUrl != null) {
        await liveStreams.doc(streamId).update({
          'playbackUrl': videoUrl,
          'recordingStatus': 'uploaded',
          'recordingUrl': videoUrl,
        });
      }
    } catch (e) {
      print('🔴 Error saving local recording: $e');
    }
  }

  static Future<String?> generatePlaybackUrl(String streamId) async {
    final doc = await liveStreams.doc(streamId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return data['recordingUrl'] ?? data['playbackUrl'];
  }

  // ==================== NOTIFICATIONS ====================
  static Future<void> setupNotifications() async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    if (token != null) {
      await saveFCMToken(token);
    }
  }

  static Future<void> saveFCMToken(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await users.doc(userId).update({
        'fcmToken': token,
      });
    }
  }

  static Future<void> sendNotification(String userId, String title, String body) async {
    // Call Cloud Function to send FCM notification
  }

  // ==================== SEARCH ====================
  static Future<List<UserModel>> searchUsers(String query) async {
    final snapshot = await users
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  static Future<List<Post>> searchPosts(String query) async {
    final snapshot = await posts
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
  }

  // ==================== AI SERVICE ====================
  static Future<void> saveAIPost(String mediaUrl, String caption) async {
    await _firestore.collection('aiGenerated').add({
      'mediaUrl': mediaUrl,
      'caption': caption,
      'timestamp': Timestamp.now(),
    });
  }

  // ── Add these two methods inside FirebaseService ──────────────────────────────

  /// Get all users except the current user
  static Future<List<UserModel>> getAllUsers(String excludeUserId) async {
    try {
      final snapshot = await users
          .orderBy('name')
          .limit(100)
          .get();

      final result = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((u) => u.id != excludeUserId) // filter client-side
          .toList();

      print('✅ getAllUsers: ${result.length} users loaded');
      return result;
    } catch (e) {
      print('❌ getAllUsers error: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  /// Get multiple users by their IDs (for pending requests list)
  static Future<List<UserModel>> getUsersByIds(
      List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      // Firestore whereIn max = 10, so chunk
      final chunks = <List<String>>[];
      for (var i = 0; i < ids.length; i += 10) {
        chunks.add(
          ids.sublist(i, (i + 10).clamp(0, ids.length)),
        );
      }

      final List<UserModel> result = [];

      for (final chunk in chunks) {
        print('🔍 getUsersByIds chunk: $chunk');
        final snapshot = await users
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        print('📄 getUsersByIds got ${snapshot.docs.length} docs');

        result.addAll(
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)),
        );
      }

      print('✅ getUsersByIds total: ${result.length}');
      return result;
    } catch (e) {
      print('❌ getUsersByIds error: $e');
      return [];
    }
  }

  /// Decline a received friend request
  /// Decline a received friend request (removes from both users)
  static Future<void> declineFriendRequest(String requesterId) async {
    final currentUserId = _auth.currentUser!.uid;
    final batch = _firestore.batch();

    // Remove from current user's received list
    batch.update(users.doc(currentUserId), {
      'friendRequestsReceived': FieldValue.arrayRemove([requesterId]),
    });

    // Remove from requester's sent list
    batch.update(users.doc(requesterId), {
      'friendRequestsSent': FieldValue.arrayRemove([currentUserId]),
    });

    await batch.commit();
    print('✅ Declined request from $requesterId');
  }

  /// Cancel a sent friend request
  static Future<void> cancelFriendRequest(String targetUserId) async {
    final currentUserId = _auth.currentUser!.uid;
    final batch = _firestore.batch();

    // Remove from current user's sent list
    batch.update(users.doc(currentUserId), {
      'friendRequestsSent': FieldValue.arrayRemove([targetUserId]),
    });

    // Remove from target's received list
    batch.update(users.doc(targetUserId), {
      'friendRequestsReceived': FieldValue.arrayRemove([currentUserId]),
    });

    await batch.commit();
    print('✅ Cancelled request to $targetUserId');
  }

  /// Accept a friend request (adds to friends, removes from requests)
  static Future<void> acceptFriendRequest(String requesterId) async {
    final currentUserId = _auth.currentUser!.uid;
    final batch = _firestore.batch();

    // Add to both users' friends lists
    batch.update(users.doc(currentUserId), {
      'friends': FieldValue.arrayUnion([requesterId]),
      'friendRequestsReceived': FieldValue.arrayRemove([requesterId]),
    });

    batch.update(users.doc(requesterId), {
      'friends': FieldValue.arrayUnion([currentUserId]),
      'friendRequestsSent': FieldValue.arrayRemove([currentUserId]),
    });

    await batch.commit();
    print('✅ Accepted request from $requesterId');
  }
}