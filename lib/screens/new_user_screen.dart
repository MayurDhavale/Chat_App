import 'package:flash_chat_project/screens/group_creation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat_project/components/rounded_button.dart';
import 'package:flash_chat_project/constants/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class NewUserScreen extends StatefulWidget {
  static const String id = 'new_user_screen';

  @override
  _NewUserScreenState createState() => _NewUserScreenState();
}

class _NewUserScreenState extends State<NewUserScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool showSpinner = false;
  late String email;
  late String password;
  late String displayName;
  String? errorMessage;

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
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushNamed(context, GroupCreationScreen.id);
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
                      displayName = value;
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
                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16.0),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16.0),
                  RoundedButton(
                    color: Colors.lightBlueAccent,
                    title: 'REGISTER',
                    onPressed: () async {
                      setState(() {
                        showSpinner = true;
                        errorMessage = null;
                      });
                      try {
                        // Register new user in Firestore without changing auth state
                        await _firestore.collection('users').doc(email).set({
                          'email': email,
                          'displayName': displayName,
                          'lastActive': FieldValue.serverTimestamp(),
                          'chattedwith': [], // Initialize as an empty array
                        });
                        print('User data stored in Firestore.');
                        // Navigate back to the group creation screen after registration
                        Navigator.pushNamed(context, GroupCreationScreen.id);
                      } catch (e) {
                        print(e);
                        setState(() {
                          errorMessage = 'Registration failed. Please try again.';
                        });
                      } finally {
                        setState(() {
                          showSpinner = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
