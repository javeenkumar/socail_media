import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../screens/nearby_screen.dart';
import '../screens/nearby_screen.dart';
import '../screens/user_detail_screen.dart';
import '../services/firebase_service.dart';

class NearbyController extends GetxController {
  // State management
  final nearbyUsers = <UserModel>[].obs;
  final currentPosition = Rxn<Position>();
  final status = RxStatus.empty().obs;

  // Pagination
  final _lastDocument = Rxn<dynamic>();
  final _hasMoreUsers = true.obs;
  static const _pageSize = 20;

  // Filters
  final radius = 5.0.obs;
  final maxDistance = 50.0.obs;
  final minAge = 18.obs;
  final maxAge = 50.obs;
  final selectedInterests = <String>[].obs;

  // Animation state
  final currentCardIndex = 0.obs;
  final swipeDirection = Rxn<SwipeDirection>();
  final isAnimating = false.obs;

  // Undo functionality
  final _removedUsers = <UserModel>[].obs;

  // Debounce timer for radius changes
  Timer? _radiusDebounce;

  @override
  void onInit() {
    super.onInit();
    _initializeLocation();
  }

  @override
  void onClose() {
    _radiusDebounce?.cancel();
    super.onClose();
  }

  Future<void> _initializeLocation() async {
    status.value = RxStatus.loading();
    try {
      await getCurrentLocation();
    } on LocationException catch (e) {
      // ✅ Show friendly message, not raw exception object
      status.value = RxStatus.error(e.message);
    } catch (e) {
      status.value = RxStatus.error('Could not get location. Please try again.');
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // ✅ Show dialog to open GPS settings
        _showLocationServiceDialog();
        throw LocationException('Location services are disabled. Please enable GPS.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationException('Location permission denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        throw LocationException('Location permission permanently denied.');
      }

      currentPosition.value = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await fetchNearbyUsers(refresh: true);

    } on LocationException {
      rethrow; // ✅ Let _initializeLocation handle it cleanly
    } catch (e) {
      throw LocationException('Failed to get location: $e');
    }
  }

