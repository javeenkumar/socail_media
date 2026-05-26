import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';

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
                color: isSuperLike ? Colors.blue : Colors.red,
                size: 80
            ),
            SizedBox(height: 16),
            Text(
                'It\'s a Match!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
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
                    onPressed: () {
                      Get.back();
                      // TODO: Navigate to chat
                      // Get.to(() => ChatScreen(user: matchedUser));
                    },
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