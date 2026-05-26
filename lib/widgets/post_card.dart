// post_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/post_model.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onUserTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onBookmark;

  const PostCard({
    Key? key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onUserTap,
    this.onMoreTap,
    this.onBookmark,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  bool _isExpanded = false;
  bool _isBookmarked = false;

  // ✅ FIX: No local _isLiked / _likeCount state.
  // widget.post is the single source of truth, managed by TimelineController.
  // Removing local state eliminates the double-flip caused by optimistic
  // local update + stream-driven parent rebuild.

  late AnimationController _likeAnimController;
  late Animation<double> _likeScale;
  bool _showHeartBurst = false;

  // ✅ FIX: 600ms debounce prevents rapid double-taps from firing twice
  bool _likeDebouncing = false;

  static const _primaryColor = Color(0xFF6C63FF);
  static const _textDark = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _likeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _likeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 0.85), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _likeAnimController, curve: Curves.easeOut));

    if (widget.post.hasVideo && widget.post.mediaUrl != null) {
      _initializeVideo();
    }
  }

  void _initializeVideo() {
    final url = widget.post.mediaUrl!;
    if (url.isEmpty || !url.startsWith('http') || url.contains('example.com')) {
      setState(() => _hasVideoError = true);
      return;
    }
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _isVideoInitialized = true);
            // ✅ FIX: setLooping(true) is sufficient — removed manual position
            // check listener that caused continuous re-seeking.
            _videoController!.setLooping(true);
          }
        }).catchError((_) {
          if (mounted) setState(() => _hasVideoError = true);
        });
    } catch (_) {
      setState(() => _hasVideoError = true);
    }
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate like button when parent flips isLiked to true
    if (!oldWidget.post.isLiked && widget.post.isLiked) {
      _likeAnimController.forward(from: 0);
    }

    // Re-init video if URL changed
    if (oldWidget.post.mediaUrl != widget.post.mediaUrl) {
      _videoController?.pause();
      _videoController?.dispose();
      _videoController = null;
      _isVideoInitialized = false;
      _hasVideoError = false;
      if (widget.post.hasVideo && widget.post.mediaUrl != null) {
        _initializeVideo();
      }
    }
  }

  @override
  void dispose() {
    // ✅ FIX: Pause before dispose so audio doesn't linger
    _videoController?.pause();
    _videoController?.dispose();
    _likeAnimController.dispose();
    super.dispose();
  }

  void _handleLike() {
    // ✅ FIX: Debounce rapid taps
    if (_likeDebouncing) return;
    _likeDebouncing = true;
    Future.delayed(const Duration(milliseconds: 600), () => _likeDebouncing = false);

    HapticFeedback.lightImpact();

    if (!widget.post.isLiked) {
      _likeAnimController.forward(from: 0);
    }

    // ✅ FIX: Only call parent — no local state mutation.
    widget.onLike();
  }

  void _handleDoubleTap() {
    if (!widget.post.isLiked) {
      _handleLike();
      setState(() => _showHeartBurst = true);
      Future.delayed(const Duration(milliseconds: 900),
              () => mounted ? setState(() => _showHeartBurst = false) : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 28,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (widget.post.content.isNotEmpty) _buildContent(),
            if (widget.post.mediaUrl != null && widget.post.mediaUrl!.isNotEmpty)
              _buildMedia(),
            if (widget.post.tags.isNotEmpty) _buildHashtags(),
            _buildCountsRow(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F5)),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onUserTap,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.post.isLiveReplay
                          ? [Colors.red.shade400, Colors.orange.shade400]
                          : [const Color(0xFF6C63FF), const Color(0xFFFF6584)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 19.5,
                      backgroundImage: widget.post.userProfilePic != null &&
                          widget.post.userProfilePic!.isNotEmpty
                          ? CachedNetworkImageProvider(widget.post.userProfilePic!)
                          : null,
                      backgroundColor: const Color(0xFFEEECFF),
                      child: widget.post.userProfilePic == null ||
                          widget.post.userProfilePic!.isEmpty
                          ? Text(
                        widget.post.userName.isNotEmpty
                            ? widget.post.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _primaryColor,
                            fontSize: 16),
                      )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: widget.onUserTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.post.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: _textDark,
                              letterSpacing: -0.3),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: _primaryColor, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 9, color: Colors.white),
                      ),
                      if (widget.post.isLiveReplay) ...[
                        const SizedBox(width: 6),
                        _buildLiveReplayBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(_getPrivacyIcon(), size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(widget.post.timestamp),
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500),
                      ),
                      if (widget.post.location != null) ...[
                        Text(' · ', style: TextStyle(color: Colors.grey[400])),
                        Icon(Icons.location_on_rounded,
                            size: 11, color: Colors.grey[400]),
                        Flexible(
                          child: Text(
                            widget.post.location!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[450]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: widget.onMoreTap ?? () {},
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.more_horiz_rounded, color: Colors.grey[500], size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveReplayBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.red.shade500, Colors.red.shade400]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 5,
              height: 5,
              decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const SizedBox(width: 3),
          const Text('LIVE',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final text = widget.post.content;
    final isLong = text.length > 180;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
                fontSize: 14.5, height: 1.55, color: Color(0xFF2D2D44), letterSpacing: -0.1),
            maxLines: _isExpanded ? null : 3,
            overflow: _isExpanded ? null : TextOverflow.ellipsis,
          ),
          if (isLong)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _isExpanded ? 'Show less' : 'Read more',
                  style: const TextStyle(
                      color: _primaryColor, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.post.hasVideo ? _buildVideoPlayer() : _buildImage(),
          if (_showHeartBurst)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (_, v, __) => Opacity(
                opacity: v < 0.7 ? v / 0.7 : (1 - v) / 0.3,
                child: Transform.scale(
                  scale: 0.5 + v * 0.8,
                  child: const Icon(Icons.favorite_rounded, size: 90, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return CachedNetworkImage(
      imageUrl: widget.post.mediaUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      maxHeightDiskCache: 800,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFFEEEEEE),
        highlightColor: const Color(0xFFF8F8F8),
        child: Container(height: 260, color: Colors.white),
      ),
      errorWidget: (_, __, ___) => Container(
        height: 180,
        color: const Color(0xFFF5F6FA),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_rounded, size: 44, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('Image unavailable',
                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_hasVideoError) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.grey.shade900, Colors.grey.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration:
              BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.videocam_off_outlined, color: Colors.white60, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              widget.post.isLiveReplay ? 'Replay unavailable' : 'Video unavailable',
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        height: 220,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2.5)),
              const SizedBox(height: 14),
              Text('Loading...',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_videoController!),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.transparent,
                    Colors.black.withOpacity(0.35),
                  ],
                  stops: const [0, 0.4, 1],
                ),
              ),
            ),
          ),
          // ✅ FIX: ValueListenableBuilder avoids calling setState on the whole
          // card every frame, which was causing the video to appear to restart.
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _videoController!,
            builder: (_, value, __) => GestureDetector(
              onTap: () => value.isPlaying
                  ? _videoController!.pause()
                  : _videoController!.play(),
              child: AnimatedOpacity(
                opacity: value.isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 20)
                    ],
                  ),
                  child: Icon(
                    value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _textDark,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 46,
            right: 12,
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _videoController!,
              builder: (_, value, __) {
                final remaining = value.duration - value.position;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration:
                  BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _formatDuration(remaining),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: _primaryColor,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.black26,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtags() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: widget.post.tags
            .take(5)
            .map((tag) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('#$tag',
              style: const TextStyle(
                  color: _primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildCountsRow() {
    // ✅ FIX: Read directly from widget.post — no local state
    final likeCount = widget.post.likes.length;
    final commentCount = widget.post.commentsCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          if (likeCount > 0) ...[
            _buildLikeAvatars(likeCount),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _likeAnimController,
              builder: (_, __) => ScaleTransition(
                scale: _likeScale,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_rounded,
                        size: 15,
                        color: widget.post.isLiked ? Colors.red.shade400 : Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(likeCount),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.post.isLiked ? Colors.red.shade400 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          if (commentCount > 0)
            GestureDetector(
              onTap: widget.onComment,
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatCount(commentCount)} comment${commentCount == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          if (widget.post.isLiveReplay &&
              widget.post.viewCount != null &&
              widget.post.viewCount! > 0) ...[
            const SizedBox(width: 12),
            Row(
              children: [
                Icon(Icons.visibility_outlined, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(_formatCount(widget.post.viewCount!),
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLikeAvatars(int likeCount) {
    final colors = [Colors.blue.shade300, Colors.pink.shade300, Colors.orange.shade300];
    final count = likeCount.clamp(1, 3);
    return SizedBox(
      width: 16.0 * count + 8,
      height: 22,
      child: Stack(
        children: List.generate(
          count,
              (i) => Positioned(
            left: i * 14.0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: colors[i % colors.length],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.person, size: 11, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    final isLiked = widget.post.isLiked; // ✅ from widget.post only
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          _buildActionBtn(
            icon: isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            label: isLiked ? 'Liked' : 'Like',
            color: isLiked ? Colors.red.shade400 : Colors.grey[600]!,
            filled: isLiked,
            fillColor: Colors.red.shade50,
            onTap: _handleLike,
            animController: _likeAnimController,
          ),
          _buildActionBtn(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Comment',
            color: Colors.grey[600]!,
            onTap: widget.onComment,
          ),
          _buildActionBtn(
            icon: Icons.reply_rounded,
            label: 'Share',
            color: Colors.grey[600]!,
            onTap: widget.onShare,
            mirrorIcon: true,
          ),
          _buildActionBtn(
            icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            label: 'Save',
            color: _isBookmarked ? _primaryColor : Colors.grey[600]!,
            filled: _isBookmarked,
            fillColor: _primaryColor.withOpacity(0.08),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isBookmarked = !_isBookmarked);
              widget.onBookmark?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
    Color fillColor = Colors.transparent,
    bool mirrorIcon = false,
    AnimationController? animController,
  }) {
    final iconWidget =
    Transform.scale(scaleX: mirrorIcon ? -1 : 1, child: Icon(icon, color: color, size: 21));
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: filled ? fillColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                animController != null
                    ? ScaleTransition(scale: _likeScale, child: iconWidget)
                    : iconWidget,
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  IconData _getPrivacyIcon() {
    switch (widget.post.privacy.toLowerCase()) {
      case 'public': return Icons.public_rounded;
      case 'friends': return Icons.people_rounded;
      case 'only_me': return Icons.lock_rounded;
      default: return Icons.public_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}