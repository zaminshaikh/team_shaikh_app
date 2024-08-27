// ignore_for_file: library_private_types_in_public_api

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/utilities.dart';



// Making a StatefulWidget representing the Create Account page
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

// Create an instance of the state for the CreateAccountPage
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

// Making a State class for the CreateAccountPage
class _CreateAccountPageState extends State<CreateAccountPage> {
  // Boolean to switch password visibility, init as true
  bool _hidePassword = true;
  late DatabaseService _databaseService; 

  // User inputs
  String _cid = '';
  String _email = '';
  String _createAccountPasswordString = '/';
  String _confirmCreateAccountPasswordString = '';
   /// Password security indicator level
  int _passwordSecurityIndicator = 0;

  // Text editing controllers for user inputs
  final TextEditingController _clientIDController = TextEditingController();
  final TextEditingController _createAccountEmailController = TextEditingController();
  final TextEditingController _createAccountPasswordController = TextEditingController();
  final TextEditingController _confirmCreateAccountPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Signs up the user and handles email verification.
  ///
  /// This method creates a new user account using the provided email and password, deleting any users currently in the buffer.
  /// This is done to prevent any issues with the user's email being already in use (Special case if user clicks out of the dialog box).
  /// It then sends an email verification link to the user's email address.
  /// After successful email verification, the user is linked with its CID in Cloud Firestore.
  /// Finally, the user is navigated to the dashboard page.
  ///
  /// Parameters:
  /// - [context]: The build context of the current widget.
  ///
  /// Throws:
  /// - [FirebaseAuthException]: If there is an error with Firebase authentication.
  /// - [Exception]: If there is an error signing the user in.
  ///
  /// Example usage:
  /// ```dart
  /// _signUserUp(context);
  /// ```
  void _signUserUp(BuildContext context) async {
    // Delete any users currently in the buffer
    if (FirebaseAuth.instance.currentUser != null) {
      log('create_account.dart: User email: ${FirebaseAuth.instance.currentUser!.email}'); 
      try {
        await FirebaseAuth.instance.currentUser!.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          await FirebaseAuth.instance.signOut();
        } else {
          log('create_account.dart: Error: $e', stackTrace: StackTrace.current);
        }
      }
      log('create_account.dart: User after delete: ${FirebaseAuth.instance.currentUser ?? 'deleted'}'); // Confirms delete
    }  
    try {
      // Create a new UserCredential from Firebase with given details
      UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _createAccountEmailController.text,
          password: _createAccountPasswordController.text,
      );
      
      // Null check
      if (userCredential.user == null) 
      {
        log('create_account.dart: ERROR: userCredential.user is null.');
        throw FirebaseAuthException(code:'operation-not-allowed');
      }
      
      log('create_account.dart: UserCredential created: ${userCredential.user!.uid}. In buffer.');

      // Create a new database service for our new user
      _databaseService = DatabaseService.withCID(userCredential.user!.uid, _cid);
      
      // If the user inputs a CID that is not in the database or is already linked to a user, show an error dialog and return.
      if (! (await _databaseService.docExists(_cid)) ){
        if (!mounted) {return;}
        await CustomAlertDialog.showAlertDialog(context, 'Error', 'There is no record of the Client ID $_cid in the database. Please contact support or re-enter your Client ID.');
        await FirebaseAuth.instance.currentUser?.delete();
        log('create_account.dart: No document for _cid: $_cid.');
        return;
      } else if (await _databaseService.docLinked(_cid)) {
        if (!mounted) {return;}
        await CustomAlertDialog.showAlertDialog(context, 'Error', 'User already exists for given Client ID $_cid. Please log in instead.');
        await FirebaseAuth.instance.currentUser?.delete();
        log('create_account.dart: User already exists for given _cid $_cid.');
        return;
      }

      // Send the email verification
      await FirebaseAuth.instance.currentUser!.sendEmailVerification();

