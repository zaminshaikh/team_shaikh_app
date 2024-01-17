// Importing Flutter Library & Google button Library
import 'package:flutter/material.dart';
import 'package:custom_signin_buttons/custom_signin_buttons.dart';

// Creating a stateful widget for the Login page
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

// State class for the LoginPage
class _LoginPageState extends State<LoginPage> {

// Boolean variable to set password visibility to hidden
  bool hidePassword = true;

// Boolean variable to set the remember me checkbox to unchecked, and initializing that the user does not want the app to remember them
  bool rememberMe = false;
  
// Strings to store login email and password
  String loginEmailString = '';
  String loginPasswordString = '';

// Making a build method to contain the entire login UI
  @override
  Widget build(BuildContext context) {

// Making a Scaffold Widget containing the components of the login screen
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
              const SizedBox(height: 60.0),

// Text widget to display "Login to Your Account"                
              const Text(
                "Login to Your Account",

// TextStyle to define text appearance
                style: TextStyle(
                  fontSize: 26, 
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontFamily: 'Titillium Web'
                ),
              ),
              
// Adding some space here
              const SizedBox(height: 35.0),

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
                          loginEmailString = value;
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
                      "Password",

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

// Placeholder text to display 'Enter your password'       
                        hintText: 'Enter your password',

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
                              hidePassword = !hidePassword;
                            });
                          },

// Adding some padding for the icon
                          child: Padding(
                            padding: const EdgeInsets.all(0.0),

// Icon widget to toggle password visibility
                            child: Icon(
                              
// Conditionally choosing between outlined and rounded eye icon based on password visibility
                              hidePassword ? Icons.remove_red_eye_outlined : Icons.remove_red_eye_rounded,

// Styling the eye icon
                              size: 25,
                              color: const Color.fromARGB(255, 154, 154, 154),

// Closing the eye Icon properties
                            ),
                          ),
                        ),
                      ),

//Making the Password visible depending on if the user pressed the icon 
                      obscureText: hidePassword,

// Update loginPasswordString whenever the text changes
                      onChanged: (value) {
                        setState(() {
                          loginPasswordString = value;
                        });
                      },
// Closing the Password Field properties
                    ),
                  ],
                ),
              ),

// Adding some space here
              const SizedBox(height: 20.0),

// Row for "Remember Me" and "Forgot Password?" options
              Row(

// Centering the options
                mainAxisAlignment: MainAxisAlignment.center,

// Making a list of child widgets in the Row
                children:[
                  Row(
                    children: [

// GestureDetector for the checkbox "Remember Me" status
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            rememberMe = !rememberMe;
                          });
                        },

// Wrapping the checkbox and the remember me text in a Padding
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: 

// Making a conditional statement that changes the icon to checked box when clicked
                            Icon(
                              rememberMe
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,

// Styling the icons
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),

// Text for "Remember Me" 
                      const Text('Remember Me',

// Styling the text
                        style: TextStyle(
                          fontSize: 16, 
                          color: Colors.white, 
                          fontFamily: 'Titillium Web'
                        )
                      ),
                      
// Adding some space here
                      const SizedBox(width: 100),
                      
// GestureDetector for navigating to the "Forgot Password?" screen
                      GestureDetector(

// Set the behavior to HitTestBehavior.translucent to capture taps on transparent areas
                        behavior: HitTestBehavior.translucent,

// Navigate to the forgot_password screen using the route
                        onTap: () {
                          Navigator.pushNamed(context, '/forgot_password');
                        },

// TextButton containing the "Forgot Password?" text
                        child: const TextButton(

// Set onPressed to null as the onTap callback handles the action
                          onPressed: null,

// Text widget displaying "Forgot Password?"
                          child: Text(
                            "Forgot Password?",

// TextStyle to define text appearance
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.blue, 
                              fontFamily: 'Titillium Web'
                              ),

// Closing the properties for the button
                          ),
                        ),
                      ),


// Closing the properties for the options row
                    ],
                  ),
                ]
              ),

// Adding some space here
              const SizedBox(height: 60.0),

