// views/watch_live_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../controllers/live_controller.dart';
import '../models/live_stream_model.dart';

class WatchLiveScreen extends StatefulWidget {
  final LiveStream stream;

  const WatchLiveScreen({Key? key, required this.stream}) : super(key: key);

  @override
  _WatchLiveScreenState createState() => _WatchLiveScreenState();
}

class _WatchLiveScreenState extends State<WatchLiveScreen> {
  final LiveController controller = Get.find();
  VideoPlayerController? _videoController;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  var isVideoInitialized = false.obs;

  @override
  void initState() {
    super.initState();

    // If live stream, join it
    if (widget.stream.isLive) {
      controller.joinLiveStream(widget.stream.id);
    }

    // If recorded stream with playback URL, initialize video player
    if (!widget.stream.isLive && widget.stream.playbackUrl != null) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.network(widget.stream.playbackUrl!)
        ..initialize().then((_) {
          isVideoInitialized.value = true;
          _videoController?.play();
        }).catchError((e) {
          print('🔴 Video player error: $e');
          Get.snackbar('Error', 'Failed to load video');
        });
    } catch (e) {
      print('🔴 Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    // Leave stream if live
    if (widget.stream.isLive) {
      controller.leaveLiveStream(widget.stream.id);
    }

    _videoController?.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLive = widget.stream.isLive;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video/Stream Display
          Positioned.fill(
            child: isLive
                ? _buildLiveView()
                : _buildRecordedView(),
          ),

          // UI Overlay
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(isLive),
                Spacer(),
                if (isLive) _buildLiveBottomSection(),
                if (!isLive) _buildRecordedBottomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveView() {
    // For live streams, show a placeholder or actual stream player
    // In production, integrate with RTMP player or WebRTC
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.live_tv, size: 80, color: Colors.red),
            SizedBox(height: 16),
            Text(
              '🔴 LIVE STREAM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Stream player integration needed',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordedView() {
    if (widget.stream.playbackUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Replay not available',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Obx(() {
      if (!isVideoInitialized.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      }

      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    });
  }

  Widget _buildTopBar(bool isLive) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: widget.stream.userProfilePic != null
                        ? NetworkImage(widget.stream.userProfilePic!)
                        : null,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.stream.hostName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isLive
                              ? '${widget.stream.viewerCount} viewers'
                              : 'Recorded ${widget.stream.startTime}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLive ? Colors.red : Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isLive ? 'LIVE' : 'REPLAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showStreamOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBottomSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      child: Row(
        children: [
          // Comments
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Live Chat',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      final comments = controller.liveComments;
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[comments.length - 1 - index];
                          return _buildCommentTile(comment);
                        },
                      );
                    }),
                  ),
                  // Comment input
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white10,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.send, color: Colors.blue),
                          onPressed: () {
                            controller.sendComment(_commentController.text);
                            _commentController.clear();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            width: 80,
            margin: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(Icons.favorite, Colors.red, 'Like', () {}),
                SizedBox(height: 16),
                _buildActionButton(Icons.share, Colors.white, 'Share',
                        () => controller.shareStream()),
                SizedBox(height: 16),
                _buildActionButton(Icons.card_giftcard, Colors.yellow, 'Gift', () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordedBottomSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Video controls for recorded streams
          if (!widget.stream.isLive && _videoController != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.replay_10, color: Colors.white),
                    onPressed: () {
                      final newPos = _videoController!.value.position - Duration(seconds: 10);
                      _videoController!.seekTo(newPos);
                    },
                  ),
                  Obx(() => IconButton(
                    icon: Icon(
                      isVideoInitialized.value && _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: () {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                      // Force refresh
                      isVideoInitialized.refresh();
                    },
                  )),
                  IconButton(
                    icon: Icon(Icons.forward_10, color: Colors.white),
                    onPressed: () {
                      final newPos = _videoController!.value.position + Duration(seconds: 10);
                      _videoController!.seekTo(newPos);
                    },
                  ),
                ],
              ),
            ),

          SizedBox(height: 16),

          // Stream info
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.stream.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.stream.description != null) ...[
                  SizedBox(height: 8),
                  Text(
                    widget.stream.description!,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
                SizedBox(height: 8),
                Text(
                  'Recorded on ${widget.stream.startTime}',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(LiveComment comment) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${comment.userName}: ',
              style: TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: comment.text,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  void _showStreamOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.report, color: Colors.red),
                title: Text('Report', style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.block, color: Colors.orange),
                title: Text('Block User', style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.share, color: Colors.blue),
                title: Text('Share', style: TextStyle(color: Colors.white)),
                onTap: () {
                  controller.shareStream();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}