  void _showLocationServiceDialog() {
    // ✅ Guard: don't show dialog if already showing one
    if (Get.isDialogOpen ?? false) return;

    Get.dialog(
      AlertDialog(
        title: const Text('GPS is Off'),
        content: const Text('Please enable location services to find nearby users.'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              await Geolocator.openLocationSettings();
              await Future.delayed(const Duration(seconds: 2));
              _initializeLocation(); // retry after returning
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showPermissionDialog() {
    if (Get.isDialogOpen ?? false) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Location permission is permanently denied. Enable it in App Settings.'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              await Geolocator.openAppSettings();
            },
            child: const Text('App Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void updateRadius(double value) {
    radius.value = value;

    // Debounce to prevent excessive Firestore calls
    _radiusDebounce?.cancel();
    _radiusDebounce = Timer(Duration(milliseconds: 500), () {
      fetchNearbyUsers(refresh: true);
    });
  }

  Future<void> fetchNearbyUsers({bool refresh = false}) async {
    if (currentPosition.value == null) return;

    if (refresh) {
      _lastDocument.value = null;
      _hasMoreUsers.value = true;
      nearbyUsers.clear();
    }

    if (!_hasMoreUsers.value) return;

    status.value = RxStatus.loading();

    try {
      final result = await FirebaseService.getNearbyUsersPaginated(
        lat: currentPosition.value!.latitude,
        lng: currentPosition.value!.longitude,
        radiusInKm: radius.value,
        lastDocument: _lastDocument.value,
        limit: _pageSize,
        filters: UserFilters(
          minAge: minAge.value,
          maxAge: maxAge.value,
          interests: selectedInterests.isEmpty ? null : selectedInterests.toList(),
        ),
      );

      final users = result.users;
      _lastDocument.value = result.lastDocument;
      _hasMoreUsers.value = users.length == _pageSize;

      if (refresh) {
        nearbyUsers.assignAll(users);
      } else {
        nearbyUsers.addAll(users);
      }

      status.value = nearbyUsers.isEmpty ? RxStatus.empty() : RxStatus.success();
    } catch (e) {
      status.value = RxStatus.error('Failed to load users');
      Get.snackbar('Error', 'Failed to fetch nearby users');
    }
  }

  void onCardChanged(int index) {
    currentCardIndex.value = index;
    // Prefetch next page when approaching end
    if (index >= nearbyUsers.length - 5 && _hasMoreUsers.value) {
      fetchNearbyUsers();
    }
  }

  Future<void> likeUser() async {
    if (_isInvalidState()) return;

    isAnimating.value = true;
    swipeDirection.value = SwipeDirection.right;

    final user = nearbyUsers[currentCardIndex.value];
    final currentUserId = FirebaseService.currentUserId;

    if (currentUserId != null) {
      try {
        final isMatch = await FirebaseService.likeUser(
          targetUserId: user.id,
          currentUserId: currentUserId,
          isSuperLike: false,
        );

        if (isMatch) {
          Get.dialog(MatchDialog(matchedUser: user));
        } else {
          Get.snackbar('Liked!', 'You liked ${user.name}',
              snackPosition: SnackPosition.BOTTOM);
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to like user');
      }
    }

    _removeCurrentUser();
    isAnimating.value = false;
  }

  Future<void> dislikeUser() async {
    if (_isInvalidState()) return;

    isAnimating.value = true;
    swipeDirection.value = SwipeDirection.left;

    final user = nearbyUsers[currentCardIndex.value];

    // Store for potential undo
    _removedUsers.add(user);

    _removeCurrentUser();
    isAnimating.value = false;

    // Show undo option
    Get.snackbar(
      'Passed',
      'You passed on ${user.name}',
      snackPosition: SnackPosition.BOTTOM,
      mainButton: TextButton(
        onPressed: undoLastAction,
        child: Text('UNDO', style: TextStyle(color: Colors.blue)),
      ),
      duration: Duration(seconds: 3),
    );
  }

  Future<void> superLikeUser() async {
    if (_isInvalidState()) return;

    isAnimating.value = true;
    swipeDirection.value = SwipeDirection.up;

    final user = nearbyUsers[currentCardIndex.value];
    final currentUserId = FirebaseService.currentUserId;

    if (currentUserId != null) {
      try {
        final isMatch = await FirebaseService.likeUser(
          targetUserId: user.id,
          currentUserId: currentUserId,
          isSuperLike: true,
        );

        if (isMatch) {
          Get.dialog(MatchDialog(matchedUser: user, isSuperLike: true));
        } else {
          Get.snackbar(
            'Super Liked! ⭐',
            'You super liked ${user.name}!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue.withOpacity(0.9),
            colorText: Colors.white,
          );
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to super like user');
      }
    }

    _removeCurrentUser();
    isAnimating.value = false;
  }

  void undoLastAction() {
    if (_removedUsers.isEmpty) return;

    final user = _removedUsers.removeLast();
    nearbyUsers.insert(currentCardIndex.value, user);

    Get.snackbar('Restored', '${user.name} is back!');
  }

  void _removeCurrentUser() {
    if (nearbyUsers.isEmpty) return;

    nearbyUsers.removeAt(currentCardIndex.value);

    // Adjust index if needed
    if (currentCardIndex.value >= nearbyUsers.length && nearbyUsers.isNotEmpty) {
      currentCardIndex.value = nearbyUsers.length - 1;
    }

    if (nearbyUsers.isEmpty) {
      status.value = RxStatus.empty();
    }
  }

  bool _isInvalidState() {
    return nearbyUsers.isEmpty ||
        currentCardIndex.value >= nearbyUsers.length ||
        isAnimating.value;
  }

  void applyFilters() {
    fetchNearbyUsers(refresh: true);
    Get.back();
    Get.snackbar(
      'Filters Applied',
      'Radius: ${radius.value.toInt()}km • Ages: ${minAge.value}-${maxAge.value}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onTapCard(UserModel user) {
    Get.to(() => UserDetailScreen(user: user));
  }
}

enum SwipeDirection { left, right, up }

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}

// Supporting models
class UserFilters {
  final int minAge;
  final int maxAge;
  final List<String>? interests;

  UserFilters({
    required this.minAge,
    required this.maxAge,
    this.interests,
  });
}

class PaginatedUsers {
  final List<UserModel> users;
  final dynamic lastDocument;

  PaginatedUsers({required this.users, this.lastDocument});
}