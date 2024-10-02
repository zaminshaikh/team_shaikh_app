// create_account_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:team_shaikh_app/components/alert_dialog.dart';
import 'package:team_shaikh_app/database/auth_helper.dart';
import 'dart:developer';
import 'package:team_shaikh_app/database/database.dart';
import 'package:team_shaikh_app/screens/authenticate/create_account/components/email_verification_dialog.dart';
import 'package:team_shaikh_app/screens/authenticate/create_account/components/password_security_indicator.dart';
import 'package:team_shaikh_app/screens/authenticate/create_account/components/password_validation.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart';
import 'package:team_shaikh_app/screens/authenticate/utils/app_state.dart';
import 'package:team_shaikh_app/screens/authenticate/utils/google_auth_service.dart';

/// A StatefulWidget representing the Create Account page.
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({Key? key}) : super(key: key);

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

/// State class for the CreateAccountPage.
class _CreateAccountPageState extends State<CreateAccountPage> {
  // Controllers for text fields.
  final TextEditingController _clientIDController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _createAccountPasswordController =
      TextEditingController();
  final TextEditingController _confirmCreateAccountPasswordController =
      TextEditingController();

  // Firebase and app state.
  late DatabaseService db;
  late AuthState appState;

  // User inputs and states.
  bool _isButtonEnabled = false;
  bool _hidePassword = true;
  String _cid = '';
  String _email = '';
  String _createAccountPasswordString = '';
  String _confirmCreateAccountPasswordString = '';
  int _passwordSecurityIndicator = 0;

  @override
  void initState() {
    super.initState();
    _clientIDController.addListener(_checkIfFilled);
  }

  @override
  void dispose() {
    _clientIDController.removeListener(_checkIfFilled);
    _clientIDController.dispose();
    super.dispose();
  }

  /// Checks if the Client ID field is filled to enable the button.
  void _checkIfFilled() {
    setState(() {
      _cid = _clientIDController.text;
      _isButtonEnabled = _cid.isNotEmpty;
    });
  }

  /// Handles the sign-up process.
  void _signUserUp() async {
    // Delete any existing user in the buffer.
    await deleteUserInBuffer();

    try {
      // Create a new user with email and password.
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _createAccountPasswordController.text.trim(),
      );

      if (userCredential.user == null) {
        throw FirebaseAuthException(code: 'operation-not-allowed');
      }

      log('UserCredential created: ${userCredential.user!.uid}. In buffer.');

      // Initialize database service with CID.
      db = DatabaseService.withCID(userCredential.user!.uid, _cid);

      // Check if CID exists and is not linked.
      if (!(await db.docExists(_cid))) {
        await _showErrorAndDeleteUser(
            'There is no record of the Client ID $_cid in the database. Please contact support or re-enter your Client ID.');
        return;
      } else if (await db.docLinked(_cid)) {
        await _showErrorAndDeleteUser(
            'User already exists for given Client ID $_cid. Please log in instead.');
        return;
      }

      // Send email verification.
      await FirebaseAuth.instance.currentUser!.sendEmailVerification();

      // Show email verification dialog.
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (BuildContext context) => EmailVerificationDialog(
          onContinue: _verifyEmail,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      handleFirebaseAuthException(context, e, _email);
    } catch (e) {
      log('Error signing user up: $e', stackTrace: StackTrace.current);
      await FirebaseAuth.instance.currentUser?.delete();
    }
  }

  /// Verifies if the email is confirmed and proceeds accordingly.
  Future<void> _verifyEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      String uid = user.uid;
      await db.linkNewUser(user.email!);
      log('User $uid connected to Client ID $_cid');

      await updateFirebaseMessagingToken(user);

