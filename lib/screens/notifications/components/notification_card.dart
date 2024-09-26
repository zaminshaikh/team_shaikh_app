// notification_card.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/database/models/notification_model.dart';
import 'package:team_shaikh_app/database/database.dart';
import 'package:team_shaikh_app/utils/resources.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/notifications/notifications.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart'; // Update with the correct import path

class NotificationCard extends StatelessWidget {
  final Notif notification;
  final Client client;
  final DateTime previousNotificationDate;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.client,
    required this.previousNotificationDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => _buildNotificationWithDayHeader(
      context, notification, previousNotificationDate);

  Widget _buildNotificationWithDayHeader(
      BuildContext context, notification, DateTime previousNotificationDate) {
    final notificationDate = notification.time;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              DateFormat('MMMM d, yyyy').format(notificationDate),
              style: AppTextStyles.xl2(color: AppColors.defaultWhite),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Divider(color: AppColors.defaultWhite),
        ), // Day header
        _buildNotification(context, notification, false),
        // Notification
      ],
    );
  }

  Widget _buildNotification(
      BuildContext context, Notif notification, bool showDivider) {
    String title;
    Widget route;
    Color? color = Colors.grey[200];
    switch (notification.type) {
      case 'activity':
        title = 'New Activity';
        route =
            const ActivityPage(); // replace with your actual Activity page widget
        break;
      case 'statement':
        title = 'New Statement';
        route =
            const ProfilePage(); // replace with your actual Profile page widget
        break;
      default:
        title = 'New Notification';
        route =
            const NotificationPage(); // replace with your actual Notification page widget
        break;
    }

    // Determine if the message contains "AK1" or "AGQ"
    bool containsAK1 = notification.message.contains('AK1');
    bool containsAGQ = notification.message.contains('AGQ');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 10, 5),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: !notification.isRead ? color?.withOpacity(0.05) : null,
                  borderRadius:
                      BorderRadius.circular(15.0), // Set the border radius
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: !notification.isRead
                            ? const CircleAvatar(
                                radius: 8,
                                backgroundColor: AppColors.defaultBlue300,
                              )
                            : const CircleAvatar(
                                radius: 8,
                                backgroundColor: Colors.transparent,
                              ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            const SizedBox(
                                height:
                                    4), // Add desired spacing between title and subtitle
                            Column(
                              children: [
                                Text(
                                  notification.message,
                                  style: AppTextStyles.xsRegular(
                                      color: AppColors.defaultWhite),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ],
                            ),
                            const SizedBox(
                                height:
                                    4), // Add desired spacing between message and ID
                          ],
                        ),
                        
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 8.0),
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
