import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/nearby_controller.dart';
import '../models/user_model.dart';

class NearbyScreen extends StatelessWidget {
  final NearbyController controller = Get.isRegistered<NearbyController>()
      ? Get.find<NearbyController>()
      : Get.put(NearbyController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text('Discover', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.black87),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black87),
            onPressed: () => controller.getCurrentLocation(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.status.value.isLoading && controller.nearbyUsers.isEmpty) {
          return _buildLoadingState();
        }

        if (controller.status.value.isError) {
          return _buildErrorState();
        }

        if (controller.nearbyUsers.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            Expanded(
              child: _buildCardStack(),
            ),
            _buildActionButtons(),
            SizedBox(height: 20),
          ],
        );
      }),
    );
  }

  Widget _buildCardStack() {
    return Obx(() {
      final users = controller.nearbyUsers;
      final currentIndex = controller.currentCardIndex.value;

      return Stack(
        alignment: Alignment.center,
        children: [
          // Background cards for depth effect
          if (users.length > currentIndex + 1)
            _buildBackgroundCard(users[currentIndex + 1], 0.9, -10),
          if (users.length > currentIndex + 2)
            _buildBackgroundCard(users[currentIndex + 2], 0.8, -20),

          // Active swipeable card
          if (currentIndex < users.length)
            _buildSwipeableCard(users[currentIndex]),
        ],
      );
    });
  }

  Widget _buildBackgroundCard(UserModel user, double scale, double offsetY) {
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        child: _buildCardContent(user, isActive: false),
      ),
    );
  }

  Widget _buildSwipeableCard(UserModel user) {
    return GestureDetector(
      onPanUpdate: (details) {
        controller.swipeDirection.value = details.delta.dx > 0
            ? SwipeDirection.right
            : SwipeDirection.left;
      },
      onPanEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx > 1000) {
          controller.likeUser();
        } else if (details.velocity.pixelsPerSecond.dx < -1000) {
          controller.dislikeUser();
        } else {
          controller.swipeDirection.value = null;
        }
      },
      onTap: () => controller.onTapCard(user),
      // ✅ FIXED: Use Obx + plain Transform — no AnimationController needed
      child: Obx(() {
        final direction = controller.swipeDirection.value;

        double rotation = 0;
        double translationX = 0;

        if (direction == SwipeDirection.right) {
          rotation = 0.1;
          translationX = 20; // subtle tilt while dragging, not full exit
        } else if (direction == SwipeDirection.left) {
          rotation = -0.1;
          translationX = -20;
        }

        return Transform.translate(
          offset: Offset(translationX, 0),
          child: Transform.rotate(
            angle: rotation,
            child: _buildCardContent(user, isActive: true),
          ),
        );
      }),
    );
  }

  Widget _buildCardContent(UserModel user, {required bool isActive}) {
    final distance = controller.currentPosition.value != null
        ? user.distanceFrom(
      controller.currentPosition.value!.latitude,
      controller.currentPosition.value!.longitude,
    )?.toStringAsFixed(1) ?? '?'
        : '?';

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with hero animation
            Hero(
              tag: 'user_${user.id}',
              child: Image.network(
                user.profilePic ?? 'https://via.placeholder.com/400',
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Center(child: CircularProgressIndicator());
                },
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.person, size: 100, color: Colors.grey[600]),
                ),
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: [0.6, 1.0],
                ),
              ),
            ),

            // Like/Nope indicators during swipe
            if (isActive)
              Positioned(
                top: 40,
                left: 20,
                child: Obx(() {
                  if (controller.swipeDirection.value == SwipeDirection.left) {
                    return _buildSwipeIndicator('NOPE', Colors.red);
                  }
                  return SizedBox.shrink();
                }),
              ),
            if (isActive)
              Positioned(
                top: 40,
                right: 20,
                child: Obx(() {
                  if (controller.swipeDirection.value == SwipeDirection.right) {
                    return _buildSwipeIndicator('LIKE', Colors.green);
                  }
                  return SizedBox.shrink();
                }),
              ),

            // User info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${user.name}${user.age != null ? ', ${user.age}' : ''}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (user.isVerified == true)
                          Icon(Icons.verified, color: Colors.blue, size: 24),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white70, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '$distance km away',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        if (user.lastActive != null) ...[
                          SizedBox(width: 12),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white70,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            _getLastActiveText(user.lastActive!),
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 12),
                    if (user.bio != null && user.bio!.isNotEmpty)
                      Text(
                        user.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    SizedBox(height: 12),
                    if (user.interests.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.interests.take(5).map((interest) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: Text(
                              interest,
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeIndicator(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.close,
            color: Colors.red,
            onTap: controller.dislikeUser,
            label: 'PASS',
          ),
          _buildActionButton(
            icon: Icons.star,
            color: Colors.blue,
            size: 50,
            iconSize: 24,
            onTap: controller.superLikeUser,
            label: 'SUPER',
          ),
          _buildActionButton(
            icon: Icons.favorite,
            color: Colors.green,
            size: 60,
            iconSize: 30,
            onTap: controller.likeUser,
            label: 'LIKE',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    double size = 56,
    double iconSize = 28,
    required VoidCallback onTap,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          elevation: 4,
          shadowColor: color.withOpacity(0.4),
          shape: CircleBorder(),
          child: InkWell(
            customBorder: CircleBorder(),
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Finding people nearby...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          SizedBox(height: 16),
          Text('Something went wrong', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => controller.getCurrentLocation(),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No one nearby',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Try increasing your search radius',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showFilterDialog(),
            icon: Icon(Icons.tune),
            label: Text('Adjust Filters'),
          ),
        ],
      ),
    );
  }

  String _getLastActiveText(DateTime lastActive) {
    final diff = DateTime.now().difference(lastActive);
    if (diff.inMinutes < 1) return 'Active now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showFilterDialog() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text('Filters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 24),

              // Distance slider
              Text('Maximum Distance', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${controller.radius.value.toInt()} km'),
                  Text('${controller.maxDistance.value.toInt()} km'),
                ],
              )),
              Obx(() => Slider(
                value: controller.radius.value,
                min: 1,
                max: controller.maxDistance.value,
                divisions: 49,
                label: '${controller.radius.value.toInt()} km',
                onChanged: controller.updateRadius,
              )),

              SizedBox(height: 16),

              // Age range
              Text('Age Range', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${controller.minAge.value}'),
                  Text('${controller.maxAge.value}'),
                ],
              )),
              Obx(() => RangeSlider(
                values: RangeValues(
                  controller.minAge.value.toDouble(),
                  controller.maxAge.value.toDouble(),
                ),
                min: 18,
                max: 80,
                divisions: 62,
                labels: RangeLabels(
                  '${controller.minAge.value}',
                  '${controller.maxAge.value}',
                ),
                onChanged: (values) {
                  controller.minAge.value = values.start.toInt();
                  controller.maxAge.value = values.end.toInt();
                },
              )),

              SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.applyFilters,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Apply Filters', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

