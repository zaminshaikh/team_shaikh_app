import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:team_shaikh_app/alert_dialog.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/screens/database.dart';

// StatefulWidget representing the Create Account page
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

// Making a State class for the CreateAccountPage
class _CreateAccountPageState extends State<CreateAccountPage> {
  // Boolean to switch password visibility, init as true
  bool hidePassword = true;

  // Boolean to track email verification status
  bool isEmailVerified = false;

  // User inputs
  String cid = '';
  String email = '';
  String createAccountPasswordString = '/';
  String confirmcreateAccountPasswordString = '';

  // Text editing controllers for user inputs
  TextEditingController clientIDController = TextEditingController();
  TextEditingController createAccountEmailController = TextEditingController();
  TextEditingController createAccountPasswordController =
      TextEditingController();
  TextEditingController confirmcreateAccountPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Check and wait for email verification status
  /// Checks the email verification status of the current user.
  ///
  /// This method continuously checks if the user's email has been verified.
  /// It uses the [FirebaseAuth] instance to get the current user and reloads
  /// the user's data. If the user is not null and their email is verified,
  /// it logs "Email verified" and returns true. Otherwise, it logs
  /// "Email not verified yet. Waiting 5 seconds..." and waits for 5 seconds
  /// before checking again.
  ///
  /// Returns a [Future<bool>] that resolves to true when the user's email
  /// is verified.
  Future<bool> checkEmailVerificationStatus() async {
    while (true) {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      if (user != null && user.emailVerified) {
        log("Email verified");
        return true;
      }
      log("Email not verified yet. Waiting 5 seconds...");
      await Future.delayed(Duration(seconds: 5));
    }
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
  /// signUserUp(context);
  /// ```
  void signUserUp(BuildContext context) async {
    // Delete any users currently in the buffer
    FirebaseAuth.instance.currentUser?.delete();
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: createAccountEmailController.text,
        password: createAccountPasswordController.text,
      );
      log("UserCredential created: $userCredential. In buffer.");

      // Create a new database service for our new user
      DatabaseService databaseService = DatabaseService(cid, userCredential.user!.uid);
      
      // If the user inputs a CID that is not in the database or is already linked to a user, show an error dialog and return.
      if (! (await databaseService.docExists(cid)) ){
        CustomAlertDialog.showAlertDialog(context, "Error", "There is no record of the Client ID $cid in the database. Please contact support or re-enter your Client ID.");
        FirebaseAuth.instance.currentUser?.delete();
        log("No document for cid: $cid.");
        return;
      } else if (await databaseService.docLinked(cid)) {
        CustomAlertDialog.showAlertDialog(context, "Error", "User already exists for given Client ID $cid. Please log in instead.");
        FirebaseAuth.instance.currentUser?.delete();
        log("User already exists for given cid $cid.");
        return;
      }

      await FirebaseAuth.instance.currentUser!.sendEmailVerification();

      // Display email verification dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return emailVerificationDialog();
        },
      );

      if (await checkEmailVerificationStatus()) {
        // Update user data in the database
        if (userCredential.user != null) {
          User user = userCredential.user!;
          String uid = user.uid;

          await databaseService.linkNewUser(user.email!);

          log("User $uid connected to Client ID $cid");
        } else {
          log("User is null");
          throw FirebaseAuthException(code: "user-null", message: "User is null");
        }
        // Navigate to the dashboard after successful email verification
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                DashboardPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return child;
            },
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle FirebaseAuth exceptions and display appropriate error messages
      handleFirebaseAuthException(context, e);
      FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      log("Error signing user in: $e", stackTrace: StackTrace.current);
      FirebaseAuth.instance.currentUser?.delete();
    }
  }

  Dialog emailVerificationDialog() {
    return Dialog(
            backgroundColor: const Color.fromARGB(255, 37, 58, 86),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              height: 500,
              width: 1000,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  const Text(
                    'ICON ART',
                    style: TextStyle(
                      fontSize: 40,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                  const SizedBox(height: 80),
                  const Text(
                    'Verify your Email Address',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  const Center(
                    child: Text(
                      "You will recieve an Email with a link to verify your email. Please check your inbox.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  ),

                  const SizedBox(height: 70),

                  GestureDetector(
                    onTap: () {
                      if (isEmailVerified) {
                        showDialog(
                          context: context,
                          barrierDismissible: false, // Prevents the dialog from being dismissed by tapping outside
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                "Verifying Email",
                                style: TextStyle(
                                  fontFamily: 'Titillium Web',
                                  color: Colors.blue,
                                ),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 10),
                                  Text(
                                    "Please wait...",
                                    style: TextStyle(
                                      fontFamily: 'Titillium Web',
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );

                        // Navigate to the dashboard or perform desired action
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => DashboardPage(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return child;
                            },
                          ),
                        );
                      } else {
                        // Show a message or take appropriate action for unverified email
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                "Error",
                                style: TextStyle(
                                  fontFamily: 'Titillium Web',
                                  color: Colors.blue, // You can change this to your desired color
                                ),
                              ),
                              content: Text(
                                "Email not verified. Please check your inbox for the verification link.",
                                style: TextStyle(
                                  fontFamily: 'Titillium Web',
                                  color: Colors.blue, // You can change this to your desired color
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    "OK",
                                    style: TextStyle(
                                      fontFamily: 'Titillium Web',
                                      color: Colors.blue, // You can change this to your desired color
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
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
                      child: Center(
                        child: Text(
                          "Continue",
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
  

  /// Password security indicator level
  int passwordSecurityIndicator = 0;


  /// Updates the password security indicator based on the conditions met by the createAccountPasswordString.
  void updatePasswordSecurityIndicator() {
    int conditionsMet = 0;

    if (createAccountPasswordString.length > 7) {
      conditionsMet++;
    }

    if (createAccountPasswordString.contains(RegExp(r'\d'))) {
      conditionsMet++;
    }

    if (createAccountPasswordString.contains(RegExp(r'[A-Z]'))) {
      conditionsMet++;
    }

    if (createAccountPasswordString.contains(RegExp(r'[a-z]'))) {
      conditionsMet++;
    }

    // Update passwordSecurityIndicator based on the number of conditions met
    if (conditionsMet == 0) {
      passwordSecurityIndicator = 0;
    } else if (conditionsMet == 1) {
      passwordSecurityIndicator = 1;
    } else if (conditionsMet == 2) {
      passwordSecurityIndicator = 2;
    } else if (conditionsMet == 3) {
      passwordSecurityIndicator = 3;
    } else if (conditionsMet == 4) {
      passwordSecurityIndicator = 4;
    }
  }

  /// Updates the [createAccountPasswordString] and sets the value of [createAccountPasswordController.text].
  void updatecreateAccountPasswordString(String value) {
    setState(() {
      createAccountPasswordString = value;
      createAccountPasswordController.text = value;
    });
  }

  /// Updates the password string and security indicator.
  void updateFields(String value) {
    updatecreateAccountPasswordString(value);
    updatePasswordSecurityIndicator();
  }

  // TODO: Delete exceptions for Firebase and other errors and replace with boolean error handling
  /// Handles [FirebaseAuthException] and displays an error dialog with the appropriate error message.
  ///
  /// The [context] parameter is the [BuildContext] of the current widget.
  /// The [e] parameter is the [FirebaseAuthException] that occurred.
  void handleFirebaseAuthException(BuildContext context, FirebaseAuthException e) {
    // Log the error message and stack trace
    log("Error signing user in: $e", stackTrace: StackTrace.current);

    String errorMessage = "Failed to sign up. Please try again.";

    // Check the error code and set the appropriate error message
    switch (e.code) {
      case 'email-already-in-use':
        errorMessage = "Email $email is already in use. Please use a different email.";
        log('$e: Email is already connected to a different cid.');
        break;
      case 'document-not-found':
        errorMessage = "There is no record of the Client ID $cid in the database. Please contact support or re-enter your Client ID.";
        log('No document for cid: $cid');
        break;
      case 'user-already-exists':
        errorMessage = "User already exists for given Client ID $cid. Please log in instead.";
        log('$e');
        break;
      default:
        log('FirebaseAuthException: $e');
    }    

    // Show an error dialog with the error message
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
  
  /// Builds the create account screen widget.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 40.0),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "AGQ",
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web',
                  ),
                ),
              ),

              const SizedBox(height: 60.0),

              const Text(
                "Create An Account",
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),

              const SizedBox(height: 25.0),

              // Container for the Client ID input
              Container(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Client ID",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    // TextField for entering the client ID
                    TextField(
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
                          borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      ),
                      onChanged: (value) {
                        setState(() {
                          clientIDController.text = value;
                          cid = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // Container for the Email input
              Container(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Email",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    // TextField for entering the email
                    TextField(
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Titillium Web',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 122, 122, 122),
                          fontFamily: 'Titillium Web',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      ),
                      onChanged: (value) {
                        setState(() {
                          email = value;
                          createAccountEmailController.text = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // Container for the Password input
              Container(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    // TextField for creating a password
                    TextField(
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Titillium Web',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Create a password',
                        hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 122, 122, 122),
                          fontFamily: 'Titillium Web',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Icon(
                              hidePassword ? Icons.remove_red_eye_outlined : Icons.remove_red_eye_rounded,
                              size: 25,
                              color: const Color.fromARGB(255, 154, 154, 154),
                            ),
                          ),
                        ),
                      ),
                      obscureText: hidePassword,
                      onChanged: updateFields,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12.0),

              // Row of rounded rectangles for the password security indicator
              Row(
                children: [
                  // First 3 rectangles in the row
                  Row(
                    children: List.generate(
                      3,
                      (index) => Container(
                        width: 31,
                        height: 5.5,
                        margin: const EdgeInsets.symmetric(horizontal: 4.4),
                        decoration: BoxDecoration(
                          color: passwordSecurityIndicator == 1
                              ? const Color.fromARGB(255, 149, 28, 28)
                              : (passwordSecurityIndicator == 2 || passwordSecurityIndicator == 3)
                                  ? const Color.fromARGB(255, 219, 195, 60)
                                  : (passwordSecurityIndicator == 4)
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
                        width: 31,
                        height: 5.5,
                        margin: const EdgeInsets.symmetric(horizontal: 4.4),
                        decoration: BoxDecoration(
                          color: passwordSecurityIndicator == 1
                              ? const Color.fromARGB(255, 100, 116, 139)
                              : (passwordSecurityIndicator == 2 || passwordSecurityIndicator == 3)
                                  ? const Color.fromARGB(255, 219, 195, 60)
                                  : (passwordSecurityIndicator == 4)
                                      ? const Color.fromARGB(255, 47, 134, 47)
                                      : const Color.fromARGB(255, 100, 116, 139),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40.0), // Adding some space at the end
          
              // Container for displaying password 8-character validation status
              Container(
                // Adding padding to the icon and text
                padding: const EdgeInsets.all(4.0), 

                // Row holding the icon and text indicating password length validation
                child: Row(
                  children: [
                    // Conditional statement that changes the icon to a green checkmark when the password is at least 8 characters
                    createAccountPasswordString.length > 7
                        ? const Icon(Icons.check_rounded, size: 30, color: Color.fromARGB(255, 61, 130, 63)) 
                        : const Icon(Icons.circle_outlined, size: 30, color: Color.fromARGB(255, 100, 116, 139)), 

                    // Adding space
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

              // Adding space
              const SizedBox(height: 16.0),

              // Container for displaying whether the password contains at least one digit
              Container(
                // Adding padding to the icon and text
                padding: const EdgeInsets.all(4.0),

                // Row holding the icon and text indicating the presence of at least one digit in the password
                child: Row(
                  children: [
                    // Conditional statement to change the icon to a green checkmark when the password contains at least one digit
                    createAccountPasswordString.contains(RegExp(r'\d'))
                      ? const Icon(Icons.check_rounded, size: 30, color: Color.fromARGB(255, 61, 130, 63)) // Green checkmark for valid condition
                      : const Icon(Icons.circle_outlined, size: 30, color: Color.fromARGB(255, 100, 116, 139)), // Outlined circle for invalid condition

                    // Adding space
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

              // Adding space
              const SizedBox(height: 16.0),

              // Container for displaying whether the password contains at least one uppercase character
              Container(
                // Adding padding to the icon and text
                padding: const EdgeInsets.all(4.0),

                // Row holding the icon and text indicating the presence of at least one uppercase character in the password
                child: Row(
                  children: [
                    // Conditional statement to change the icon to a green checkmark when the password contains at least one uppercase character
                    createAccountPasswordString.contains(RegExp(r'[A-Z]'))
                      ? const Icon(Icons.check_rounded, size: 30, color: Color.fromARGB(255, 61, 130, 63)) // Green checkmark for valid condition
                      : const Icon(Icons.circle_outlined, size: 30, color: Color.fromARGB(255, 100, 116, 139)), // Outlined circle for invalid condition

                    // Adding space
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

              // Adding space
              const SizedBox(height: 16.0),

              // Container for displaying whether the password contains at least one lowercase character
              Container(
                // Adding padding to the icon and text
                padding: const EdgeInsets.all(4.0),

                // Row holding the icon and text indicating the presence of at least one lowercase character in the password
                child: Row(
                  children: [
                    // Conditional statement to change the icon to a green checkmark when the password contains at least one lowercase character
                    createAccountPasswordString.contains(RegExp(r'[a-z]'))
                      ? const Icon(Icons.check_rounded, size: 30, color: Color.fromARGB(255, 61, 130, 63)) // Green checkmark for valid condition
                      : const Icon(Icons.circle_outlined, size: 30, color: Color.fromARGB(255, 100, 116, 139)), // Outlined circle for invalid condition

                    // Adding space
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

              // Adding space
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
                      "Confirm Password",
                      // TextStyle conditionally set based on password security indicator
                      style: passwordSecurityIndicator == 4
                          ? const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web') // Style for valid condition
                          : const TextStyle(color: Color.fromARGB(255, 122, 122, 122), fontFamily: 'Titillium Web'), // Style for invalid condition
                    ),
                    
                    // Adding space
                    const SizedBox(height: 10.0),

                    // TextField widget for entering and confirming the password
                    TextField(
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Titillium Web'),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: const TextStyle(color: Color.fromARGB(255, 122, 122, 122), fontFamily: 'Titillium Web'),
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
                          confirmcreateAccountPasswordString = value;
                          confirmcreateAccountPasswordController.text =value;
                        });
                      },

                      // Enable the text field based on the password security indicator
                      enabled: passwordSecurityIndicator == 4,

                      // Closing properties for the Confirm Password textfield
                    ),
                  ],
                ),
              ),

              // Adding space
              const SizedBox(height: 16.0),

              // "Next" button
              GestureDetector(
                // Execute onTap
                onTap: () => signUserUp(context),

                // Container holding the "Next" button
                child: Container(
                  height: 50,

                  // Decoration based on password match status
                  decoration: BoxDecoration(
                    color: createAccountPasswordString == confirmcreateAccountPasswordString
                        ? const Color.fromARGB(255, 30, 75, 137) // Color when passwords match
                        : const Color.fromARGB(255, 85, 86, 87),  // Color when passwords don't match
                    borderRadius: BorderRadius.circular(25),
                  ),

                  // Row to contain "Next" text and arrow icon
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Next",

                        // TextStyle to define text appearance
                        style: TextStyle(
                          fontSize: 18, 
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontFamily: 'Titillium Web'
                        ),
                      ),

                      // Adding space
                      SizedBox(width: 10),

                      // Adding a white arrow
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 15),

                      // Closing properties for the Next button
                    ],
                  ),
                ),
              ),

              // Adding space
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
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return child;
                          },
                        ),
                      );
                    },

                    // TextButton widget styled as a link for navigating to the login screen
                    child: const TextButton(
                      onPressed: null, // Set onPressed to null or add your logic inside the GestureDetector
                      child: Text(
                        "Login",

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

              // Adding space
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }
}
