import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewGroupScreen extends StatefulWidget {
  static const String id = 'new_group_screen';
  final List<Map<String, String>> selectedUsers;

  NewGroupScreen({required this.selectedUsers});

  @override
  _NewGroupScreenState createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _groupNameController = TextEditingController();
  bool _isCreatingGroup = false;

  Future<void> createGroup(String groupName) async {
    try {
      final loggedInUser = _auth.currentUser;
      if (loggedInUser == null) return;

      if (groupName.isEmpty) {
        print('Group name cannot be empty.');
        return;
      }

      String userEmail = loggedInUser.email!;
      DocumentReference newGroupRef = _firestore.collection('groups').doc();
      await newGroupRef.set({
        'name': groupName,
        'members': [userEmail, ...widget.selectedUsers.map((user) => user['email']).toList()],
        'admin': userEmail,
        'lastActive': FieldValue.serverTimestamp(),
      });

      print('Group created successfully.');
      Navigator.pop(context); // Go back to the previous screen after group creation
    } catch (e) {
      print('Error creating group: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Group'),
        backgroundColor: Colors.green,

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _groupNameController,
              onChanged: (value) {
                // Handle group name change if necessary
              },
              decoration: InputDecoration(
                hintText: 'Enter group name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Text('Members:'),
            Expanded(
              child: ListView.builder(
                itemCount: widget.selectedUsers.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(widget.selectedUsers[index]['displayName'] ?? ''),
                    subtitle: Text(widget.selectedUsers[index]['email'] ?? ''),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isCreatingGroup = true; // Indicate group creation is in progress
                });
                createGroup(_groupNameController.text.trim());
              },
              child: _isCreatingGroup
                  ? CircularProgressIndicator() // Show loading indicator if creating group
                  : Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}
