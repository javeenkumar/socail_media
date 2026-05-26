import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/timeline_controller.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/post_card.dart';
import '../widgets/story_bar.dart';
import 'post_creation_screen.dart';

class TimelineScreen extends StatefulWidget {
  @override
  _TimelineScreenState createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen>
    with SingleTickerProviderStateMixin {
  final TimelineController controller = Get.find<TimelineController>();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  bool _showFab = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOut,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;

    // Hide/show FAB on scroll direction
    if (offset > _lastScrollOffset + 10 && _showFab) {
      setState(() => _showFab = false);
      _fabAnimationController.reverse();
    } else if (offset < _lastScrollOffset - 10 && !_showFab) {
      setState(() => _showFab = true);
      _fabAnimationController.forward();
    }
    _lastScrollOffset = offset;

    // Pagination
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      controller.loadMorePosts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(innerBoxIsScrolled),
          ],
          body: RefreshIndicator(
            color: const Color(0xFF6C63FF),
            backgroundColor: Colors.white,
            displacement: 20,
            onRefresh: () => controller.refreshPosts(),
            child: Obx(() {
              if (controller.isLoading.value && controller.posts.isEmpty) {
                return _buildLoadingState();
              }
              if (controller.posts.isEmpty) {
                return _buildEmptyState();
              }
              return _buildFeed();
            }),
          ),
        ),
        floatingActionButton: ScaleTransition(
          scale: _fabScaleAnimation,
          child: _buildFAB(),
        ),
      ),
    );
  }

  // ─── Sliver App Bar ───────────────────────────────────────────────────────

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.06),
      forceElevated: innerBoxIsScrolled,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Logo mark
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Feed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
                letterSpacing: -0.8,
              ),
            ),
            const Spacer(),
            // Live indicator
            // _buildLiveChip(),
          ],
        ),
      ),
      actions: [
        _buildIconButton(
          icon: Icons.search_rounded,
          onTap: () => Get.toNamed('/search'),
        ),
        _buildIconButton(
          icon: Icons.chat_outlined,
          onTap: () => Get.toNamed('/friend'),
          badge: true,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Widget _buildLiveChip() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //     decoration: BoxDecoration(
  //       color: Colors.red.shade50,
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(color: Colors.red.shade100),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Container(
  //           width: 7,
  //           height: 7,
  //           decoration: BoxDecoration(
  //             color: Colors.red.shade500,
  //             shape: BoxShape.circle,
  //             boxShadow: [
  //               BoxShadow(
  //                   color: Colors.red.shade300,
  //                   blurRadius: 4,
  //                   spreadRadius: 1),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(width: 5),
  //         Text(
  //           'LIVE',
  //           style: TextStyle(
  //             color: Colors.red.shade600,
  //             fontSize: 11,
  //             fontWeight: FontWeight.w800,
  //             letterSpacing: 0.8,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Stack(
        children: [
          Material(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icon,
                    color: const Color(0xFF1A1A2E), size: 22),
              ),
            ),
          ),
          if (badge)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF6C63FF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Feed ─────────────────────────────────────────────────────────────────

  Widget _buildFeed() {
    return Obx(() => CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Stats bar
        SliverToBoxAdapter(child: _buildStatsBar()),

        // Stories
        SliverToBoxAdapter(child: StoryBar()),

        // Section header
        SliverToBoxAdapter(child: _buildSectionHeader()),

        // Posts
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              if (index == controller.posts.length) {
                return controller.isLoadingMore.value
                    ? _buildLoadMoreIndicator()
                    : const SizedBox(height: 100);
              }
              final post = controller.posts[index];
              return AnimatedPostWrapper(
                index: index,
                child: PostCard(
                  post: post,
                  onLike: () => controller.likePost(post),
                  onComment: () => _showComments(post),
                  onShare: () => controller.sharePost(post),
                  onUserTap: () =>
                      Get.toNamed('/profile/${post.userId}'),
                ),
              );
            },
            childCount: controller.posts.length + 1,
          ),
        ),
      ],
    ));
  }

  Widget _buildStatsBar() {
    return Obx(() {
      final totalLikes = controller.posts
          .fold<int>(0, (sum, p) => sum + p.likes.length);
      final totalComments = controller.posts
          .fold<int>(0, (sum, p) => sum + p.commentsCount);
      final totalPosts = controller.posts.length;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
                icon: Icons.article_rounded,
                value: '$totalPosts',
                label: 'Posts'),
            _buildStatDivider(),
            _buildStatItem(
                icon: Icons.favorite_rounded,
                value: _formatCount(totalLikes),
                label: 'Likes'),
            _buildStatDivider(),
            _buildStatItem(
                icon: Icons.chat_bubble_rounded,
                value: _formatCount(totalComments),
                label: 'Comments'),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 32,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          const Text(
            'Latest Posts',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${controller.posts.length}',
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          )),
          const Spacer(),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor:
              const Color(0xFF6C63FF).withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Filter',
              style: TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty / Loading states ───────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.dynamic_feed_rounded,
                size: 44, color: Color(0xFF6C63FF)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nothing here yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to post something!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => _openPostCreation(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12),
      itemCount: 4,
      itemBuilder: (_, i) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmerBox(width: 48, height: 48, radius: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(width: 120, height: 12, radius: 6),
                  const SizedBox(height: 6),
                  _shimmerBox(width: 80, height: 10, radius: 5),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _shimmerBox(width: double.infinity, height: 14, radius: 7),
          const SizedBox(height: 6),
          _shimmerBox(width: 200, height: 14, radius: 7),
          const SizedBox(height: 14),
          _shimmerBox(width: double.infinity, height: 180, radius: 12),
        ],
      ),
    );
  }

  Widget _shimmerBox(
      {required double width,
        required double height,
        required double radius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: const Color(0xFF6C63FF).withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading more...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FAB ──────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: _openPostCreation,
          borderRadius: BorderRadius.circular(18),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'Post',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _openPostCreation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostCreationScreen(),
    );
  }

  void _showComments(dynamic post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, c) => CommentsSheet(post: post),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

// ─── Animated Post Wrapper ────────────────────────────────────────────────────

class AnimatedPostWrapper extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedPostWrapper(
      {Key? key, required this.child, required this.index})
      : super(key: key);

  @override
  State<AnimatedPostWrapper> createState() => _AnimatedPostWrapperState();
}

class _AnimatedPostWrapperState extends State<AnimatedPostWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + (widget.index * 60).clamp(0, 400)),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Stagger based on index, capped so items further down don't wait too long
    Future.delayed(
        Duration(milliseconds: (widget.index * 80).clamp(0, 320)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}