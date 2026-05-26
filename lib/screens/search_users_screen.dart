import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_search_controller.dart';
import '../models/user_model.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({Key? key}) : super(key: key);

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  late final UserSearchController controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Safe: find existing permanent instance, put if not exists
    controller = Get.isRegistered<UserSearchController>()
        ? Get.find<UserSearchController>()
        : Get.put(UserSearchController());
    controller.refresh();
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      // ── Use regular AppBar + Column body instead of
      //    NestedScrollView to avoid the overflow ──────────
      appBar: _buildAppBar(colorScheme),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────
          _SearchBar(
            controller: _searchController,
            onChanged: controller.onSearchChanged,
            colorScheme: colorScheme,
          ),
          // ── Tab bar ─────────────────────────────────────
          Obx(() => _ModernTabBar(
            selectedIndex: controller.selectedTab.value,
            pendingCount: controller.pendingRequests.length,
            onTap: (i) => controller.selectedTab.value = i,
          )),
          // ── Body ────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.selectedTab.value == 0) {
                return _AllUsersTab(controller: controller);
              } else {
                return _RequestsTab(controller: controller);
              }
            }),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      // leading: IconButton(
      //   icon: Icon(Icons.arrow_back_ios_new_rounded,
      //       color: colorScheme.onSurface),
      //   onPressed: () => Get.back(),
      // ),
      title: Text(
        'Find People',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: colorScheme.onSurface,
        ),
      ),
      actions: [
        Obx(() {
          final count = controller.pendingRequests.length;
          if (count == 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ColorScheme colorScheme;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: controller,
        autofocus: false,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          hintStyle:
          TextStyle(color: colorScheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search_rounded,
              color: colorScheme.primary),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              if (value.text.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(Icons.clear_rounded,
                    color: colorScheme.onSurfaceVariant),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              );
            },
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest
              .withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
            BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}

// ── Modern Tab Bar ────────────────────────────────────────────────────────────

class _ModernTabBar extends StatelessWidget {
  final int selectedIndex;
  final int pendingCount;
  final ValueChanged<int> onTap;

  const _ModernTabBar({
    required this.selectedIndex,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'All Users',
            icon: Icons.people_outline_rounded,
            selected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _Tab(
            label: 'Requests',
            icon: Icons.person_add_outlined,
            selected: selectedIndex == 1,
            badgeCount: pendingCount,
            onTap: () => onTap(1),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primary
                        : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── All Users Tab ─────────────────────────────────────────────────────────────

class _AllUsersTab extends StatelessWidget {
  final UserSearchController controller;
  const _AllUsersTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Loading skeleton
      if (controller.isLoadingUsers.value) {
        return ListView.builder(
          padding:
          const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemCount: 6,
          itemBuilder: (_, i) => _SkeletonCard(index: i),
        );
      }

      // Error
      if (controller.errorMessage.value.isNotEmpty) {
        return _ErrorView(
          message: controller.errorMessage.value,
          onRetry: controller.loadAllUsers,
        );
      }

      // Empty
      if (controller.filteredUsers.isEmpty) {
        return _EmptyView(
          icon: controller.searchQuery.value.isEmpty
              ? Icons.people_outline
              : Icons.search_off_rounded,
          message: controller.searchQuery.value.isEmpty
              ? 'No users found'
              : 'No results for "${controller.searchQuery.value}"',
          subtitle: controller.searchQuery.value.isEmpty
              ? 'Check back later for new users'
              : 'Try a different search term',
        );
      }

      // List
      return RefreshIndicator(
        onRefresh: controller.loadAllUsers,
        color: Theme.of(context).colorScheme.primary,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
              vertical: 8, horizontal: 16),
          itemCount: controller.filteredUsers.length,
          itemBuilder: (context, index) {
            final user = controller.filteredUsers[index];
            return Obx(() {
              final relation = controller.getRelation(user.id);
              return _AnimatedCard(
                index: index,
                child: _UserCard(
                  user: user,
                  relation: relation,
                  onAction: () =>
                      _handleAction(relation, user.id),
                ),
              );
            });
          },
        ),
      );
    });
  }

  void _handleAction(UserRelation relation, String userId) {
    switch (relation) {
      case UserRelation.none:
        controller.sendRequest(userId);
        break;
      case UserRelation.requestSent:
        controller.cancelRequest(userId);
        break;
      case UserRelation.requestReceived:
        controller.acceptRequest(userId);
        break;
      case UserRelation.friend:
        break;
    }
  }
}

// ── Requests Tab ──────────────────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  final UserSearchController controller;
  const _RequestsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingRequests.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.pendingRequests.isEmpty) {
        return const _EmptyView(
          icon: Icons.inbox_outlined,
          message: 'No pending requests',
          subtitle: 'Friend requests will appear here',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemCount: controller.pendingRequests.length,
        itemBuilder: (context, index) {
          final user = controller.pendingRequests[index];
          return _AnimatedCard(
            index: index,
            child: _RequestCard(
              user: user,
              onAccept: () => controller.acceptRequest(user.id),
              onDecline: () => controller.declineRequest(user.id), // This now properly declines
            ),
          );
        },
      );
    });
  }
}

