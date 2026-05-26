import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/profile_controller.dart';
import '../models/post_model.dart';
import '../models/reel_model.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfileController controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Obx(() {  // Single Obx at top level
        if (controller.isLoading.value && controller.currentUser.value == null) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          );
        }

        final user = controller.currentUser.value;
        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Could not load profile',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: controller.loadAllUserData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadAllUserData,
          color: Colors.black,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Modern AppBar with Gradient ─────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                floating: false,
                backgroundColor: Colors.black,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.purple[900]!,
                              Colors.blue[900]!,
                              Colors.black,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 60,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Hero(
                              tag: 'profile_${user.id}',
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: user.profilePic != null
                                      ? NetworkImage(user.profilePic!)
                                      : null,
                                  child: user.profilePic == null
                                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 10, color: Colors.black54),
                                ],
                              ),
                            ),
                            if (user.age != null)
                              Text(
                                '${user.age} years old',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => Get.toNamed('/edit-profile'),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      onPressed: () => _showLogoutDialog(context),
                      tooltip: 'Logout',
                    ),
                  ),
                ],
              ),

              // ── Stats Cards ─────────────────────────────────

              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      margin: EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatTile(
                            label: 'Posts',
                            value: controller.userPosts.length,
                            icon: Icons.grid_on,
                            color: Colors.blue,
                          ),
                          _buildDivider(),
                          _StatTile(
                            label: 'Reels',
                            value: controller.userReels.length,
                            icon: Icons.video_collection,
                            color: Colors.purple,
                          ),
                          _buildDivider(),
                          _StatTile(
                            label: 'Followers',
                            value: user.followersCount,
                            icon: Icons.people,
                            color: Colors.green,
                          ),
                          _buildDivider(),
                          _StatTile(
                            label: 'Following',
                            value: user.followingCount,
                            icon: Icons.person_add,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bio Section ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'About',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                user.bio!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.pink[50]!, Colors.purple[50]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _EngagementItem(
                              icon: Icons.favorite,
                              value: controller.totalLikes,
                              label: 'Total Likes',
                              color: Colors.pink,
                            ),
                            const SizedBox(width: 40),
                            _EngagementItem(
                              icon: Icons.visibility,
                              value: controller.totalViews,
                              label: 'Total Views',
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Tab Bar ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _TabButton(
                        label: 'Posts',
                        icon: Icons.grid_on,
                        isSelected: controller.selectedTab.value == 'posts',
                        onTap: () => controller.selectedTab.value = 'posts',
                      ),
                      _TabButton(
                        label: 'Reels',
                        icon: Icons.video_collection,
                        isSelected: controller.selectedTab.value == 'reels',
                        onTap: () => controller.selectedTab.value = 'reels',
                      ),
                      _TabButton(
                        label: 'Stories',
                        icon: Icons.auto_stories,
                        isSelected: controller.selectedTab.value == 'stories',
                        onTap: () => controller.selectedTab.value = 'stories',
                      ),
                      _TabButton(
                        label: 'Live',
                        icon: Icons.live_tv,
                        isSelected: controller.selectedTab.value == 'live',
                        onTap: () => controller.selectedTab.value = 'live',
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Tab Content ─────────────────────────────────
              // Use SliverFillRemaining or wrap content based on tab
              _buildTabContent(),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      }),
    );
  }

  // Build tab content widget based on selected tab
  Widget _buildTabContent() {
    // Use Obx only for the content that changes
    return SliverToBoxAdapter(
      child: Obx(() {
        switch (controller.selectedTab.value) {
          case 'posts':
            return _PostsGrid(
              posts: controller.userPosts.toList(),
              controller: controller,
            );
          case 'reels':
            return _ReelsGrid(
              reels: controller.userReels.toList(),
              controller: controller,
            );
          case 'stories':
            return _StoriesList(
              stories: controller.userStories.toList(),
              controller: controller,
            );
          case 'live':
            return _LiveReplaysList(
              replays: controller.livedReplayPosts.toList(),
              controller: controller,
            );
          default:
            return _PostsGrid(
              posts: controller.userPosts.toList(),
              controller: controller,
            );
        }
      }),
    );
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[200]);
  }

  void _showLogoutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Icon(Icons.logout, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                const Text(
                  'Logout?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to logout from your account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Get.back();
                          await _logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      await FirebaseAuth.instance.signOut();
      Get.back();
      Get.offAllNamed('/login');
      Get.snackbar(
        'See you soon! 👋',
        'Logged out successfully',
        backgroundColor: Colors.black,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      if (Get.isDialogOpen!) Get.back();
      Get.snackbar('Error', 'Failed to logout: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}

// ── Widget Classes (same as before) ─────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          _formatNumber(value),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }
}

class _EngagementItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _EngagementItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Grid and List Classes ───────────────────────────────────

class _PostsGrid extends StatelessWidget {
  final List<Post> posts;
  final ProfileController controller;

  const _PostsGrid({required this.posts, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _EmptyState(
        icon: Icons.grid_on,
        message: 'No posts yet',
        subMessage: 'Share your first photo or video',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return GestureDetector(
            onLongPress: () => _showDeleteDialog(
              context,
              'post',
                  () => controller.deletePost(post.id),
            ),
            onTap: () => Get.toNamed('/post-detail', arguments: post),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  post.mediaUrl != null
                      ? Image.network(
                    post.mediaUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image),
                    ),
                  )
                      : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.text_fields),
                  ),
                  if (post.mediaType == 'video')
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 16,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likes?.length ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReelsGrid extends StatelessWidget {
  final List<Reel> reels;
  final ProfileController controller;

  const _ReelsGrid({required this.reels, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (reels.isEmpty) {
      return const _EmptyState(
        icon: Icons.video_collection,
        message: 'No reels yet',
        subMessage: 'Create your first short video',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 0.6,
        ),
        itemCount: reels.length,
        itemBuilder: (context, index) {
          final reel = reels[index];
          return GestureDetector(
            onLongPress: () => _showDeleteDialog(
              context,
              'reel',
                  () => controller.deleteReel(reel.id),
            ),
            onTap: () => Get.toNamed('/reel-detail', arguments: reel),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  reel.thumbnailUrl != null
                      ? Image.network(
                    reel.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black87,
                      child: const Icon(Icons.play_circle, color: Colors.white, size: 40),
                    ),
                  )
                      : Container(
                    color: Colors.black87,
                    child: const Icon(Icons.play_circle, color: Colors.white, size: 40),
                  ),
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(
                      Icons.video_collection,
                      color: Colors.white,
                      size: 16,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${reel.views?.length ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StoriesList extends StatelessWidget {
  final List stories;
  final ProfileController controller;

  const _StoriesList({required this.stories, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return const _EmptyState(
        icon: Icons.auto_stories,
        message: 'No active stories',
        subMessage: 'Share a story that disappears in 24h',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Colors.purple, Colors.pink]),
                ),
                child: CircleAvatar(
                  backgroundImage: story.userProfilePic != null
                      ? NetworkImage(story.userProfilePic!)
                      : null,
                  child: story.userProfilePic == null ? const Icon(Icons.person) : null,
                ),
              ),
              title: Text(story.caption ?? 'Story', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${story.viewers.length} views · ${_timeAgo(story.timestamp)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'View',
                  style: TextStyle(
                    color: Colors.purple[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () => Get.toNamed('/story-view', arguments: story),
            ),
          );
        },
      ),
    );
  }
}

class _LiveReplaysList extends StatelessWidget {
  final List replays;
  final ProfileController controller;

  const _LiveReplaysList({required this.replays, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (replays.isEmpty) {
      return const _EmptyState(
        icon: Icons.live_tv,
        message: 'No live replays yet',
        subMessage: 'Start a live stream to engage with your audience',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: replays.length,
        itemBuilder: (context, index) {
          final replay = replays[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.red[400]!, Colors.red[600]!]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.live_tv, color: Colors.white),
              ),
              title: Text(
                replay.content.replaceFirst('📺 Was LIVE: ', ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${replay.viewCount ?? 0} views'
                    '${replay.streamDuration != null ? ' · ${replay.streamDuration}' : ''}'
                    ' · ${_timeAgo(replay.timestamp)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              trailing: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow, color: Colors.red[600]),
              ),
              onTap: () => Get.toNamed('/video-player', arguments: replay.mediaUrl),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subMessage;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.subMessage = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showDeleteDialog(BuildContext context, String type, VoidCallback onConfirm) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Icon(Icons.delete_outline, size: 48, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Delete $type?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}