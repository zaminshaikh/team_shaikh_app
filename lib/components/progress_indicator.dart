import 'package:flutter/material.dart';
import 'package:team_shaikh_app/screens/utils/resources.dart';

class CustomProgressIndicator extends StatelessWidget {
  const CustomProgressIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      strokeWidth: 6.0,
    );
}

class CustomProgressIndicatorPage extends StatelessWidget {
  const CustomProgressIndicatorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          padding: const EdgeInsets.all(26.0),
          margin: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 50.0),
          decoration: BoxDecoration(
            color: AppColors.defaultBlue500,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: const Stack(
            children: [
              CustomProgressIndicator(),
            ],
          ),
        ),
      );
}