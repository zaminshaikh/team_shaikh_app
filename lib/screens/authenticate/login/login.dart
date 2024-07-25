// Importing Flutter Library & Google button Library
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_shaikh_app/screens/authenticate/create_account.dart';
import 'package:team_shaikh_app/screens/authenticate/login/forgot_password.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/utilities.dart';
import 'package:team_shaikh_app/resources.dart';


// Creating a stateful widget for the Login page
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

  // Controllers to store login email and password
  final emailController = TextEditingController();
  final passwordController = TextEditingController();


// State class for the LoginPage
class _LoginPageState extends State<LoginPage> {

  // Boolean variable to set password visibility to hidden
  bool hidePassword = true;
  // Boolean variable to set the remember me checkbox to unchecked, and initializing that the user does not want the app to remember them
  bool rememberMe = false;
  
  // Sign user in method
  Future<bool> signUserIn(context) async {
    print('Attempting to sign user in...'); // Debugging output
    try {
      print('Calling FirebaseAuth to sign in with email and password...'); // Debugging output
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      print('login.dart: Signed in user ${userCredential.user!.uid}'); // Debugging output
      print('Sign in successful, proceeding to dashboard...'); // Debugging output
      return true;
    } on FirebaseAuthException catch (e) {
      print('Caught FirebaseAuthException: $e'); // Debugging output
      String errorMessage = '';
      if (e.code == 'user-not-found') {
        errorMessage = 'Email not found. Please check your email or sign up for a new account.';
        print('Error: $errorMessage'); // Debugging output
      } else {
        errorMessage = 'Error signing in. Please check your email and password. $e';
        print('Error: $errorMessage'); // Debugging output
      }
      print('Showing error dialog...'); // Debugging output
      await CustomAlertDialog.showAlertDialog(context, 'Error logging in', errorMessage);
      print('Error dialog shown, returning false...'); // Debugging output
      return false;
    } catch (e) {
      print('An unexpected error occurred: $e'); // Debugging output for any other exceptions
      return false;
    }
  }
  


  // The build method for the login screen widget
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

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

          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
          // Title for the login section
                const Text(
                  'Login to Your Account',
                  style: TextStyle(
                    fontSize: 26, 
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontFamily: 'Titillium Web'
                  ),
                ),
          // Spacing
          const SizedBox(height: 35.0),
          
          // Email input field
          Container(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 16, 
                    color: Colors.white, 
                    fontFamily: 'Titillium Web'
                  ),
                ),
                const SizedBox(height: 10.0),
                TextField(
                  controller: emailController,
                  style: const TextStyle(
                    fontSize: 16, 
                    color: Colors.white, 
                    fontFamily: 'Titillium Web'
                  ), 
                  // Input field styling
                  decoration: InputDecoration(
                    hintText: 'Enter your email', 
                    hintStyle: const TextStyle(
                      color: Color.fromARGB(255, 122, 122, 122), 
                      fontFamily: 'Titillium Web'
                    ),
                    // Border and focus styling
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  ),
                  onChanged: (value){
                    setState(() {
                      emailController.text = value;
                    });
                  },
                ),
              ],
            ),
          ),
          // Spacing
          const SizedBox(height: 16.0),
          
          // Password input field
          Container(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 16, 
                    color: Colors.white, 
                    fontFamily: 'Titillium Web'
                  ),
                ),
                const SizedBox(height: 10.0),
                TextField(
                  controller: passwordController,
                  style: const TextStyle(
                    fontSize: 16, 
                    color: Colors.white, 
                    fontFamily: 'Titillium Web'
                  ), 
                  // Input field styling with password visibility toggle
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: const TextStyle(
                      color: Color.fromARGB(255, 122, 122, 122), 
                      fontFamily: 'Titillium Web'
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
                  onChanged: (value) {
                    setState(() {
                      passwordController.text = value;
                    });
                  },
                ),
              ],
            ),
          ),
          // Spacing
          const SizedBox(height: 20.0),
          
          // Remember Me and Forgot Password section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
                  // GestureDetector(
                  //   onTap: () {
                  //     setState(() {
                  //       rememberMe = !rememberMe;
                  //     });
                  //   },
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(6.0),
                  //     child: Icon(
                  //       rememberMe ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  //       size: 24,
                  //       color: Colors.white,
                  //     ),
                  //   ),
                  // ),
                  // const Text('Remember Me',
                  //   style: TextStyle(
                  //     fontSize: 16, 
                  //     color: Colors.white, 
                  //     fontFamily: 'Titillium Web'
                  //   )
                  // ),
                  // const SizedBox(width: 100),
                  
                  // Forgot Password link
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()), // Navigate to the Log In page
                      );
                    },
                    child: const TextButton(
                      onPressed: null,
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.blue, 
                          fontFamily: 'Titillium Web'
                          ),
                      ),
                    ),
                  ),
                ],
          ),
          // Spacing
          const SizedBox(height: 40.0),
          
          // Login Button
          GestureDetector(
            onTap: () async {
              bool success = await signUserIn(context);
              if (success) {
                await Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) => const DashboardPage(),
                    transitionDuration: Duration.zero,
                  ),
                );
              }
            },
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: passwordController.text.isNotEmpty && emailController.text.isNotEmpty
                    ? const Color.fromARGB(255, 30, 75, 137)
                    : const Color.fromARGB(255, 85, 86, 87),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Center(
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 18, 
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontFamily: 'Titillium Web'
                  ),
                ),
              ),
            ),
          ),
          // Spacing
          const SizedBox(height: 20.0),
          
          // Google Sign-In Button
          // Container(
          //   height: 55,
          //   decoration: BoxDecoration(
          //     color: Colors.transparent, 
          //     borderRadius: BorderRadius.circular(25),
          //     border: Border.all(color: const Color.fromARGB(255, 30, 75, 137), width: 4), 
          //   ),
          //   child: const Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Icon(
          //         FontAwesomeIcons.google,
          //         color: Colors.blue,
          //       ),
          //       SizedBox(width: 15),
          //       Text(
          //         'Sign in with Google',
          //         style: TextStyle(
          //           fontSize: 18, 
          //           color: Colors.blue, 
          //           fontWeight: FontWeight.bold, 
          //           fontFamily: 'Titillium Web'
          //           ),
          //       ),
          //     ],
          //   ),
          // ),
          // Spacing
          // const SizedBox(height: 30.0),
          
          // Login with Face ID
          // GestureDetector(
          //   behavior: HitTestBehavior.translucent,
          //   onTap: () {
          //   },
          //   child: const Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       TextButton(
          //         onPressed: null,
          //         child: Row(
          //           children: [
          //             Text(
          //               'Login with Face ID',
          //               style: TextStyle(
          //                 fontSize: 18, 
          //                 fontWeight: FontWeight.bold, 
          //                 color: Colors.blue, 
          //                 fontFamily: 'Titillium Web'
          //               ),
          //             ),
          //             SizedBox(width: 10),
          //             Icon(
          //               Icons.face,
          //               color: Colors.blue,
          //               size: 20,
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // Spacing
          const SizedBox(height: 40.0),
          
          // Sign-Up Section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Don\'t have an account?',
                style: TextStyle(
                  fontSize: 18, 
                  color: Colors.white, 
                  fontFamily: 'Titillium Web'
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const CreateAccountPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                    ),
                  );
                },
                child: const TextButton(
                  onPressed: null,
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 18, 
                      color: Colors.blue, 
                      fontWeight: FontWeight.bold, 
                      fontFamily: 'Titillium Web'
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Spacing
          const SizedBox(height: 20.0),
              
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
