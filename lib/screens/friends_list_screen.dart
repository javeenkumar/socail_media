import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/friends_controller.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';

class FriendsListScreen extends StatelessWidget {
  FriendsListScreen({Key? key}) : super(key: key);

  final FriendsController controller = Get.put(FriendsController());

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            snap: true,
            pinned: true,
            elevation: innerBoxIsScrolled ? 2 : 0,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              title: Text(
                'Messages',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                onPressed: () => Get.toNamed('/search-users'),
              ),
              IconButton(
                icon: Badge(
                  smallSize: 8,
                  child: Icon(Icons.person_add_outlined, color: colorScheme.primary),
                ),
                onPressed: () => _showAddFriendDialog(),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        body: Obx(() {
          if (controller.isLoading.value) {
            return _buildLoadingState(context);
          }

          if (controller.errorMessage.value.isNotEmpty) {
            return _buildErrorState(context);
          }

          if (controller.friends.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async => controller.loadFriends(),
            color: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Online friends section
                if (_hasOnlineFriends())
                  SliverToBoxAdapter(
                    child: _buildOnlineFriendsSection(context),
                  ),

                // Section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      children: [
                        Text(
                          'Recent Chats',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${controller.friends.length} friends',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Friends list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final friendData = controller.friends[index];
                        return _buildAnimatedFriendCard(context, friendData, index);
                      },
                      childCount: controller.friends.length,
                    ),
                  ),
                ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFriendDialog(),
        elevation: 4,
        icon: const Icon(Icons.edit),
        label: const Text('New Chat'),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading friends...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => controller.loadFriends(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add friends to start chatting',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showAddFriendDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Find Friends'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasOnlineFriends() {
    return controller.friends.any((f) => (f['user'] as UserModel).isOnline);
  }

  Widget _buildOnlineFriendsSection(BuildContext context) {
    final onlineFriends = controller.friends
        .where((f) => (f['user'] as UserModel).isOnline)
        .take(10)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            'Online Now',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: onlineFriends.length,
            itemBuilder: (context, index) {
              final friend = onlineFriends[index]['user'] as UserModel;
              return _OnlineFriendAvatar(
                friend: friend,
                onTap: () {
                  final chatId = onlineFriends[index]['chatId'] as String;
                  controller.markAsRead(chatId);
                  Get.to(
                        () => ChatScreen(
                      chatId: chatId,
                      otherUserId: friend.id,
                    ),
                    transition: Transition.cupertino,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedFriendCard(BuildContext context, Map<String, dynamic> friendData, int index) {
    final friend = friendData['user'] as UserModel;
    final chatId = friendData['chatId'] as String;
    final lastMessage = friendData['lastMessage'] as String?;
    final lastMessageTime = friendData['lastMessageTime'] as DateTime?;
    final unreadCount = friendData['unreadCount'] as int? ?? 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _FriendCard(
          friend: friend,
          chatId: chatId,
          lastMessage: lastMessage,
          lastMessageTime: lastMessageTime,
          unreadCount: unreadCount,
          onTap: () {
            controller.markAsRead(chatId);
            Get.to(
                  () => ChatScreen(
                chatId: chatId,
                otherUserId: friend.id,
              ),
              transition: Transition.cupertino,
            );
          },
        ),
      ),
    );
  }

  void _showAddFriendDialog() {
    Get.toNamed('/search-users');
  }
}

// Online friends avatar
class _OnlineFriendAvatar extends StatelessWidget {
  final UserModel friend;
  final VoidCallback onTap;

  const _OnlineFriendAvatar({
    required this.friend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'avatar_${friend.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: friend.profilePic != null && friend.profilePic!.isNotEmpty
                          ? NetworkImage(friend.profilePic!)
                          : null,
                      child: friend.profilePic == null || friend.profilePic!.isEmpty
                          ? Text(
                        friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 68,
              child: Text(
                friend.name.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Friend card widget
class _FriendCard extends StatelessWidget {
  final UserModel friend;
  final String chatId;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final VoidCallback onTap;

  const _FriendCard({
    required this.friend,
    required this.chatId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasUnread = unreadCount > 0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: hasUnread
          ? colorScheme.primaryContainer.withOpacity(0.08)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasUnread
              ? colorScheme.primary.withOpacity(0.15)
              : colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Hero(
                    tag: 'avatar_list_${friend.id}',
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: friend.profilePic != null && friend.profilePic!.isNotEmpty
                          ? NetworkImage(friend.profilePic!)
                          : null,
                      child: friend.profilePic == null || friend.profilePic!.isEmpty
                          ? Text(
                        friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      )
                          : null,
                    ),
                  ),
                  if (friend.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            friend.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (lastMessageTime != null)
                          Text(
                            _formatTime(lastMessageTime!),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread ? colorScheme.primary : colorScheme.onSurfaceVariant,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage ?? 'Say hello! 👋',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.3,
                              color: hasUnread ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else if (friend.isVerified)
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays >= 7) {
      return '${time.day}/${time.month}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    }
    return 'now';
  }
}