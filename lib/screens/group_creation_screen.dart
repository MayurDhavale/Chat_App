import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat_project/screens/new_user_screen.dart';
import 'package:flutter/material.dart';

import 'new_group_screen.dart'; // Import the NewGroupScreen
import 'group_screen.dart';

class GroupCreationScreen extends StatefulWidget {
  static const String id = 'group_creation_screen';

  @override
  State<GroupCreationScreen> createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  List<Map<String, String>> allRegisteredUsers = [];
  List<Map<String, String>> filteredUsers = [];
  List<Map<String, String>> selectedUsers = [];
  String searchQuery = '';

  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    getAllRegisteredUsers();
  }

  Future<void> getAllRegisteredUsers() async {
    QuerySnapshot userSnapshot = await _firestore.collection('users').get();
    if (userSnapshot.docs.isNotEmpty) {
      List<Map<String, String>> userList = [];
      for (var doc in userSnapshot.docs) {
        String displayName = doc['displayName'];
        String email = doc['email'];
        userList.add({'displayName': displayName, 'email': email});
      }
      setState(() {
        allRegisteredUsers = userList;
        filteredUsers = userList; // Initialize with all users
      });
    }
  }

  void performSearch(String query) {
    final filtered = allRegisteredUsers.where((user) {
      final displayName = user['displayName']?.toLowerCase() ?? '';
      return displayName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredUsers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, GroupsScreen.id);
          },
        ),
        title: Text('Chat'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search TextField
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  searchQuery = value;
                  performSearch(searchQuery);
                },
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            // Options for creating new items
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.grey[200],
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.group_add),
                    title: Text('New Group'),
                    onTap: () {
                      if (selectedUsers.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewGroupScreen(selectedUsers: selectedUsers),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select users to create a group.')),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person_add),
                    title: Text('New Contact'),
                    onTap: () {
                      Navigator.pushNamed(context, NewUserScreen.id);
                    },
                  ),
                ],
              ),
            ),
            // Scrollable List of Registered Users
            ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(filteredUsers[index]['displayName'] ?? 'Unknown User'),
                  subtitle: Text(filteredUsers[index]['email'] ?? ''),
                  trailing: IconButton(
                    icon: Icon(
                      selectedUsers.contains(filteredUsers[index]) ? Icons.check_box : Icons.check_box_outline_blank,
                    ),
                    onPressed: () {
                      setState(() {
                        if (selectedUsers.contains(filteredUsers[index])) {
                          selectedUsers.remove(filteredUsers[index]);
                        } else {
                          selectedUsers.add(filteredUsers[index]);
                        }
                      });
                    },
                  ),
                  onTap: () {
                    // Action for when a user is tapped
                  },
                );
              },
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
            ),
          ],
        ),
      ),
    );
  }
}
