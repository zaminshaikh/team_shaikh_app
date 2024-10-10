// mark_all_as_read_button.dart
import 'package:flutter/material.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/database/database.dart';
import 'package:team_shaikh_app/screens/utils/resources.dart'; // Update with the correct import path

class MarkAllAsReadButton extends StatelessWidget {
  final Client client;
  final VoidCallback onRefresh;

  const MarkAllAsReadButton({
    Key? key,
    required this.client,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool hasUnreadNotifications = (client.numNotifsUnread ?? 0) > 0;

    if (!hasUnreadNotifications) {
      return Container(); // Return an empty container if there are no unread notifications
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.bottomCenter, // Align to bottom center
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Adjust padding as needed
            child: ElevatedButton(
              onPressed: () async {
                await DatabaseService.withCID(client.uid, client.cid)
                    .markAllNotificationsAsRead();
                onRefresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.defaultBlue500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0), // Add padding to the button
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min, // Add this
                children: [
                  Icon(Icons.checklist_rounded, color: Colors.white),
                  Text(
                    ' Mark All As Read',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
