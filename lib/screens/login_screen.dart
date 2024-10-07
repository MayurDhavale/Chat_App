import 'package:flash_chat_project/screens/registration_screen.dart';
import 'package:flash_chat_project/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat_project/components/rounded_button.dart';
import 'package:flash_chat_project/constants/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flash_chat_project/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String id = 'login_screen';
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool showSpinner = false;
  late String email;
  late String password;
  User? loggedInUser;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),


           AppBar(
             backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushNamed(context, WelcomeScreen.id); //Navigate back to the welcome screen
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

                const SizedBox(
                  height: 48.0,
                ),

                TextField(
                  keyboardType: TextInputType.emailAddress,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    email = value;
                  },
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  decoration:
                      kTextFieldDecoration.copyWith(hintText: 'Enter your Email'),
                ),

                const SizedBox(
                  height: 8.0,
                ),

                TextField(
                  obscureText: true,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    password = value;
                  },
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  decoration:
                      kTextFieldDecoration.copyWith(hintText: 'Enter Password'),
                ),

                const SizedBox(
                  height: 24.0,
                ),

                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14.0,
                  ),
                ),

                SizedBox(
                  height: 24.0,
                ),

                RoundedButton(
                  color: Colors.lightBlueAccent,
                  title: 'LOGIN',
                  onPressed: () async {
                    await loginUser();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
      ),

    );
  }

  Future<void> loginUser() async {
    try {
      // Show loading spinner and clear any previous error messages
      setState(() {
        showSpinner = true;
        errorMessage = ''; // Clear previous error message
      });
      // Attempt to sign in the user with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      loggedInUser = userCredential.user;

      if (loggedInUser != null) {
        // Fetch the groups the user belongs to
        List<String> userGroups = await getUserGroups();

        // Navigate to the home screen, passing the user's groups as arguments
        Navigator.pushNamed(context, HomeScreen.id, arguments: userGroups);
      } else {
        print('User not logged in.');
      }
    } catch (e) {
      print('Login error: $e');
      setState(() {
        errorMessage = 'Invalid email or password. Please try again.';
      });
    } finally {

      // Hide loading spinner regardless of success or failure
      setState(() {
        showSpinner = false;
      });
    }
  }


  Future<List<String>> getUserGroups() async {
    try {
      if (loggedInUser == null) {
        print('No user is currently logged in....');
        return [];
      }
      // Get the logged-in user's email
      String userEmail = loggedInUser!.email!;

      // Query Firestore for groups that contain the logged-in user
      QuerySnapshot groupsSnapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: userEmail)
          .get();

      if (groupsSnapshot.docs.isNotEmpty) {
        // Map the found groups to a list of group IDs
        List<String> userGroups =
            groupsSnapshot.docs.map((doc) => doc.id).toList();
        print('User is in groups: $userGroups');
        return userGroups;
      } else {
        print('No groups found for the user.');
        return [];
      }
    } catch (e) {
      print('Error fetching user groups: $e');
      return [];
    }
  }
}
