// Import Flutter Library
import 'package:flutter/material.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart';

// Creating a stateful widget for the Forgot Password page
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

// Creating the state for the Forgot Password page
class _ForgotPasswordPageState extends State<ForgotPasswordPage> {

// Initializing a string to store the entered email
  String ForgotPasswordEmailString = '';

// Making a build method to contain the UI for the Forgot Password page
  @override
  Widget build(BuildContext context) {

// Making a Scaffold Widget containing the components of the Forgot Password page
    return Scaffold(

// Wrapping everything in a padding to make some boundaries 
      body: Padding(
        padding: const EdgeInsets.all(16.0),

// Wrapping everything in a SingleChildScrollView 
        child: SingleChildScrollView(

// Wrapping everything in a column to arrange children vertically
          child: Column(

// Centering the children
            mainAxisAlignment: MainAxisAlignment.center,

// Making a list of child widgets in the Column
            children: <Widget>[

// Adding some space here
              const SizedBox(height: 40.0),

// Adding an align widget to put the text "AGQ" at the top left of the screen
              const Align(
                alignment: Alignment.centerLeft,

// Text widget to display "AGQ"                
                child: Text(
                  "AGQ",
                  
// TextStyle to define text appearance
                  style: TextStyle(
                    fontSize: 40, 
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontFamily: 'Titillium Web', 
                  ),
                ),
              ),

// Adding some space here
              const SizedBox(height: 100.0),

// Text widget to display "Forgot Password?"
              const Text(
                "Forgot Password?",

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

// Text widget to display instructions for the user
              const Text(
                "Enter your email. We will email instructions on how to reset your password.",

// Text alignment set to center
                textAlign: TextAlign.center,

// TextStyle to define text appearance
                style: TextStyle(
                  fontSize: 15, 
                  color: Colors.white, 
                  fontFamily: 'Titillium Web'
                ),
              ),

// Adding some space here
              const SizedBox(height: 25.0),

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
                      "Email",
                      
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
                          ForgotPasswordEmailString = value;
                        });
                      },

// Closing the properties for the textfield
                    ),
                  ],
                ),
              ),
                        
// Adding space at the bottom for the submit button
              const SizedBox(height: 320.0),

// GestureDetector for handling taps on the submit button
              GestureDetector(
                // onTap callback to define logic for handling submit
                onTap: () {
                  // Add your logic for handling submit here
                },
                // Container representing the submit button
                child: Container(
                  // Height of the submit button
                  height: 55,
                  // BoxDecoration for styling the button
                  decoration: BoxDecoration(
                    // Making conditional statements to change the color of the button
                    color: ForgotPasswordEmailString.isNotEmpty
                        ? const Color.fromARGB(255, 30, 75, 137)
                        : const Color.fromARGB(255, 85, 86, 87),
                    // Making the button have rounded borders
                    borderRadius: BorderRadius.circular(25),
                  ),
                  // Row containing the submit text
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Text widget displaying "Submit"
                      Text(
                        "Submit",
                        // TextStyle to define text appearance
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Titillium Web'),
                      )
                    ],
                  ),
                ),
              ),

// Adding space between the submit button and the link to sign in
              const SizedBox(height: 30.0),

// Row containing the link to go back to the sign-in screen
              Row(

// Aligning content at the center horizontally
                mainAxisAlignment: MainAxisAlignment.center,

// Setting the mainAxisSize to MainAxisSize.min to minimize the horizontal space
                mainAxisSize: MainAxisSize.min,

// List of widgets representing the content
                children: [

// Text widget displaying "Back to"
                  const Text(
                    'Back to',

// TextStyle to define text appearance
                    style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'Titillium Web'),
                  ),

// GestureDetector for navigating back to the sign-in screen
                  GestureDetector(

// Making the GestureDetector respond to taps on the entire area
                    behavior: HitTestBehavior.translucent,

// onTap callback to define navigation logic
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

// TextButton representing the "Sign In" link
                    child: const TextButton(

// Set onPressed to null or add your logic inside the GestureDetector
                      onPressed: null,

// Text widget displaying "Sign In"
                      child: Text(
                        "Sign In",

// TextStyle to define text appearance
                        style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold, fontFamily: 'Titillium Web'),
                      ),

// Closing the properties for the message and button
                    ),
                  ),
                ],
              ),

// Adding space at the bottom
              const SizedBox(height: 20.0),

// Closing properties of the forgot password page
            ],
          ),
        ),
      ),
    );
  }
}
