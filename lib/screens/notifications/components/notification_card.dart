// notification_card.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/screens/profile/pages/documents.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/database/models/notification_model.dart';
import 'package:team_shaikh_app/database/database.dart';
import 'package:team_shaikh_app/screens/utils/resources.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/notifications/notifications.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart'; // Update with the correct import path

class NotificationCard extends StatelessWidget {
  final Notif notification;
  final Client client;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.client,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildNotification(context, notification);
  }

  Widget _buildNotification(BuildContext context, Notif notification) {
    String title;
    Widget route;
    Color? color = Colors.grey[200];
    switch (notification.type) {
      case 'activity':
        title = 'New Activity';
        route =
            const ActivityPage(); // Replace with your actual Activity page widget
        break;
      case 'statement':
        title = 'New Statement';
        route =
            const ProfilePage(); // Replace with your actual Profile page widget
        break;
      default:
        title = 'New Notification';
        route =
            const NotificationPage(); // Replace with your actual Notification page widget
        break;
    }

    // Determine if the message contains "AK1" or "AGQ"
    bool containsAK1 = notification.message.contains('AK1');
    bool containsAGQ = notification.message.contains('AGQ');

    // Calculate the time ago string
    String timeAgo = timeago.format(notification.time, locale: 'en_short');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 20, 5),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: null,
                  borderRadius:
                      BorderRadius.circular(15.0), // Set the border radius
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0,0,0,0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: !notification.isRead
                            ? const CircleAvatar(
                                radius: 6,
                                backgroundColor: AppColors.defaultBlue300,
                              )
                            : const CircleAvatar(
                                radius: 6,
                                backgroundColor: Colors.transparent,
                              ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Title and icons
                            Row(
                              children: [
                                Text(
                                  title,
                                  style: AppTextStyles.lBold(
                                      color: AppColors.defaultWhite),
                                ),
                                const SizedBox(width: 12.0),
                                if (containsAK1)
                                  SvgPicture.asset(
                                    'assets/icons/ak1_logo.svg',
                                    height: 16.0,
                                    width: 16.0,
                                  ),
                                if (containsAGQ)
                                  SvgPicture.asset(
                                    'assets/icons/agq_logo.svg',
                                    height: 16.0,
                                    width: 16.0,
                                  ),
                              ],
                            ),
                            // Time ago
                            Text(
                              timeAgo,
                              style: AppTextStyles.sRegular(
                                  color: AppColors.defaultWhite),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: AppTextStyles.xsRegular(
                                  color: AppColors.defaultWhite),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ],
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                        dense: true,
                        onTap: () {
                          if (notification.type == 'activity') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ActivityPage(),
                              ),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DocumentsPage(),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(thickness: 0.5,),
      ],
    );
  }
}