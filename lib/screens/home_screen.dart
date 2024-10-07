import 'package:flash_chat_project/screens/group_screen.dart';
import 'package:flash_chat_project/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  static const String id = 'home_screen';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Index of the currently selected tab
  final FirebaseAuth _auth = FirebaseAuth.instance; // Initialize Firebase Auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Initialize Firestore

  // List of pages to display based on the selected index
  final List<Widget> _pages = [
    HomeContentScreen(),
    GroupsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to show user information in a dialog when click on profile icon
  Future<void> _showUserInfo() async {
    User? user = _auth.currentUser; // Get the current user
    if (user == null) return;

    try {
      // Fetch user document from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.email).get();
      String displayName = userDoc['displayName'] ?? 'Not set';
      String email = user.email ?? 'Not set';


      // Show dialog with user information
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('User Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('UserName: $displayName'),
                Text('Email: $email'),
              ],
            ),

            actions: [
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      _logout(); // Close the dialog
                    },
                    child: const Text('Logout'),
                  ),
                  const SizedBox(width: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: Text('Close'),
                  ),
                ],
              )
            ],
          );
        },
      );
    } catch (e) {
      print('Error fetching user information: $e');

    }
  }

  // Function to logout the user
  Future<void> _logout() async {
    try {
      await _auth.signOut();  // Sign out the user
      // Navigate to the login screen or show a logout message
      Navigator.pushNamed(context, LoginScreen.id);
    } catch (e) {
      print('Error logging out: $e');

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 // Show AppBar only for HomeContentScreen
          ? AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: const Text(
          'Welcome Flash Chat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _showUserInfo,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      )
          : null, // No AppBar for GroupsScreen

      body: _pages[_selectedIndex], // Display selected page

      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Colors.lightBlueAccent,
        buttonBackgroundColor: Colors.green,
        height: 60.0,
        items: <Widget>[
          Icon(
            Icons.home,
            size: 25,
            color: _selectedIndex == 0 ? Colors.black : Colors.white,
          ),

          Icon(
            Icons.chat,
            size: 25,
            color: _selectedIndex == 1 ? Colors.black : Colors.white,
          ),

        ],
        index: _selectedIndex, // Set the currently selected index
        onTap: _onItemTapped, // Handle tab selection
      ),
    );
  }
}

// Define HomeContentScreen as a separate widget
class HomeContentScreen extends StatelessWidget {
  const HomeContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 200.0,
                child: Image.asset('images/logo.png'),
              ),
            ),
          ),
          const Center(
            child: Text(
              'Flash Chat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 50.0,
                color: Colors.black54,
                fontFamily: 'Raleway',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