// GestureDetector for handling taps on the login button
              GestureDetector(

// onTap callback to define logic for handling login
                onTap: () {
                      Navigator.pushNamed(context, '/dashboard');                    
                },

// Container representing the login button
                child: Container(
                  height: 55,

// BoxDecoration for styling the button
                  decoration: BoxDecoration(

// Making conditional statements to change the color of the button
                    color: loginEmailString.isNotEmpty && loginPasswordString.isNotEmpty
                        ? const Color.fromARGB(255, 30, 75, 137)
                        : const Color.fromARGB(255, 85, 86, 87),

// Making the button have rounded borders
                    borderRadius: BorderRadius.circular(25),
                  ),

// Centered Text widget displaying "Login"
                  child: const Center(
                    child: Text(
                      "Login",

// TextStyle to define text appearance
                      style: TextStyle(
                        fontSize: 18, 
                        color: Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontFamily: 'Titillium Web'
                      ),

// Closing the properties for the button
                    ),
                  ),
                ),
              ),


// Adding some space here
              const SizedBox(height: 20.0),

// Container for Google sign-in button
              Container(
                height: 55,

// BoxDecoration for styling the button
                decoration: BoxDecoration(
                  color: Colors.transparent, 
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color.fromARGB(255, 30, 75, 137), width: 4), 
                ),

// Row containing Google icon and text
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

// Google icon
                    Icon(
                      FontAwesomeIcons.google,
                      color: Colors.blue,
                    ),

// Adding some space here
                    SizedBox(width: 15),

// Text widget displaying "Sign in with Google"
                    Text(
                      "Sign in with Google",

// TextStyle to define text appearance
                      style: TextStyle(
                        fontSize: 18, 
                        color: Colors.blue, 
                        fontWeight: FontWeight.bold, 
                        fontFamily: 'Titillium Web'
                        ),

// Closing the google sign in button properties
                    )
                  ],
                ),
              ),

// Adding some space here
              const SizedBox(height: 30.0),

// GestureDetector for handling the Face ID login
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                },

// Row containing the Face ID login option
                child: const Row(

// Aligning the row content at the center
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

// TextButton for Face ID login
                    TextButton(
                      onPressed: null, // Set to null for now

// Row containing text and Face ID icon
                      child: Row(

// Listing the text and Face ID icon in the row
                        children: [

// Text widget displaying "Login with Face ID"
                          Text(
                            "Login with Face ID",

// TextStyle to define text appearance
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.blue, 
                              fontFamily: 'Titillium Web'
                            ),
                          ),

// Adding some space here
                          SizedBox(width: 10),

// Face ID icon
                          Icon(
                            Icons.face,
                            color: Colors.blue,
                            size: 20,
                          ),

// Closing the properties for the Face ID option
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              
// Adding some space here
              const SizedBox(height: 40.0),

// Row containing the "Don't have an account?" message and "Sign Up" button
              Row(

// Aligning the row content at the center
                mainAxisAlignment: MainAxisAlignment.center,
                
// Listing the message and button as children in the row
                children: [
                  
// Text widget displaying "Don't have an account?"
                  const Text(
                    'Don\'t have an account?',

// TextStyle to define text appearance
                    style: TextStyle(
                      fontSize: 18, 
                      color: Colors.white, 
                      fontFamily: 'Titillium Web'
                    ),
                  ),

// GestureDetector for navigating to the "Sign Up" screen
                  GestureDetector(

// Making the GestureDetector respond to taps on the entire area
                    behavior: HitTestBehavior.translucent,

// Adding an onTap method so it navigates to the create_account page
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/create_account');
                    },

// TextButton representing the "Sign Up" button
                    child: const TextButton(

// Set onPressed to null or add your logic inside the GestureDetector
                      onPressed: null,

// Text widget displaying "Sign Up"
                      child: Text(
                        "Sign Up",

// TextStyle to define text appearance
                        style: TextStyle(
                          fontSize: 18, 
                          color: Colors.blue, 
                          fontWeight: FontWeight.bold, 
                          fontFamily: 'Titillium Web'
                        ),
                      ),

//Closing the properties for the "Don't have an account?" message and "Sign Up" button
                    ),
                  ),
                ],
              ),
              
// Adding some space here
              const SizedBox(height: 20.0),


// Close all properties for the log in screen
            ],
          ),
        ),
      ),
    );
  }
}
