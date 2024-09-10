import 'package:flutter/material.dart';

class CustomProgressIndicator extends StatelessWidget {
  const CustomProgressIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const CircularProgressIndicator(
      valueColor: const AlwaysStoppedAnimation<Color>(Colors.transparent),
      strokeWidth: 6.0,
    );
}
