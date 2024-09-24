// notification_card.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_shaikh_app/database/models/client_model.dart';
import 'package:team_shaikh_app/database/models/notification_model.dart';
import 'package:team_shaikh_app/database/database.dart';
import 'package:team_shaikh_app/resources.dart';
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
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
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.lBold(
                                  color: AppColors.defaultWhite),
                            ),
                            const SizedBox(
                                height:
                                    4), // Add desired spacing between title and subtitle
                            Text(
                              notification.message,
                              style: AppTextStyles.xsRegular(
                                  color: AppColors.defaultWhite),
                            ),
                          ],
                        ),
                        trailing: !notification.isRead
                            ? const CircleAvatar(
                                radius: 8,
                                backgroundColor: AppColors.defaultBlue300,
                              )
                            : const CircleAvatar(
                                radius: 8,
                                backgroundColor: Colors.transparent,
                              ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 8.0),
                        dense: true,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              // Mark the notification as read
                              DatabaseService db = DatabaseService.withCID(
                                  '', notification.parentCID);
                              await db.markNotificationAsRead(notification.id);

                              await Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (context, animation1, animation2) =>
                                            route,
                                    transitionDuration: Duration.zero,
                                  ));
                            } catch (e) {
                              if (e is FirebaseException &&
                                  e.code == 'not-found') {
                                log('notification.dart: The document was not found');
                                log('notification.dart: Notification ID: ${notification.id}');
                                log('notification.dart: uid: ${client.uid}');
                              } else {
                                rethrow;
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.defaultBlue300,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: Text(
                            'View More',
                            style: AppTextStyles.lBold(
                                color: AppColors.defaultWhite),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15.0),
                    ],
                  ),
                ),
              ),
              if (showDivider)
                const Padding(
                  padding: EdgeInsets.all(5),
                  child: Divider(color: AppColors.defaultWhite),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
