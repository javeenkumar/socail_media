import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socialmedia/controllers/user_search_controller.dart';
import 'package:socialmedia/screens/search_users_screen.dart';
import '../controllers/create_reel_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/reels_controller.dart';
import '../controllers/nearby_controller.dart';
import '../controllers/live_controller.dart';
import '../controllers/speech_controller.dart';
import '../controllers/timeline_controller.dart';
import '../controllers/tts_controller.dart';
import '../controllers/friends_controller.dart';
import 'timeline_screen.dart';
import 'reels_screen.dart';
import 'nearby_screen.dart';
import 'friends_list_screen.dart';
import 'live_screen.dart';
import 'post_creation_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  late final AnimationController _fabAnimationController;
  late final Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();

    // ── FAB animation ──────────────────────────────────────
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    );
    _fabAnimationController.forward();

    // ── Controllers ────────────────────────────────────────
    Get.put(TimelineController());
    Get.put(ReelsController());
    Get.put(ProfileController());
    Get.put(FriendsController());
    Get.put(LiveController());
    Get.put(SpeechController());
    Get.put(TTSController());
    Get.put(CreateReelController());
    Get.put(UserSearchController());

    // ── Screens ────────────────────────────────────────────
    _screens = [
      TimelineScreen(),
      ReelsScreen(),
      ProfileScreen(),
      // FriendsListScreen(),
      SearchUsersScreen(),
      LiveScreen(),
    ];
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    // Animate FAB in/out
    if (index == 0) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  void _openPostCreation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostCreationScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // ── App Bar ─────────────────────────────────────────
      // appBar: _buildAppBar(isDark),

      // ── Body ─────────────────────────────────────────────
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ── Bottom Nav ────────────────────────────────────────
      bottomNavigationBar: _buildBottomNav(isDark, theme),
    );
  }

  // ── AppBar builder ──────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isDark) {
    final titles = ['Timeline', 'Reels', 'Profile', 'Chats', 'Live'];
    final title = titles[_currentIndex];

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor:
      isDark ? Colors.grey[900] : Colors.white,
      centerTitle: false,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          title,
          key: ValueKey(title),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      actions: [
        // Live indicator (only on Live tab)
        if (_currentIndex == 4)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.white, size: 8),
                SizedBox(width: 4),
                Text('LIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),

        // Search button
        if (_currentIndex == 0 || _currentIndex == 2)
          IconButton(
            icon: Icon(Icons.search_rounded,
                color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Get.toNamed('/search'),
          ),

        // Notifications
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_outlined,
                  color:
                  isDark ? Colors.white : Colors.black87),
              // Notification dot
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () => Get.toNamed('/notifications'),
        ),

        const SizedBox(width: 4),
      ],
    );
  }

  // ── Bottom Nav builder ──────────────────────────────────────────────────────
  Widget _buildBottomNav(bool isDark, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Timeline',
                index: 0,
                currentIndex: _currentIndex,
                onTap: _onTabChanged,
              ),
              _NavItem(
                icon: Icons.play_circle_outline_rounded,
                activeIcon: Icons.play_circle_rounded,
                label: 'Reels',
                index: 1,
                currentIndex: _currentIndex,
                onTap: _onTabChanged,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                index: 2,
                currentIndex: _currentIndex,
                onTap: _onTabChanged,
              ),
              _NavItem(
                icon: Icons.people_alt_outlined,
                activeIcon: Icons.people,
                label: 'Friends',
                index: 3,
                currentIndex: _currentIndex,
                onTap: _onTabChanged,
              ),
              _NavItem(
                icon: Icons.live_tv_outlined,
                activeIcon: Icons.live_tv_rounded,
                label: 'Live',
                index: 4,
                currentIndex: _currentIndex,
                onTap: _onTabChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Nav Item
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = theme.primaryColor;
    final inactiveColor =
    isDark ? Colors.grey[500]! : Colors.grey[600]!;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    color:
                    isSelected ? activeColor : inactiveColor,
                    size: 24,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 3),

            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
                color:
                isSelected ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}