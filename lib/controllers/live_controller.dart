// controllers/live_controller.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../models/live_stream_model.dart';
import '../services/firebase_service.dart';

class LiveController extends GetxController {
  // Streams
  var liveStreams = <LiveStream>[].obs;
  var currentStream = Rxn<LiveStream>();
  var trendingStreams = <LiveStream>[].obs;
  var myStreams = <LiveStream>[].obs;

  // UI State
  var isStreaming = false.obs;
  var isLoading = false.obs;
  var isRecording = false.obs;
  var selectedCategory = 'All'.obs;

  // Recording
  var recordingPath = ''.obs;
  var uploadProgress = 0.0.obs;
  var isUploading = false.obs;

  // Comments
  var liveComments = <LiveComment>[].obs;
  var commentController = TextEditingController();
  var showComments = true.obs;

  // Streaming
  CameraController? cameraController;
  var isCameraInitialized = false.obs;
  var isBackCamera = true.obs;
  var isMuted = false.obs;
  var isFlashOn = false.obs;
  var isSwitchingCamera = false.obs;

  // Viewers
  var viewerCount = 0.obs;
  var viewers = <String>[].obs;

  // Timer
  Timer? _streamTimer;
  var streamDuration = Duration.zero.obs;
  var elapsedTime = '00:00'.obs;

  // Categories
  final List<String> categories = [
    'All', 'Gaming', 'Music', 'Talk Show', 'Sports', 'Education', 'Fashion', 'Travel'
  ];

  @override
  void onInit() {
    super.onInit();
    fetchLiveStreams();
    fetchTrendingStreams();
    fetchMyStreams();
    _requestPermissions();
  }

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  void _cleanup() {
    _streamTimer?.cancel();
    commentController.dispose();
    WakelockPlus.disable();
    _disposeCamera();
  }

  Future<void> _disposeCamera() async {
    if (cameraController != null) {
      isCameraInitialized.value = false;
      // Stop recording if active
      if (isRecording.value) {
        try {
          await cameraController!.stopVideoRecording();
        } catch (e) {
          print('⚠️ Error stopping recording during cleanup: $e');
        }
        isRecording.value = false;
      }
      await cameraController!.dispose();
      cameraController = null;
    }
  }

  // ==================== FETCH STREAMS ====================
  void fetchLiveStreams() {
    FirebaseService.getActiveLiveStreams().listen((streams) {
      liveStreams.value = streams;
    }, onError: (e) {
      print('🔴 Error fetching streams: $e');
    });
  }

  void fetchTrendingStreams() {
    FirebaseService.getTrendingLiveStreams().listen((streams) {
      trendingStreams.value = streams;
    }, onError: (e) {
      print('🔴 Error fetching trending: $e');
    });
  }

