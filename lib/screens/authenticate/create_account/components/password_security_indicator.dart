// password_security_indicator.dart

import 'package:flutter/material.dart';

/// Widget to display password strength indicator.
class PasswordSecurityIndicator extends StatelessWidget {
  final int strength;

  const PasswordSecurityIndicator({Key? key, required this.strength})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine color based on strength.
    Color color;
    if (strength == 1) {
      color = const Color.fromARGB(255, 149, 28, 28); // Red
    } else if (strength == 2 || strength == 3) {
      color = const Color.fromARGB(255, 219, 195, 60); // Yellow
    } else if (strength == 4) {
      color = const Color.fromARGB(255, 47, 134, 47); // Green
    } else {
      color = const Color.fromARGB(255, 100, 116, 139); // Gray
    }

    return Row(
      children: [
        // First 3 rectangles
        Row(
          children: List.generate(
            3,
            (index) => Container(
              width: 28,
              height: 5.5,
              margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.01),
              decoration: BoxDecoration(
                color: strength >= 1
                    ? color
                    : const Color.fromARGB(255, 100, 116, 139),
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ),
        // Next 2 rectangles
        Row(
          children: List.generate(
            2,
            (index) => Container(
              width: 28,
              height: 5.5,
              margin: const EdgeInsets.symmetric(horizontal: 4.4),
              decoration: BoxDecoration(
                color: strength >= 2
                    ? color
                    : const Color.fromARGB(255, 100, 116, 139),
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ),
        // Next 2 rectangles
        Row(
          children: List.generate(
            2,
            (index) => Container(
              width: 28,
              height: 5.5,
              margin: const EdgeInsets.symmetric(horizontal: 4.4),
              decoration: BoxDecoration(
                color: strength >= 3
                    ? color
                    : const Color.fromARGB(255, 100, 116, 139),
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ),
        // Last 3 rectangles
        Row(
          children: List.generate(
            3,
            (index) => Container(
              width: 25,
              height: 5.5,
              margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.01),
              decoration: BoxDecoration(
                color: strength == 4
                    ? color
                    : const Color.fromARGB(255, 100, 116, 139),
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
