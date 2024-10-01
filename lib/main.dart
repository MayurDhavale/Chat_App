import 'package:firebase_core/firebase_core.dart';
import 'package:flash_chat_project/screens/group_screen.dart';
import 'package:flash_chat_project/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat_project/screens/welcome_screen.dart';
import 'package:flash_chat_project/screens/login_screen.dart';
import 'package:flash_chat_project/screens/registration_screen.dart';
import 'package:flash_chat_project/screens/group_chat_screen.dart';

import 'firebase_options.dart';
void main() async{
  //
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}




class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(



      debugShowCheckedModeBanner: false,
      initialRoute: WelcomeScreen.id,
      routes: {
        //  '/welcome_screen' : (context) =>WelcomeScreen(),
        WelcomeScreen.id: (context) =>WelcomeScreen(),
        //  '/registration_screen' : (context) => RegistrationScreen(),
        RegistrationScreen.id : (context) => RegistrationScreen(),
        //'/login_screen' : (context) => LoginScreen(),
        LoginScreen.id : (context) => LoginScreen(),
        'chat_screen' :(context) => ChatScreen(groupId: 'group1',),
        //ChatScreen.id :(context) => ChatScreen(),
        // GroupListScreen.id :(context) => GroupListScreen(),
        GroupsScreen.id : (context) => GroupsScreen(),
        HomeScreen.id : (context) => HomeScreen(),
      },
    );

  }
}