      if (!mounted) return;
      await CustomAlertDialog.showAlertDialog(
        context,
        'Success',
        'Email verified successfully.',
        icon:
            const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
      );
      if (!mounted) return;
      appState = Provider.of<AuthState>(context, listen: false);
      appState.setInitiallyAuthenticated(true);

      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      if (!mounted) return;
      await CustomAlertDialog.showAlertDialog(
        context,
        'Error',
        'Email not verified. Please check your inbox for the verification link.',
        icon: const Icon(Icons.error_outline, color: Colors.red),
      );
    }
  }

  /// Shows an error dialog and deletes the current user.
  Future<void> _showErrorAndDeleteUser(String message) async {
    if (!mounted) return;
    await CustomAlertDialog.showAlertDialog(context, 'Error', message);
    await FirebaseAuth.instance.currentUser?.delete();
    log('Error: $message');
  }

  /// Updates the password strength indicator.
  void _updatePasswordSecurityIndicator() {
    int conditionsMet = 0;

    if (_createAccountPasswordString.length > 7) {
      conditionsMet++;
    }

    if (_createAccountPasswordString.contains(RegExp(r'\d'))) {
      conditionsMet++;
    }

    if (_createAccountPasswordString.contains(RegExp(r'[A-Z]'))) {
      conditionsMet++;
    }

    if (_createAccountPasswordString.contains(RegExp(r'[a-z]'))) {
      conditionsMet++;
    }

    // Update _passwordSecurityIndicator based on the number of conditions met
    _passwordSecurityIndicator = conditionsMet;
  }

  /// Updates the password string and security indicator.
  void _updateFields(String value) {
    setState(() {
      _createAccountPasswordString = value;
      _createAccountPasswordController.text = value;
      _updatePasswordSecurityIndicator();
    });
  }

  /// Checks if the passwords match.
  bool _doPasswordsMatch() => _createAccountPasswordString ==
            _confirmCreateAccountPasswordString &&
        _createAccountPasswordString.isNotEmpty;

  /// Builds the create account screen widget.
  @override
  Widget build(BuildContext context) => Scaffold(
      body: SingleChildScrollView(
        // Wrapping everything in a column to arrange children vertically
        child: Column(
          // Centering the children
          mainAxisAlignment: MainAxisAlignment.center,

          // Making a list of child widgets in the Column
          children: <Widget>[
            // Logo and branding
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D5EAF), // Start color
                    Color.fromARGB(255, 17, 24, 39), // End color
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 60.0),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Align(
                          alignment: const Alignment(-1.0, -1.0),
                          child: Image.asset(
                            'assets/icons/team_shaikh_transparent.png',
                            height: 100,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30.0),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Text widget to display "Create An Account"
                  const Text(
                    'Create An Account',
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Titillium Web',
                    ),
                  ),

                  // Adding some space here
                  const SizedBox(height: 25.0),

                  // Client ID input field
                  _buildClientIDField(),

                  // Adding some space here
                  const SizedBox(height: 40.0),

                  // Google Sign-Up button
                  _buildGoogleSignUpButton(),

                  // Adding some space here
                  const SizedBox(height: 30.0),

                  // OR divider
                  _buildOrDivider(),

                  // Adding some space here
                  const SizedBox(height: 30.0),

                  // Email input field
                  _buildEmailField(),

                  // Adding some space here
                  const SizedBox(height: 16.0),

                  // Password input field
                  _buildPasswordField(),

                  // Adding some space here
                  const SizedBox(height: 12.0),

                  // Password security indicator
                  PasswordSecurityIndicator(
                      strength: _passwordSecurityIndicator),

                  // Adding some space here
                  const SizedBox(height: 20.0),

                  // Password validation checks
                  PasswordValidation(password: _createAccountPasswordString),

                  // Adding some space here
                  const SizedBox(height: 16.0),

                  // Confirm password input field
                  _buildConfirmPasswordField(),

                  // Adding some space here
                  const SizedBox(height: 16.0),

                  // Next button
                  _buildNextButton(),

                  // Adding some space here
                  const SizedBox(height: 30.0),

                  // Login option
                  _buildLoginOption(),

                  // Adding some space here
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  /// Builds the Client ID input field.
  Widget _buildClientIDField() => Container(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Client ID',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'Titillium Web'),
              ),
              const Spacer(),
              GestureDetector(
                child: Container(
                  color: Colors.transparent,
                  child: const Row(
                    children: [
                      Text(
                        'What is my Client ID?',
                        style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 157, 157, 157),
                            fontFamily: 'Titillium Web'),
                      ),
                      SizedBox(width: 5),
                      Icon(
                        Icons.help_outline_rounded,
                        color: Color(0xFF3199DD),
                        size: 18,
                      ),
                    ],
                  ),
                ),
                onTap: () => CustomAlertDialog.showAlertDialog(
                  context,
                  'Client ID',
                  'Your Client ID Number (CID) is an 8 digit numeric identification code. You will receive an email containing your CID that is specific to your account. Do not share it with anyone. If you have yet to receive your CID, please reach out to melinda@agqconsulting.com for assistance.',
                  icon: const Icon(Icons.numbers_rounded,
                      color: Color(0xFF3199DD)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          TextField(
            controller: _clientIDController,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
            decoration: InputDecoration(
              hintText: 'Enter your client ID',
              hintStyle: const TextStyle(
                color: Color.fromARGB(255, 122, 122, 122),
                fontFamily: 'Titillium Web',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 27, 123, 201),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 14,
              ),
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              setState(() {
                _cid = value;
              });
            },
          ),
        ],
      ),
    );

  /// Builds the Google Sign-Up button.
  Widget _buildGoogleSignUpButton() => GestureDetector(
      onTap: _isButtonEnabled
          ? () async {
              await GoogleAuthService().signUpWithGoogle(
                context,
                _clientIDController.text,
              );
            }
          : () {
              CustomAlertDialog.showAlertDialog(
                context,
                'Please enter your CID',
                'We need your CID to authenticate with Google. Please enter your CID to continue.',
              );
            },
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color.fromARGB(255, 30, 75, 137),
            width: 4,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.google,
              color: Colors.blue,
            ),
            SizedBox(width: 15),
            Text(
              'Sign up with Google',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web'),
            ),
          ],
        ),
      ),
    );

  /// Builds the OR divider.
  Widget _buildOrDivider() => Row(
      children: [
        Expanded(
          child: Container(
            height: 3,
            color: const Color.fromARGB(255, 122, 122, 122),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'OR',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
                fontFamily: 'Titillium Web'),
          ),
        ),
        Expanded(
          child: Container(
            height: 3,
            color: const Color.fromARGB(255, 122, 122, 122),
          ),
        ),
      ],
    );

  /// Builds the Email input field.
  Widget _buildEmailField() => Container(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Email',
            style: TextStyle(
                fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
          ),
          const SizedBox(height: 10.0),
          TextField(
            controller: _emailController,
            style: const TextStyle(
                fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: const TextStyle(
                  color: Color.fromARGB(255, 122, 122, 122),
                  fontFamily: 'Titillium Web'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide:
                    const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            ),
            onChanged: (value) {
              setState(() {
                _email = value;
              });
            },
          ),
        ],
      ),
    );

  /// Builds the Password input field.
  Widget _buildPasswordField() => Container(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Password',
            style: TextStyle(
                fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
          ),
          const SizedBox(height: 10.0),
          TextField(
            controller: _createAccountPasswordController,
            style: const TextStyle(
                fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
            decoration: InputDecoration(
              hintText: 'Create a password',
              hintStyle: const TextStyle(
                  color: Color.fromARGB(255, 122, 122, 122),
                  fontFamily: 'Titillium Web'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide:
                    const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _hidePassword = !_hidePassword;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Icon(
                    _hidePassword
                        ? Icons.remove_red_eye_outlined
                        : Icons.remove_red_eye_rounded,
                    size: 25,
                    color: const Color.fromARGB(255, 154, 154, 154),
                  ),
                ),
              ),
            ),
            obscureText: _hidePassword,
            onChanged: _updateFields,
          ),
        ],
      ),
    );

  /// Builds the Confirm Password input field.
  Widget _buildConfirmPasswordField() => Container(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Confirm Password',
            style: _passwordSecurityIndicator == 4
                ? const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'Titillium Web')
                : const TextStyle(
                    color: Color.fromARGB(255, 122, 122, 122),
                    fontFamily: 'Titillium Web'),
          ),
          const SizedBox(height: 10.0),
          TextField(
            controller: _confirmCreateAccountPasswordController,
            style: const TextStyle(
                fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: const TextStyle(
                  color: Color.fromARGB(255, 122, 122, 122),
                  fontFamily: 'Titillium Web'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide:
                    const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            ),
            obscureText: true,
            onChanged: (value) {
              setState(() {
                _confirmCreateAccountPasswordString = value;
              });
            },
            enabled: _passwordSecurityIndicator == 4,
          ),
        ],
      ),
    );

  /// Builds the Next button.
  Widget _buildNextButton() => GestureDetector(
      onTap: _doPasswordsMatch() ? () => _signUserUp() : null,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: _doPasswordsMatch()
              ? const Color.fromARGB(255, 30, 75, 137)
              : const Color.fromARGB(255, 85, 86, 87),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Next',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web'),
            ),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 15),
          ],
        ),
      ),
    );

  /// Builds the login option row.
  Widget _buildLoginOption() => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Already have an account?',
          style: TextStyle(
              fontSize: 18, color: Colors.white, fontFamily: 'Titillium Web'),
        ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const LoginPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) => child,
              ),
            );
          },
          child: const TextButton(
            onPressed: null,
            child: Text(
              'Login',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web'),
            ),
          ),
        ),
      ],
    );
}
