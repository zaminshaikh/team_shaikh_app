import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/database/models/activity_model.dart';
import 'package:team_shaikh_app/screens/activity/utils/activity_styles.dart';
import 'package:team_shaikh_app/screens/utils/utilities.dart';

class ActivityCardItem extends StatelessWidget {
  final Activity activity;

  const ActivityCardItem({
    required this.activity,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat timeFormat = DateFormat('h:mm a');
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');
    String time = timeFormat.format(activity.time);
    String date = dateFormat.format(activity.time);

    return Container(
      width: MediaQuery.of(context).size.width * 0.55, // Set a fixed width
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: getActivityColor(activity.type), width: 2.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActivityDetails(),
                  SizedBox(height: 16.0),
                  _buildActivityAmountAndRecipient(time),
                  SizedBox(height: 16.0),
                  _buildActivityDateTime(date, time),
                ],
              ),
            ),
            _buildActivityIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityDateTime(String date, String time) => Row(
        children: [
          Text(
            date,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
          SizedBox(width: 2),
          SvgPicture.asset(
            'assets/icons/line.svg',
            color: Colors.white,
            height: 15,
          ),
          SizedBox(width: 2),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
        ],
      );

  Widget _buildActivityIcon() => Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.circle,
            color: getUnderlayColor(activity.type),
            size: 50,
          ),
          getActivityIcon(activity.type),
        ],
      );

  Widget _buildActivityDetails() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.fund,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Titillium Web',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            getActivityType(activity),
            style: TextStyle(
              fontSize: 15,
              color: getActivityColor(activity.type),
              fontWeight: FontWeight.bold,
              fontFamily: 'Titillium Web',
            ),
          ),
        ],
      );

  Widget _buildActivityAmountAndRecipient(String time) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${activity.type == 'withdrawal' ? '-' : ''}${currencyFormat(activity.amount.toDouble())}',
              style: TextStyle(
                fontSize: 18,
                color: getActivityColor(activity.type),
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                activity.recipient,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ],
          ),
        ],
      );
}