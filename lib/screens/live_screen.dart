// views/live_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/live_controller.dart';
import '../models/live_stream_model.dart';
import 'go_live_screen.dart';
import 'watch_live_screen.dart';

class LiveScreen extends StatelessWidget {
  final LiveController controller = Get.put(LiveController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: Colors.black,
            floating: true,
            title: Row(
              children: [
                Icon(Icons.live_tv, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: Colors.white),
                onPressed: () => _showSearch(),
              ),
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: () => Get.to(() => GoLiveScreen()),
                  icon: Icon(Icons.videocam, size: 18),
                  label: Text('Go Live'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Categories
          SliverToBoxAdapter(
            child: _buildCategories(),
          ),

          // 🔴 LIVE NOW Section
          SliverToBoxAdapter(
            child: _buildSectionTitle('🔴 Live Now'),
          ),
          SliverPadding(
            padding: EdgeInsets.all(12),
            sliver: Obx(() {
              final liveStreams = controller.liveStreams.where((s) => s.isLive).toList();
              return _buildStreamGrid(liveStreams, isLive: true);
            }),
          ),

          // 📼 Recent Replays Section
          SliverToBoxAdapter(
            child: _buildSectionTitle('📼 Recent Replays'),
          ),
          SliverPadding(
            padding: EdgeInsets.all(12),
            sliver: Obx(() {
              final replays = controller.liveStreams.where((s) => !s.isLive && s.playbackUrl != null).toList();
              return _buildStreamGrid(replays, isLive: false);
            }),
          ),

          // 🔥 Trending Section
          SliverToBoxAdapter(
            child: _buildSectionTitle('🔥 Trending'),
          ),
          SliverToBoxAdapter(
            child: _buildTrendingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemCount: controller.categories.length,
        itemBuilder: (context, index) {
          final category = controller.categories[index];
          return Obx(() {
            final isSelected = controller.selectedCategory.value == category;
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) => controller.selectedCategory.value = category,
                selectedColor: Colors.red,
                backgroundColor: Colors.grey[800],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[400],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStreamGrid(List<LiveStream> streams, {required bool isLive}) {
    if (streams.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 150,
          child: Center(
            child: Text(
              isLive ? 'No live streams' : 'No replays available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final stream = streams[index];
          return _buildStreamCard(stream, isLive: isLive);
        },
        childCount: streams.length,
      ),
    );
  }

  Widget _buildStreamCard(LiveStream stream, {required bool isLive}) {
    return GestureDetector(
      onTap: () => Get.to(() => WatchLiveScreen(stream: stream)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[900],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: stream.thumbnail ?? stream.userProfilePic ?? '',
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey[800]),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
                    ),
                    // Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLive ? Colors.red : Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isLive ? 'LIVE' : 'REPLAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Viewers/Duration
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLive ? Icons.visibility : Icons.play_arrow,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              isLive
                                  ? '${stream.viewerCount}'
                                  : _formatDuration(stream.duration),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stream.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: stream.userProfilePic != null
                            ? NetworkImage(stream.userProfilePic!)
                            : null,
                        child: stream.userProfilePic == null
                            ? Icon(Icons.person, size: 16)
                            : null,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stream.hostName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildTrendingList() {
    return Container(
      height: 200,
      child: Obx(() {
        if (controller.trendingStreams.isEmpty) {
          return Center(
            child: Text(
              'No trending streams',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12),
          itemCount: controller.trendingStreams.length,
          itemBuilder: (context, index) {
            final stream = controller.trendingStreams[index];
            return _buildTrendingCard(stream);
          },
        );
      }),
    );
  }

  Widget _buildTrendingCard(LiveStream stream) {
    return GestureDetector(
      onTap: () => Get.to(() => WatchLiveScreen(stream: stream)),
      child: Container(
        width: 280,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple, Colors.red],
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: stream.thumbnail ?? stream.userProfilePic ?? '',
                width: 280,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[800]),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: Icon(Icons.person, size: 60, color: Colors.grey),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: stream.isLive ? Colors.red : Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    if (stream.isLive)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (stream.isLive) SizedBox(width: 6),
                    Text(
                      stream.isLive ? 'LIVE' : 'REPLAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '${stream.viewerCount}',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stream.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: stream.userProfilePic != null
                            ? NetworkImage(stream.userProfilePic!)
                            : null,
                        child: stream.userProfilePic == null
                            ? Icon(Icons.person, size: 14)
                            : null,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stream.hostName,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (stream.category != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            stream.category!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearch() {
    showSearch(
      context: Get.context!,
      delegate: LiveStreamSearchDelegate(),
    );
  }
}

class LiveStreamSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(child: Text('Search: $query'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(child: Text('Search for live streams...'));
  }
}