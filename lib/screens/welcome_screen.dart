import 'package:flutter/material.dart';
import 'package:flash_chat_project/screens/login_screen.dart';
import 'package:flash_chat_project/screens/registration_screen.dart';
import 'package:flash_chat_project/components/rounded_button.dart';

class WelcomeScreen extends StatelessWidget {
  static const String id = 'welcome_screen'; // create the static constant id for navigation

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),


          // Foreground content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Hero(
                      tag: 'logo',
                      child: Container(
                        child: Image.asset('images/logo.png'),
                        height: 60.0,
                      ),
                    ),
                    const Text(
                      'Flash Chat',
                      style: TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 48.0,
                ),

                RoundedButton(
                  color: Colors.lightBlueAccent,
                  title: 'LOGIN',
                  onPressed: () {
                    // Go to login screen.
                    Navigator.pushNamed(context, LoginScreen.id);
                  },
                ),

                RoundedButton(
                  color: Colors.lightBlueAccent,
                  title: 'REGISTER',
                  onPressed: () {
                    // Go to registration screen.
                    Navigator.pushNamed(context, RegistrationScreen.id);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