// ── Animated Card Wrapper ─────────────────────────────────────────────────────

class _AnimatedCard extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedCard({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + (index * 40)),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Transform.translate(
        offset: Offset(0, 16 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: child,
    );
  }
}

// ── User Card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UserModel user;
  final UserRelation relation;
  final VoidCallback onAction;

  const _UserCard({
    required this.user,
    required this.relation,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _Avatar(user: user, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + online dot
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isOnline) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.bio != null &&
                        user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.bio!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant
                              .withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _RelationButton(
                  relation: relation, onTap: onAction),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Request Card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestCard({
    required this.user,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: colorScheme.primaryContainer.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _Avatar(user: user, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.person_add_rounded,
                            size: 13,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Wants to be your friend',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (user.email != null &&
                          user.email!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.email!,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                            colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDecline,
                    icon: const Icon(
                        Icons.close_rounded,
                        size: 16),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(
                          color: colorScheme.error),
                      padding: const EdgeInsets.symmetric(
                          vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(
                        Icons.check_rounded,
                        size: 16),
                    label: const Text('Accept'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Relation Button ───────────────────────────────────────────────────────────

class _RelationButton extends StatelessWidget {
  final UserRelation relation;
  final VoidCallback onTap;

  const _RelationButton(
      {required this.relation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (relation) {
      case UserRelation.friend:
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.green.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded,
                  size: 15, color: Colors.green[700]),
              const SizedBox(width: 5),
              Text(
                'Friends',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );

      case UserRelation.requestSent:
        return OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.close_rounded, size: 15), // Change to close icon
          label: const Text('Cancel', style: TextStyle(fontSize: 13)), // "Cancel" not "Sent"
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

      // case UserRelation.requestSent:
      //   return OutlinedButton.icon(
      //     onPressed: onTap,
      //     icon: const Icon(Icons.schedule_rounded, size: 15),
      //     label: const Text('Sent',
      //         style: TextStyle(fontSize: 13)),
      //     style: OutlinedButton.styleFrom(
      //       foregroundColor: Colors.orange,
      //       side: const BorderSide(color: Colors.orange),
      //       padding: const EdgeInsets.symmetric(
      //           horizontal: 14, vertical: 8),
      //       minimumSize: Size.zero,
      //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      //       shape: RoundedRectangleBorder(
      //         borderRadius: BorderRadius.circular(12),
      //       ),
      //     ),
      //   );

      case UserRelation.requestReceived:
        return FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.person_add_rounded,
              size: 15),
          label: const Text('Accept',
              style: TextStyle(fontSize: 13)),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

      case UserRelation.none:
      default:
        return FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.person_add_rounded,
              size: 15),
          label: const Text('Add',
              style: TextStyle(fontSize: 13)),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    }
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final UserModel user;
  final double size;

  const _Avatar({required this.user, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.primaryContainer,
      backgroundImage: (user.profilePic != null &&
          user.profilePic!.isNotEmpty)
          ? NetworkImage(user.profilePic!)
          : null,
      child: (user.profilePic == null ||
          user.profilePic!.isEmpty)
          ? Text(
        user.name.isNotEmpty
            ? user.name[0].toUpperCase()
            : '?',
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      )
          : null,
    );
  }
}

// ── Skeleton Card ─────────────────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  final int index;
  const _SkeletonCard({required this.index});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fade = Tween(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _fade,
      builder: (_, __) => Opacity(
        opacity: _fade.value,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest
                .withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Avatar placeholder
              CircleAvatar(
                radius: 26,
                backgroundColor:
                colorScheme.onSurfaceVariant.withOpacity(0.2),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 130,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 190,
                      height: 11,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 68,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty View ────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const _EmptyView({
    required this.icon,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
                color:
                colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
              child: Icon(Icons.cloud_off_outlined,
                  size: 44,
                  color: colorScheme.onErrorContainer),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}