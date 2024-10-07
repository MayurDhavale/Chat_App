import 'package:flash_chat_project/screens/login_screen.dart';
import 'package:flash_chat_project/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat_project/components/rounded_button.dart';
import 'package:flash_chat_project/constants/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class RegistrationScreen extends StatefulWidget {
  static const String id = 'registration_screen';

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool showSpinner = false;
  late String email;
  late String password;
  late String displayName;
  String? errorMessage; // Variable to hold error message

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0, // Remove shadow
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushNamed(context, WelcomeScreen.id); // Navigate back to the Login screen
              },
            ),
          ),

          ModalProgressHUD(
            inAsyncCall: showSpinner,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Flexible(
                    child: Hero(
                      tag: 'logo',
                      child: Container(
                        height: 200.0,
                        child: Image.asset('images/logo.png'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48.0),

                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      email = value;
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: kTextFieldDecoration.copyWith(hintText: 'Enter your Email'),
                  ),

                  const SizedBox(height: 8.0),

                  TextField(
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      displayName = value; // Store user name input
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: kTextFieldDecoration.copyWith(hintText: 'Enter your Name'),
                  ),

                  const SizedBox(height: 8.0),

                  TextField(
                    obscureText: true,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      password = value;
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: kTextFieldDecoration.copyWith(hintText: 'Enter Password'),
                  ),

                  const SizedBox(height: 24.0),

                  // Show error message if exists
                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16.0),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 16.0), // Add some spacing

                  RoundedButton(
                    color: Colors.lightBlueAccent,
                    title: 'REGISTER',
                    onPressed: () async {
                      setState(() {
                        showSpinner = true;
                        errorMessage = null; // Reset error message
                      });
                      try {
                        final newUser = await _auth.createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );
                        if (newUser != null) {
                          // Store user data in Firestore users collection
                          await _firestore.collection('users').doc(email).set({
                            'email': email,
                            'displayName': displayName, // Add user name to Firestore
                            'lastActive': FieldValue.serverTimestamp(),
                            // 'lastMessageTime' :FieldValue.serverTimestamp(),
                          });
                          print('User registered and document created.');
                          // After successfully registration navigate to the login screen
                          Navigator.pushNamed(context, LoginScreen.id);
                        }
                      } catch (e) {
                        print(e);
                        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
                          setState(() {
                            errorMessage = 'This email is already registered.'; // Set error message
                          });
                        } else {
                          setState(() {
                            errorMessage = 'Registration failed. Please try again.';
                          });
                        }
                      } finally {
                        setState(() {
                          showSpinner = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16.0), // Add some spacing
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Center the Row content
                      children: [
                        const Text(
                          'Already Registered? ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, LoginScreen.id); // Navigate to Login screen
                          },
                          child: const Text(
                            ' Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.blue, fontSize: 16.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
