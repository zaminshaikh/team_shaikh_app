// email_verification_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Dialog widget for email verification.
class EmailVerificationDialog extends StatelessWidget {
  final VoidCallback onContinue;

  const EmailVerificationDialog({Key? key, required this.onContinue})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Dialog(
      backgroundColor: const Color.fromARGB(255, 37, 58, 86),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 500,
        width: 1000,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            SvgPicture.asset(
              'assets/icons/verify_email_iconart.svg',
              height: 200,
              width: 200,
            ),
            const Spacer(),
            const Text(
              'Verify your Email Address',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
            const Spacer(),
            const Center(
              child: Text(
                'You will recieve an Email with a link to verify your email. Please check your inbox.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onContinue,
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.blue,
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