      // Display email verification dialog
      if (!mounted) {return;}
      await showDialog(
        context: context,
        builder: (BuildContext context) => _emailVerificationDialog(),
      );
      
    } on FirebaseAuthException catch (e) {
      if (!mounted) {return;}
      // Handle FirebaseAuth exceptions and display appropriate error messages
      handleFirebaseAuthException(context, e);
    } catch (e) {
      log('create_account.dart: Error signing user in: $e', stackTrace: StackTrace.current);
      await FirebaseAuth.instance.currentUser?.delete();
    }
  }

  

  Dialog _emailVerificationDialog() => Dialog(
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
            height: 200, // specify a fixed height
            width: 200, // specify a fixed width
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
            onPressed: () async {

              User? user = FirebaseAuth.instance.currentUser;
              await user?.reload(); // Update to most current information
              // await Future.delayed(const Duration(seconds: 1)); // Add a delay 
              user = FirebaseAuth.instance.currentUser; // Get the user object again after the delay

              if (user != null && user.emailVerified) {
                String uid = user.uid;
                // Link the UID to CID
                await _databaseService.linkNewUser(user.email!);
                log('create_account.dart: User $uid connected to Client ID $_cid');

                if (!mounted) {return;} // async gap widget mounting check
                await CustomAlertDialog.showAlertDialog(context, 'Success', 'Email verified successfully.', icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green));
                if (!mounted) {return;} 
                await Navigator.pushReplacement(context, PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) => const DashboardPage(),
                  transitionDuration: const Duration(seconds: 0),
                ));
                } else {
                if (!mounted) {return;} // async gap widget mounting check
                await CustomAlertDialog.showAlertDialog(context, 'Error', 'Email not verified. Please check your inbox for the verification link.', icon: const Icon(Icons.not_interested_rounded, color: Colors.red));
              }
            },
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

  /// Updates the password security indicator based on the conditions met by the _createAccountPasswordString.
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
    if (conditionsMet == 0) {
      _passwordSecurityIndicator = 0;
    } else if (conditionsMet == 1) {
      _passwordSecurityIndicator = 1;
    } else if (conditionsMet == 2) {
      _passwordSecurityIndicator = 2;
    } else if (conditionsMet == 3) {
      _passwordSecurityIndicator = 3;
    } else if (conditionsMet == 4) {
      _passwordSecurityIndicator = 4;
    }

  }

  /// Updates the [_createAccountPasswordString] and sets the value of [createAccountPasswordController.text].
  void _updateCreateAccountPasswordString(String value) {
    setState(() {
      _createAccountPasswordString = value;
      _createAccountPasswordController.text = value;
    });
  }

  /// Updates the password string and security indicator.
  void _updateFields(String value) {
    _updateCreateAccountPasswordString(value);
    _updatePasswordSecurityIndicator();
  }

  
  /// Handles [FirebaseAuthException] and displays an error dialog with the appropriate error message.
  ///
  /// The [context] parameter is the [BuildContext] of the current widget.
  /// The [e] parameter is the [FirebaseAuthException] that occurred.
  void handleFirebaseAuthException(BuildContext context, FirebaseAuthException e) {
    // Log the error message and stack trace
    log('create_account.dart:Error signing user in: $e', stackTrace: StackTrace.current);

    String errorMessage = 'Failed to sign up. Please try again.';

    // Check the error code and set the appropriate error message
    switch (e.code) {
      case 'email-already-in-use':
        errorMessage = 'Email $_email is already in use. Please use a different email.';
        log('create_account.dart:$e: Email is already connected to a different _cid.');
        break;
      case 'document-not-found':
        errorMessage = 'There is no record of the Client ID $_cid in the database. Please contact support or re-enter your Client ID.';
        log('create_account.dart:No document for _cid: $_cid');
        break;
      case 'user-already-exists':
        errorMessage = 'User already exists for given Client ID $_cid. Please log in instead.';
        log('create_account.dart:$e');
        break;
      case 'invalid-email':
        errorMessage = '"$_email is not a valid email format. Please try again';
        log('create_account.dart:$e');
      default:
        log('create_account.dart:FirebaseAuthException: $e');
    }    

    // Show an error dialog with the error message
    CustomAlertDialog.showAlertDialog(context, 'Error', errorMessage, icon: const Icon(Icons.error, color: Colors.red,));
  }
  
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
                    AppColors.defaultBlue500, // Start color
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

                  
  Padding(padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
              // Text widget to display "Create An Account"                
            const Text(
              'Create An Account',
      
      // TextStyle to define text appearance
              style: TextStyle(
                fontSize: 26, 
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontFamily: 'Titillium Web'
              ),
            ),
      
      // Adding some space here
            const SizedBox(height: 25.0),
      
      // Container to hold the client ID text box with its own title
            Container(
              
      // Adding some padding for this text box
              padding: const EdgeInsets.all(4.0),
      
      // Making a column to arrange the client ID text box with its title vertically
              child: Column(
      
      // Stretching the client ID text box with its title to fill the column to give the text box width
                crossAxisAlignment: CrossAxisAlignment.stretch,
      
      // Defining the children (client ID text box with its title) 
                children: [
      
      // Text widget to display "Client ID"                
                  Row(
                    children: [
                      const Text(
                        'Client ID',
                        
                            // TextStyle to define text appearance
                        style: TextStyle(
                          fontSize: 16, 
                          color: Colors.white, 
                          fontFamily: 'Titillium Web'
                          ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        child: Container(
                          color: Colors.transparent,
                          child: const Row(
                            children: [
                              Text(
                                'What is my Client ID?',
                                    // TextStyle to define text appearance
                                style: TextStyle(
                                  fontSize: 16, 
                                  color: Color.fromARGB(255, 157, 157, 157), 
                                  fontFamily: 'Titillium Web'
                                  ),
                              ),
                              SizedBox(width: 5),
                              Icon(
                                Icons.help_outline_rounded, color: AppColors.defaultBlue300, size: 18,
                              ),
                            ],
                          ),
                        ),
                        onTap: () => 
                          CustomAlertDialog.showAlertDialog(context, 
                          'Client ID', 
                          'Your Client ID Number (CID) is an 8 digit numeric identification code. You will receive an email containing your CID that is specific to your account. Do not share it with anyone. If you have yet to receive your CID, please reach out to melinda@agqconsulting.com for assistance.',
                          icon: const Icon(Icons.numbers_rounded, color: AppColors.defaultBlue300),
                        ),
                      ),
                    ],
                  ),
      
      // Adding some space here
                  const SizedBox(height: 10.0),                    
      
      // TextField widget for the user to Enter their client ID
                  TextField(
      
      // TextStyle to define text appearance of the users input
                    style: const TextStyle(
                      fontSize: 16, 
                      color: Colors.white, 
                      fontFamily: 'Titillium Web'
                    ), 
      
      // InputDecoration for styling the input field
                    decoration: InputDecoration(
                              
      // Placeholder text to display 'Enter your client ID'
                      hintText: 'Enter your client ID', 
      
      // Styling the placeholder text
                      hintStyle: const TextStyle(
                        color: Color.fromARGB(255, 122, 122, 122), 
                        fontFamily: 'Titillium Web'
                      ),
      
      // Styling the border for the input field and giving it a rounded look
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
      
      // Changing the color of the border when the user interacts with it
                      focusedBorder: 
                        OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)), // Border color
                        ),
      
      // Adding some padding so the input is spaced proportionally                         
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14), // Padding for input content
                    ),
                    onChanged: (value) {
                      setState(() {
                        _clientIDController.text = value;
                        _cid = value;
                      });
                    },
                  ),
                ],
              ),
            ),
                          
      // Adding some space here
            const SizedBox(height: 16.0),
        
      // Container to hold the Email text box with its own title
            Container(
      
      // Adding some padding for this text box
              padding: const EdgeInsets.all(4.0),
      
      // Making a column to arrange the email text box with its title vertically
              child: Column(
      
      // Stretching the email text box with its title to fill the column to give the text box width
                crossAxisAlignment: CrossAxisAlignment.stretch,
      
      // Defining the children (email text box with its title) 
                children: [
      
      // Text widget to display "Email"                
                  const Text(
                    'Email',
                    
      // TextStyle to define text appearance
                    style: TextStyle(
                      fontSize: 16, 
                      color: Colors.white, 
                      fontFamily: 'Titillium Web'
                    ),
                  ),
      
      // Adding some space here
                  const SizedBox(height: 10.0),                    
      
      // TextField widget for the user to Enter their email
                  TextField(
      
      // TextStyle to define text appearance of the user's input
                    style: const TextStyle(
                      fontSize: 16, 
                      color: Colors.white, 
                      fontFamily: 'Titillium Web'
                    ), 
      
      // InputDecoration for styling the input field
                    decoration: InputDecoration(
      
      // Placeholder text to display 'Enter your email'
                      hintText: 'Enter your email', 
      
      // Styling the placeholder text
                        hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 122, 122, 122), 
                          fontFamily: 'Titillium Web'
                        ),
      
      // Styling the border for the input field and giving it a rounded look
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
      
      // Changing the color of the border when the user interacts with it
                      focusedBorder: 
                        OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
                        ),
      
      // Adding some padding so the input is spaced proportionally                         
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14), // Padding for input content
                    ),
      
      // Update the emailString when the value inputted from the user
                    onChanged: (value){
                      setState(() {
                        _email = value;
                        _createAccountEmailController.text = value;
                      });
                    },
      
      // Closing the properties for the textfield
                  ),
                ],
              ),
            ),
                      
      // Adding some space here
            const SizedBox(height: 16.0),
      
      // Container to hold the Password text box with its own title
            Container(
      
      // Adding some padding for this text box
              padding: const EdgeInsets.all(4.0),
      
      // Making a column to arrange the password text box with its title vertically
              child: Column(
      
      // Stretching the password text box with its title to fill the column to give the text box width
                crossAxisAlignment: CrossAxisAlignment.stretch,
      
      // Defining the children (password text box with its title)
                children: [
      
      // Text widget to display "Password"
                  const Text(
                    'Password',
                    
      // TextStyle to define text appearance
                    style: TextStyle(
                      fontSize: 16, 
                      color: Colors.white, 
                      fontFamily: 'Titillium Web'
                    ),
                  ),
      
      // Adding some space here
                  const SizedBox(height: 10.0),
      
      // TextField widget for the user to create a password
                  TextField(
      
      // TextStyle to define text appearance of the user's input
                    style: const TextStyle(
                      fontSize: 16, 
                      color: Colors.white, 
                      fontFamily: 'Titillium Web'
                    ), 
      
      // InputDecoration for styling the input field
                    decoration: InputDecoration(
      
      // Placeholder text to display 'Create a password'
                      hintText: 'Create a password', 
      
      // Styling the placeholder text
                      hintStyle: const TextStyle(
                        color: Color.fromARGB(255, 122, 122, 122), 
                        fontFamily: 'Titillium Web'
                      ),
      
      // Styling the border for the input field and giving it a rounded look
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
      
      // Changing the color of the border when the user interacts with it
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
                      ),
      
      // Adding some padding so the input is spaced proportionally                         
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      
      // Adding an eye icon to toggle password visibility
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
      
      // Adding some padding for the icon
                        child: Padding(
                          padding: const EdgeInsets.all(0.0),
      
      // Icon widget to toggle password visibility
                          child: Icon(
                            _hidePassword ? Icons.remove_red_eye_outlined : Icons.remove_red_eye_rounded,
                            size: 25,
                            color: const Color.fromARGB(255, 154, 154, 154),
      
      // Closing the eye Icon properties
                          ),
                        ),
                      ),
                    ),
                    obscureText: _hidePassword,
                    onChanged: _updateFields,
                  ),
                ],
              ),
            ),
      
      // Adding some space here
            const SizedBox(height: 12.0),
      
      // Making a row of rounded rectangles for the password security indicator
          Row(
      
      // Splitting the rectangles in different parts by assigning them as children
            children: [
      
      // Making the first 3 rectangles in the row
              Row(
                  children:
                  List.generate(
                    3,
      
      // Styling the rectangles
                    (index) => Container(
      
      // Setting the width and height for the rectangles
                      width: 28, 
                      height: 5.5,
      
      // Making a margin between rectangles
                      margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.01),
      
      // Making conditional statements to change the color of the rectangles based on the security of the password
                      decoration: BoxDecoration(
                        color: _passwordSecurityIndicator == 1
                            ? const Color.fromARGB(255, 149, 28, 28)
                            : (_passwordSecurityIndicator == 2 || _passwordSecurityIndicator == 3)
                                ? const Color.fromARGB(255, 219, 195, 60)
                                : (_passwordSecurityIndicator == 4)
                                    ? const Color.fromARGB(255, 47, 134, 47)
                                    : const Color.fromARGB(255, 100, 116, 139),
                        borderRadius: BorderRadius.circular(10.0),
      
      // Closing properties for the first 3 rectangles in the row
                      ),
                    ),
                  ),
                ),
      
                // Next 2 rectangles in the row
                Row(
                  children: List.generate(
                    2,
                    (index) => Container(
                      width: 28,
                      height: 5.5,
                      margin: const EdgeInsets.symmetric(horizontal: 4.4),
                      decoration: BoxDecoration(
                        color: _passwordSecurityIndicator == 1
                            ? const Color.fromARGB(255, 100, 116, 139)
                            : (_passwordSecurityIndicator == 2 || _passwordSecurityIndicator == 3)
                                ? const Color.fromARGB(255, 219, 195, 60)
                                : (_passwordSecurityIndicator == 4)
                                    ? const Color.fromARGB(255, 47, 134, 47)
                                    : const Color.fromARGB(255, 100, 116, 139),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
      
                // Next 2 rectangles in the row
                Row(
                  children: List.generate(
                    2,
                    (index) => Container(
                      width: 28,
                      height: 5.5,
                      margin: const EdgeInsets.symmetric(horizontal: 4.4),
                      decoration: BoxDecoration(
                        color: _passwordSecurityIndicator == 2
                            ? const Color.fromARGB(255, 100, 116, 139)
                            : (_passwordSecurityIndicator == 3)
                                ? const Color.fromARGB(255, 219, 195, 60)
                                : (_passwordSecurityIndicator == 4)
                                    ? const Color.fromARGB(255, 47, 134, 47)
                                    : const Color.fromARGB(255, 100, 116, 139),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
      
      // Making the last 3 rectangles in the row
              Row(
                  children:
                  List.generate(
                    3,
      
      // Styling the rectangles
                    (index) => Container(
      
      // Setting the width and height for the rectangles
                      width: 25, 
                      height: 5.5,
      
      // Making a margin between rectangles
                      margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.01),
      
      // Making conditional statements to change the color of the rectangles based on the security of the password
                      decoration: BoxDecoration(
                        color: _passwordSecurityIndicator == 4
                          ? const Color.fromARGB(255, 47, 134, 47)
                          : const Color.fromARGB(255, 100, 116, 139),
                        borderRadius: BorderRadius.circular(10.0),
      
      // Closing properties for the first 3 rectangles in the row
                      ),
                    ),
                  ),
                ),
      
      // Closing the row of rounded rectangles for the password security indicator
            ],
          ),
        
      // Adding some space here
            const SizedBox(height: 20.0),
        
      // Making a container to display password 8 character validation status
            Container(
      
      // Adding some padding to the icon and text
              padding: const EdgeInsets.all(4.0), 
      
      // Making a row holding the icon and text indicating password length validation
              child: Row(
                children: [
                  // Conditional statement that changes the icon to a green checkmark when the password is at least 8 characters
                  _createAccountPasswordString.length > 7
                      ? const Icon(Icons.check_rounded, size: 30, color: Color.fromARGB(255, 61, 130, 63)) 
                      : const Icon(Icons.circle_outlined, size: 30, color: Color.fromARGB(255, 100, 116, 139)), 
      
      // Adding some space here
                  const SizedBox(width: 10.0),
      
      // Text widget to display 'At least 8 characters'
                  const Text(
                    'At least 8 characters',
      
      // TextStyle to define text appearance
                    style: TextStyle(
                      fontSize: 16, 
                      color: Colors.white, 
                      fontFamily: 'Titillium Web'
                    ),
      // Closing properties for the password length validation status
                  ),
                ],
              ),
            ),
      
      // Adding some space here
            const SizedBox(height: 16.0),
      
      // Container for displaying whether the password contains at least one digit
            Container(
      
      // Adding padding to the icon and text
              padding: const EdgeInsets.all(4.0),
      
      // Row holding the icon and text indicating the presence of at least one digit in the password
              child: Row(
                children: [
                  // Conditional statement to change the icon to a green checkmark when the password contains at least one digit
                  _createAccountPasswordString.contains(RegExp(r'\d'))
                    ? const Icon(Icons.check_rounded, size: 30, color: Color.fromARGB(255, 61, 130, 63)) // Green checkmark for valid condition
                    : const Icon(Icons.circle_outlined, size: 30, color: Color.fromARGB(255, 100, 116, 139)), // Outlined circle for invalid condition
      
      // Adding some space here
                  const SizedBox(width: 10.0),
      
      // Text widget to display '1 digit'
                  const Text(
                    '1 digit',
      
      // TextStyle to define text appearance
                    style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
                  ),
      
      // Closing properties for the 1 digit condition display
                ],
              ),
            ),
              
      // Adding some space here
            const SizedBox(height: 16.0),
      
      // Container for displaying whether the password contains at least one uppercase character
            Container(
      
      // Adding padding to the icon and text
              padding: const EdgeInsets.all(4.0),
      
      // Row holding the icon and text indicating the presence of at least one uppercase character in the password
              child: Row(
                children: [
                  // Conditional statement to change the icon to a green checkmark when the password contains at least one uppercase character
                  _createAccountPasswordString.contains(RegExp(r'[A-Z]'))
                    ? const Icon(Icons.check_rounded, size: 30, color: Color.fromARGB(255, 61, 130, 63)) // Green checkmark for valid condition
                    : const Icon(Icons.circle_outlined, size: 30, color: Color.fromARGB(255, 100, 116, 139)), // Outlined circle for invalid condition
      
      // Adding some space here
                  const SizedBox(width: 10.0),
      
      // Text widget to display '1 uppercase character'
                  const Text(
                    '1 uppercase character',
      
      // TextStyle to define text appearance
                    style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
                  ),
                  
      // Closing properties for the uppercase character condition display
                ],
              ),
            ),
      
      // Adding some space here
            const SizedBox(height: 16.0),
        
      // Container for displaying whether the password contains at least one lowercase character
            Container(
      
      // Adding padding to the icon and text
              padding: const EdgeInsets.all(4.0),
      
      // Row holding the icon and text indicating the presence of at least one lowercase character in the password
              child: Row(
                children: [
                  // Conditional statement to change the icon to a green checkmark when the password contains at least one lowercase character
                  _createAccountPasswordString.contains(RegExp(r'[a-z]'))
                    ? const Icon(Icons.check_rounded, size: 30, color: Color.fromARGB(255, 61, 130, 63)) // Green checkmark for valid condition
                    : const Icon(Icons.circle_outlined, size: 30, color: Color.fromARGB(255, 100, 116, 139)), // Outlined circle for invalid condition
      
      // Adding some space here
                  const SizedBox(width: 10.0),
      
      // Text widget to display '1 lowercase character'
                  const Text(
                    '1 lowercase character',
      
      // TextStyle to define text appearance
                    style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
                  ),
      // Closing properties for the lowercase character condition display
                ],
              ),
            ),
        
      // Adding some space here
            const SizedBox(height: 16.0),
        
      // Container for the confirmation password section
            Container(
              padding: const EdgeInsets.all(4.0), // Adjust padding as needed
      
      // Column to arrange child widgets vertically
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
      
      // Text widget for displaying "Confirm Password"
                  Text(
                    'Confirm Password',
                    // TextStyle conditionally set based on password security indicator
                    style: _passwordSecurityIndicator == 4
                        ? const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web') // Style for valid condition
                        : const TextStyle(color: Color.fromARGB(255, 122, 122, 122), fontFamily: 'Titillium Web'), // Style for invalid condition
                  ),
                  
      // Adding some space here
                  const SizedBox(height: 10.0),
      
      // TextField widget for entering and confirming the password
                  TextField(
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
      
      // InputDecoration for customizing the appearance of the text field
                    decoration: InputDecoration(
      
      // Hint text to guide the user for entering the password
                      hintText: 'Enter your password',
      
      // TextStyle for the hint text
                      hintStyle: const TextStyle(color: Color.fromARGB(255, 122, 122, 122), fontFamily: 'Titillium Web'),
      
      // Border styling for the text field
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
      
      // Styling for the border when the text field is focused
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
                      ),
      
      // Padding inside the text field content area
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    ),
      
      // Hide entered text 
                    obscureText: true, 
      
      // onChanged callback to update the confirmation password string
                    onChanged: (value) {
                      setState(() {
                        _confirmCreateAccountPasswordString = value;
                        _confirmCreateAccountPasswordController.text = value;
                      });
                    },
      
                    // Enable the text field based on the password security indicator
                    enabled: _passwordSecurityIndicator == 4,
      
      // Closing properties for the Confirm Password textfield
                  ),
                ],
              ),
            ),
                      
      // Adding some space here
            const SizedBox(height: 16.0),
      
            // Making a "Next" button
            GestureDetector(
      
              // Execute onTap
              onTap: () => _signUserUp(context),
      
              // Container holding the "Next" button
              child: Container(
                height: 50,
      
                // Decoration based on password match status
                decoration: BoxDecoration(
                  color: _createAccountPasswordString == _confirmCreateAccountPasswordString
                      ? const Color.fromARGB(255, 30, 75, 137) // Color when passwords match
                      : const Color.fromARGB(255, 85, 86, 87),  // Color when passwords don't match
                  borderRadius: BorderRadius.circular(25),
                ),
      
                // Row to contain "Next" text and arrow icon
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next',
      
                      // TextStyle to define text appearance
                      style: TextStyle(
                        fontSize: 18, 
                        color: Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontFamily: 'Titillium Web'
                      ),
                    ),
      
                    // Adding some space here
                    SizedBox(width: 10),
      
                    // Adding a white arrow
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 15),
      
                    // Closing properties for the Next button
                  ],
                ),
              ),
            ),
      
      // Adding some space here
            const SizedBox(height: 30.0),
      
      // Row widget containing text and a GestureDetector for navigation to the login screen
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
      
      // Children widgets within the row
              children: [
      
      // Text widget indicating the presence of an existing account
                const Text(
                  'Already have an account?',
      
      // TextStyle to define text appearance
                  style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'Titillium Web'),
                ),
      
      // GestureDetector for handling taps on the "Login" text
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
      
      // onTap navigation to the login screen
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                      ),
                    );
                  },
      
      // TextButton widget styled as a link for navigating to the login screen
                  child: const TextButton(
                    onPressed: null, // Set onPressed to null or add your logic inside the GestureDetector
                    child: Text(
                      'Login',
      
      // TextStyle to define text appearance
                      style: TextStyle(
                        fontSize: 18, 
                        color: Colors.blue, 
                        fontWeight: FontWeight.bold, 
                        fontFamily: 'Titillium Web'
                      ),
      
      // Closing the Message properties
                    ),
                  ),
                ),
              ],
            ),
      
      // Adding some space here
            const SizedBox(height: 20.0),

      ],
    ),
  ),
      
      // Close all properties
          ],
        ),
      ),
    );
  }

