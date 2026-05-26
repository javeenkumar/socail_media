// story_bar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/story_controller.dart';
import '../models/story_model.dart';
import '../screens/story_creation_screen.dart';
import '../screens/story_view_screen.dart';
//
// class StoryBar extends StatelessWidget {
//   final StoryController controller = Get.put(StoryController());
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 100,
//       child: Obx(() {
//         return ListView.builder(
//           scrollDirection: Axis.horizontal,
//           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//           itemCount: controller.stories.length + 1,
//           itemBuilder: (context, index) {
//             if (index == 0) {
//               return _buildAddStoryButton();
//             }
//
//             final story = controller.stories[index - 1];
//             return _buildStoryCircle(story);
//           },
//         );
//       }),
//     );
//   }
//
//   Widget _buildAddStoryButton() {
//     return Padding(
//       padding: EdgeInsets.only(right: 12),
//       child: Column(
//         children: [
//           GestureDetector(
//             onTap: () => Get.to(() => StoryCreationScreen()),
//             child: Container(
//               width: 60,
//               height: 60,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.blue, width: 2),
//               ),
//               child: Icon(Icons.add, size: 30, color: Colors.blue),
//             ),
//           ),
//           SizedBox(height: 4),
//           Text('Your Story', style: TextStyle(fontSize: 12)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStoryCircle(Story story) {
//     return Padding(
//       padding: EdgeInsets.only(right: 12),
//       child: GestureDetector(
//         onTap: () => Get.to(() => StoryViewScreen(story: story)),
//         child: Column(
//           children: [
//             Container(
//               padding: EdgeInsets.all(3),
//               width: 60,
//               height: 60,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 gradient: LinearGradient(
//                   colors: [Colors.purple, Colors.orange, Colors.yellow],
//                 ),
//               ),
//               child: Container(
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.white, width: 2),
//                   image: DecorationImage(
//                     image: NetworkImage(story.thumbnailUrl ?? story.mediaUrl),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 4),
//             Text(
//               story.userName,
//               style: TextStyle(fontSize: 12),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



class StoryBar extends StatelessWidget {
  final StoryController controller = Get.put(StoryController());

  // Group stories by userId, preserving the most recent story's thumbnail
  Map<String, List<Story>> _groupByUser(List<Story> stories) {
    final Map<String, List<Story>> grouped = {};
    for (final story in stories) {
      grouped.putIfAbsent(story.userId, () => []).add(story);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: Obx(() {
        final grouped = _groupByUser(controller.stories);
        final userIds = grouped.keys.toList();

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: userIds.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildAddStoryButton();

            final userId = userIds[index - 1];
            final userStories = grouped[userId]!;
            // Use the first story for display name/pic
            final representative = userStories.first;

            return _buildStoryCircle(representative, userStories);
          },
        );
      }),
    );
  }

  Widget _buildAddStoryButton() {
    return Padding(
      padding: EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Get.to(() => StoryCreationScreen()),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Icon(Icons.add, size: 30, color: Colors.blue),
            ),
          ),
          SizedBox(height: 4),
          Text('Your Story', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // Now receives all stories for this user
  Widget _buildStoryCircle(Story representative, List<Story> userStories) {
    return Padding(
      padding: EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => Get.to(() => StoryViewScreen(
          stories: userStories,   // ← pass the full list
          startIndex: 0,
        )),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(3),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.orange, Colors.yellow],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(
                      representative.thumbnailUrl ?? representative.mediaUrl,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              representative.userName,
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}