// At the bottom of nearby_screen.dart, replace the placeholder classes with:

class MatchDialog extends StatelessWidget {
  final UserModel matchedUser;
  final bool isSuperLike;

  MatchDialog({required this.matchedUser, this.isSuperLike = false});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                isSuperLike ? Icons.star : Icons.favorite,
                color: isSuperLike ? Colors.blue : Colors.pink,
                size: 80
            ),
            SizedBox(height: 16),
            Text(
                'It\'s a Match!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.pink)
            ),
            SizedBox(height: 8),
            Text(
              'You and ${matchedUser.name} liked each other',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: Text('Keep Swiping'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                    onPressed: () => Get.back(),
                    child: Text('Send Message'),
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

// class UserDetailScreen extends StatelessWidget {
//   final UserModel user;
//   UserDetailScreen({required this.user});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             expandedHeight: 400,
//             pinned: true,
//             flexibleSpace: FlexibleSpaceBar(
//               title: Text(user.name),
//               background: Hero(
//                 tag: 'user_${user.id}',
//                 child: Image.network(
//                   user.profilePic ?? 'https://via.placeholder.com/400',
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//           ),
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Text(
//                         '${user.name}, ${user.age ?? '?'}',
//                         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                       ),
//                       if (user.isVerified) ...[
//                         SizedBox(width: 8),
//                         Icon(Icons.verified, color: Colors.blue),
//                       ],
//                     ],
//                   ),
//                   SizedBox(height: 8),
//                   if (user.bio != null) Text(user.bio!, style: TextStyle(fontSize: 16)),
//                   SizedBox(height: 16),
//                   if (user.interests.isNotEmpty) ...[
//                     Text('Interests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                     SizedBox(height: 8),
//                     Wrap(
//                       spacing: 8,
//                       children: user.interests.map((interest) => Chip(label: Text(interest))).toList(),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }