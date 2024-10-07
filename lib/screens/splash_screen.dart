import 'package:flutter/material.dart';
import 'package:flash_chat_project/screens/welcome_screen.dart'; // Import your welcome screen

class SplashScreen extends StatefulWidget {
  static String id = 'splash_screen';

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToWelcome();
  }

  _navigateToWelcome() async {
    await Future.delayed(Duration(seconds: 5), () {}); // Adjust duration as needed
    Navigator.pushReplacementNamed(context, WelcomeScreen.id); // Use named route
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE73838), // Set faint red background color
      body: Center( // Center the content
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            Container(
              child: Image.asset('images/logo.png'),
              height: 100.0,
            ),
            SizedBox(height: 20,),
            const Text(
              'Flash Chat',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Change the color if needed
              ),
            ),
          ],
        ),
      ),
    );
  }
}