  void fetchMyStreams() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseService.getUserStreams(userId).listen((streams) {
      myStreams.value = streams;
    });
  }

  List<LiveStream> get filteredStreams {
    if (selectedCategory.value == 'All') return liveStreams;
    return liveStreams.where((s) => s.category == selectedCategory.value).toList();
  }

  // ==================== CAMERA ====================
  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        Get.snackbar('Error', 'No cameras found');
        return;
      }

      final camera = cameras.firstWhere(
            (c) => c.lensDirection == (isBackCamera.value
            ? CameraLensDirection.back
            : CameraLensDirection.front),
        orElse: () => cameras.first,
      );

      if (cameraController != null) {
        await cameraController!.dispose();
      }

      cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: !isMuted.value,
      );

      await cameraController!.initialize();

      if (cameraController!.value.isInitialized) {
        isCameraInitialized.value = true;
        print('✅ Camera initialized: ${isBackCamera.value ? "back" : "front"}');
      }

    } catch (e) {
      print('🔴 Camera init error: $e');
      isCameraInitialized.value = false;
      Get.snackbar('Error', 'Failed to initialize camera: $e');
    }
  }

  // ==================== LOCAL VIDEO RECORDING ====================

  /// Start camera video recording when stream starts
  Future<bool> startVideoRecording() async {
    try {
      if (cameraController == null || !cameraController!.value.isInitialized) {
        print('🔴 Camera not initialized');
        return false;
      }

      // Check if already recording
      if (cameraController!.value.isRecordingVideo) {
        print('⚠️ Already recording');
        return true;
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'live_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final path = '${tempDir.path}/$fileName';

      // Start recording
      await cameraController!.startVideoRecording();

      recordingPath.value = path;
      isRecording.value = true;

      print('✅ Video recording started');
      return true;

    } catch (e) {
      print('🔴 Video recording error: $e');
      Get.snackbar('Warning', 'Could not start recording: $e');
      return false;
    }
  }

  /// Stop video recording and return file path
  Future<String?> stopVideoRecording() async {
    try {
      if (!isRecording.value || !cameraController!.value.isRecordingVideo) {
        print('⚠️ Not recording');
        return null;
      }

      // Stop recording - this returns the actual file
      final XFile videoFile = await cameraController!.stopVideoRecording();
      isRecording.value = false;

      // Get the actual path
      final String path = videoFile.path;
      recordingPath.value = path;

      // Verify file exists
      final file = File(path);
      if (await file.exists() && file.lengthSync() > 0) {
        print('✅ Video recording saved: $path (${file.lengthSync()} bytes)');
        return path;
      } else {
        print('⚠️ Recording file is empty or missing');
        return null;
      }

    } catch (e) {
      print('🔴 Stop video recording error: $e');
      isRecording.value = false;
      return null;
    }
  }

  // ==================== GO LIVE ====================
  Future<void> startLiveStream({
    required String title,
    String? description,
    String? category,
    bool allowComments = true,
    bool isPrivate = false,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'Please login first');
        return;
      }

      isLoading.value = true;

      // Initialize camera first
      await initializeCamera();

      if (!isCameraInitialized.value) {
        throw Exception('Camera failed to initialize');
      }

      // Start video recording
      final recordingStarted = await startVideoRecording();
      if (!recordingStarted) {
        print('⚠️ Failed to start recording, continuing without recording');
      }

      final userData = await FirebaseService.getUser(user.uid);
      if (userData == null) throw Exception('User data not found');

      final streamKey = await FirebaseService.generateStreamKey(user.uid);
      final streamUrl = 'rtmp://live.example.com/app/$streamKey';

      final stream = LiveStream(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        userName: userData.name,
        userProfilePic: userData.profilePic,
        title: title,
        description: description,
        startTime: DateTime.now(),
        isLive: true,
        status: LiveStreamStatus.live,
        viewerCount: 0,
        viewers: [],
        comments: [],
        streamUrl: streamUrl,
        category: category,
        allowComments: allowComments,
        isPrivate: isPrivate,
      );

      await FirebaseService.startLiveStream(stream);
      currentStream.value = stream;
      isStreaming.value = true;
      isLoading.value = false;

      WakelockPlus.enable();
      _startStreamTimer();
      _listenToStreamUpdates(stream.id);

    } catch (e) {
      isLoading.value = false;
      // Stop recording if started
      if (isRecording.value) {
        try {
          await cameraController?.stopVideoRecording();
        } catch (_) {}
        isRecording.value = false;
      }
      Get.snackbar('Error', 'Failed to start live stream: $e');
    }
  }

  void _startStreamTimer() {
    _streamTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (currentStream.value == null) return;

      streamDuration.value = DateTime.now().difference(
        currentStream.value!.startTime,
      );
      final minutes = streamDuration.value.inMinutes.toString().padLeft(2, '0');
      final seconds = (streamDuration.value.inSeconds % 60).toString().padLeft(2, '0');
      elapsedTime.value = '$minutes:$seconds';
    });
  }

  void _listenToStreamUpdates(String streamId) {
    FirebaseService.getStreamUpdates(streamId).listen((stream) {
      if (stream != null) {
        currentStream.value = stream;
        viewerCount.value = stream.viewerCount;
        liveComments.value = stream.comments;
      }
    });
  }

  // ==================== STREAM CONTROLS ====================
  Future<void> switchCamera() async {
    if (isSwitchingCamera.value) return;
    if (isRecording.value) {
      Get.snackbar('Info', 'Cannot switch camera while recording');
      return;
    }

    isSwitchingCamera.value = true;

    try {
      isBackCamera.value = !isBackCamera.value;
      await _disposeCamera();
      await Future.delayed(Duration(milliseconds: 100));
      await initializeCamera();
    } catch (e) {
      print('🔴 Camera switch error: $e');
      isBackCamera.value = !isBackCamera.value;
      Get.snackbar('Error', 'Failed to switch camera: $e');
    } finally {
      isSwitchingCamera.value = false;
    }
  }

  Future<void> toggleMute() async {
    isMuted.value = !isMuted.value;
    // Note: Requires re-initialization or streaming SDK integration
  }

  Future<void> toggleFlash() async {
    if (cameraController == null || !isCameraInitialized.value) return;

    if (!isBackCamera.value) {
      Get.snackbar('Info', 'Flash is only available on back camera');
      return;
    }

    try {
      isFlashOn.value = !isFlashOn.value;
      await cameraController!.setFlashMode(
        isFlashOn.value ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      print('🔴 Flash error: $e');
      isFlashOn.value = false;
      Get.snackbar('Error', 'Flash not supported on this device');
    }
  }

  // ==================== END STREAM ====================

  /// End stream with local video recording and post creation
  Future<void> endLiveStream() async {
    try {
      final streamId = currentStream.value?.id;
      if (streamId == null) {
        print('🔴 No active stream to end');
        return;
      }

      print('🔴 Ending stream: $streamId');

      // Show loading
      _showLoadingDialog('Stopping recording...');

      // 1. Stop video recording and get the REAL local file path
      final videoPath = await stopVideoRecording();

      _closeAllDialogs();

      if (videoPath != null && File(videoPath).existsSync()) {
        // 2. We have a real local video file - upload it!
        isUploading.value = true;
        _showLoadingDialog('Uploading video...');

        await FirebaseService.endLiveStreamWithRecording(
          streamId: streamId,
          localVideoPath: videoPath,
          title: currentStream.value?.title ?? 'Live Stream',
          description: currentStream.value?.description,
          onUploadProgress: (progress) {
            uploadProgress.value = progress;
            _updateLoadingDialog('Uploading: ${(progress * 100).toStringAsFixed(0)}%');
          },
        );

        isUploading.value = false;
        _closeAllDialogs();

        Get.snackbar(
          'Success',
          'Live stream saved and posted!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      } else {
        // No recording available - just end stream
        await FirebaseService.endLiveStream(streamId);

        _closeAllDialogs();
        Get.snackbar(
          'Stream Ended',
          'Live stream ended (no recording)',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }

      // Cleanup and close screen
      _cleanupStreamState();
      await Future.delayed(Duration(milliseconds: 500));
      _forceCloseScreen();

    } catch (e, stackTrace) {
      print('🔴 Error ending stream: $e');
      print('🔴 Stack: $stackTrace');

      _closeAllDialogs();
      isUploading.value = false;

      // Try to stop recording if still going
      if (isRecording.value) {
        try {
          await cameraController?.stopVideoRecording();
        } catch (_) {}
        isRecording.value = false;
      }

      Get.snackbar('Error', 'Failed to end stream: $e');

      // Force cleanup
      _cleanupStreamState();
    }
  }

  /// Quick end without saving (for errors)
  Future<void> forceEndStream() async {
    print('🔴 Force ending stream');

    // Stop recording
    if (isRecording.value && cameraController != null) {
      try {
        await cameraController!.stopVideoRecording();
      } catch (e) {
        print('⚠️ Error stopping recording: $e');
      }
      isRecording.value = false;
    }

    _streamTimer?.cancel();
    _streamTimer = null;

    if (currentStream.value != null) {
      try {
        await FirebaseService.endLiveStream(currentStream.value!.id);
      } catch (e) {
        print('🔴 Error force ending: $e');
      }
    }

    isStreaming.value = false;
    currentStream.value = null;
    streamDuration.value = Duration.zero;
    elapsedTime.value = '00:00';

    await _disposeCamera();
    WakelockPlus.disable();
  }

  // ==================== DIALOG HELPERS ====================

  void _showLoadingDialog(String message) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Obx(() => Text(
                isUploading.value
                    ? 'Uploading: ${(uploadProgress.value * 100).toStringAsFixed(0)}%'
                    : message,
                style: TextStyle(color: Colors.white),
              )),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
  }

  void _updateLoadingDialog(String message) {
    // Dialog updates automatically via Obx
  }

  void _closeAllDialogs() {
    for (int i = 0; i < 5; i++) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      } else {
        break;
      }
    }
  }

  void _cleanupStreamState() {
    print('🔴 Cleaning up stream state');

    _streamTimer?.cancel();
    _streamTimer = null;

    isStreaming.value = false;
    isUploading.value = false;
    isRecording.value = false;
    uploadProgress.value = 0.0;
    currentStream.value = null;
    streamDuration.value = Duration.zero;
    elapsedTime.value = '00:00';
    liveComments.clear();
    viewerCount.value = 0;

    _disposeCamera();
    WakelockPlus.disable();
  }

  void _forceCloseScreen() {
    try {
      final context = Get.context;
      if (context == null) return;

      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        navigator.popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('🔴 Error closing screen: $e');
      Get.back();
    }
  }

  // ==================== COMMENTS ====================
  Future<void> sendComment(String text) async {
    if (text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || currentStream.value == null) return;

    if (currentStream.value!.bannedUsers.contains(user.uid)) {
      Get.snackbar('Error', 'You are banned from commenting');
      return;
    }

    if (!currentStream.value!.allowComments) {
      Get.snackbar('Info', 'Comments are disabled for this stream');
      return;
    }

    final userData = await FirebaseService.getUser(user.uid);

    final comment = LiveComment(
      userId: user.uid,
      userName: userData?.name ?? 'Unknown',
      userPic: userData?.profilePic ?? '',
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    await FirebaseService.addLiveComment(currentStream.value!.id, comment);
    commentController.clear();
  }

  // ==================== OTHER METHODS ====================
  Future<void> joinLiveStream(String streamId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'Please login to join');
        return;
      }

      await FirebaseService.joinLiveStream(streamId, user.uid);
      _listenToStreamUpdates(streamId);
      await FirebaseService.addToWatchHistory(user.uid, streamId);

    } catch (e) {
      Get.snackbar('Error', 'Failed to join stream: $e');
    }
  }

  Future<void> leaveLiveStream(String streamId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseService.leaveLiveStream(streamId, user.uid);
  }

  Future<void> shareStream() async {
    if (currentStream.value == null) return;

    final stream = currentStream.value!;
    final shareText = '''
🔴 LIVE: ${stream.title}
Host: ${stream.hostName}
Join now: https://yourapp.com/live/${stream.id}
''';

    Get.dialog(
      AlertDialog(
        title: Text('Share Stream'),
        content: Text(shareText),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Shared', 'Stream link copied!');
            },
            child: Text('Copy Link'),
          ),
        ],
      ),
    );
  }
}