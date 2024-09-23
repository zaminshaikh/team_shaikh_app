// widgets/activity_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/database/models/activity_model.dart';
import 'package:team_shaikh_app/screens/activity/utils/activity_styles.dart';
import 'package:team_shaikh_app/utilities.dart';

class ActivityListItem extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;

  const ActivityListItem(
      {required this.activity, required this.onTap, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateFormat timeFormat = DateFormat('h:mm a');
    String time = timeFormat.format(activity.time);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30.0, 5.0, 15.0, 5.0),
        child: Container(
          color: Colors.transparent,
          child: Row(
            children: [
              _buildActivityIcon(),
              _buildActivityDetails(),
              const Spacer(),
              _buildActivityAmountAndTime(time),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityIcon() => Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.circle,
            color: getUnderlayColor(activity.type),
            size: 50,
          ),
          getActivityIcon(activity.type),
        ],
      ),
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

  Widget _buildActivityAmountAndTime(String time) => Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.centerRight,
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
              time,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontFamily: 'Titillium Web',
              ),
            ),
            SvgPicture.asset(
              'assets/icons/line.svg',
              color: Colors.white,
              height: 15,
            ),
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
