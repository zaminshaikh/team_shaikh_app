// password_validation.dart

import 'package:flutter/material.dart';

/// Widget to display password validation checks.
class PasswordValidation extends StatelessWidget {
  final String password;

  const PasswordValidation({Key? key, required this.password})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildValidationRow(
          'At least 8 characters',
          password.length >= 8,
        ),
        const SizedBox(height: 16.0),
        _buildValidationRow(
          '1 digit',
          password.contains(RegExp(r'\d')),
        ),
        const SizedBox(height: 16.0),
        _buildValidationRow(
          '1 uppercase character',
          password.contains(RegExp(r'[A-Z]')),
        ),
        const SizedBox(height: 16.0),
        _buildValidationRow(
          '1 lowercase character',
          password.contains(RegExp(r'[a-z]')),
        ),
      ],
    );
  }

  /// Builds a validation row with an icon and text.
  Widget _buildValidationRow(String text, bool isValid) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_rounded : Icons.circle_outlined,
            size: 30,
            color: isValid
                ? const Color.fromARGB(255, 61, 130, 63)
                : const Color.fromARGB(255, 100, 116, 139),
          ),
          const SizedBox(width: 10.0),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
        ],
      ),
    );
  }
}
