import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flash_chat_project/screens/group_info_screen.dart';
import 'package:flash_chat_project/screens/group_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat_project/constants/constants.dart';
import 'package:flash_chat_project/screens/home_screen.dart';
import 'package:flash_chat_project/screens/group_info_screen.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
User? loggedInUser;

class ChatScreen extends StatefulWidget {
  static String id = 'chat_screen';
  final String groupId;

  ChatScreen({required this.groupId}); // Constructor to receive group ID

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController =
      TextEditingController(); // Controller for message input
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  late String messageText; // Variable to hold message text
  String groupName = '';
  String groupAdminEmail = '';

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    getGroupName();
  }

  void getCurrentUser() {
    try {
      final User? user = _auth.currentUser; // Get currently logged-in user

      if (user != null) {
        setState(() {
          loggedInUser = user;
        });
        print(loggedInUser?.email ?? 'No email available');
      } else {
        print('No user is currently logged in.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

// Fetch group name and admin email
  void getGroupName() async {
    try {
      DocumentSnapshot groupSnapshot = await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .get(); // Get group document

      if (groupSnapshot.exists) {
        setState(() {
          groupName = groupSnapshot['name'] ?? 'Group Chat';
          groupAdminEmail = groupSnapshot['admin'] ?? '';
        });
      } else {
        print('Group not found');
      }
    } catch (e) {
      print('Error getting group name: $e');
    }
  }

  //Function to exit group functionality
  Future<void> exitGroup(String groupId) async {
    try {
      final loggedInUser = _auth.currentUser;
      if (loggedInUser == null) return;

      String userEmail = loggedInUser.email!;
      DocumentSnapshot groupDoc =
          await _firestore.collection('groups').doc(groupId).get();
      List<dynamic> members = groupDoc['members']; // Get current members

      // Check if the user exiting is the admin
      if (groupDoc['admin'] == userEmail) {
        // Remove the user from the members
        members.remove(userEmail);

        // If there are remaining members, assign the first one as the new admin
        if (members.isNotEmpty) {
          String newAdminEmail = members[0];
          await _firestore.collection('groups').doc(groupId).update({
            'members': members,
            'admin': newAdminEmail,
            'lastActive': FieldValue.serverTimestamp(),
          });
          print('Admin exited group. New admin assigned: $newAdminEmail.');
        } else {
          // If no members are left, delete the group
          await _firestore.collection('groups').doc(groupId).delete();
          print('Last admin exited group. Group deleted.');
        }
      } else {
        // If the user is not the admin, simply remove them
        await _firestore.collection('groups').doc(groupId).update({
          'members': FieldValue.arrayRemove([userEmail]),
          'lastActive': FieldValue.serverTimestamp(),
        });
        print('Exited group successfully.');
        // Navigate to groups screen
      }

      // Navigate to groups screen after exiting
      Navigator.pushReplacementNamed(context, GroupsScreen.id);
    } catch (e) {
      print('Error exiting group: $e');
    }
  }

  //Function to Show confirmation dialog before exiting the group
  Future<void> _showExitConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Exit Group'),
          content: Text('Are you sure you want to exit this group?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                exitGroup(widget.groupId);
                Navigator.pop(context); // Close the dialog after exiting
              },
              child: Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  // Function to add a new member to the group
  void _addMember(String mailId) async {
    try {
      // Reference to the group's document
      final groupDocRef = _firestore.collection('groups').doc(widget.groupId);

      // Fetch the current group document
      final groupDocSnapshot = await groupDocRef.get();

      if (groupDocSnapshot.exists) {
        // Get the current members list, if any
        List<dynamic> currentMembers =
            groupDocSnapshot.data()?['members'] ?? [];

        // Check if the member is already in the group
        if (currentMembers.contains(mailId)) {
          print('Member already exists');
          return; // Exit if the member is already present
        }

        // Check if adding this member would exceed the limit of 256
        if (currentMembers.length >= 256) {
          print('Cannot add more members. The group is full.');
          return; // Exit if the limit is reached
        }

        // Add the new member
        currentMembers.add(mailId);

        // Update the group's document with the new members list
        await groupDocRef.update({'members': currentMembers});
        print('Member added successfully');
      } else {
        print('Group does not exist');
      }
    } catch (e) {
      print('Error adding member: $e');
    }
  }

  // Show dialog to add a new member
  Future<String?> _showAddMemberDialog(BuildContext context) async {
    final TextEditingController _controller =
        TextEditingController(); // Controller for inpu
    final GlobalKey<FormState> _formKey =
        GlobalKey<FormState>(); // Form key for validation

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add Member',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _controller,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(hintText: 'Enter user email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                final emailRegex = RegExp(
                  r'^[^@]+@[^@]+\.[^@]+$',
                );
                if (!emailRegex.hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  Navigator.pop(
                      context, _controller.text); // Return email on success
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: Text(
                'Add',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 20.0),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, GroupsScreen.id); // Navigate back to the previous screen
          },
        ),
        actions: <Widget>[
          if (loggedInUser?.email ==
              groupAdminEmail) // Only show add member button for admin
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () async {
                var userMail = await _showAddMemberDialog(
                    context); // Show add member dialog
                if (userMail != null) {
                  _addMember(userMail);
                }
              },
            ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              _showExitConfirmationDialog(context);
            },
          ),
        ],
        title: Row(
          children: [
            Icon(Icons.group),
            SizedBox(width: 8),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupInfoScreen(groupName: groupName),
                  ),
                );
              },
              child: Text(' $groupName'),
            ),
          ],
        ),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(groupId: widget.groupId), // Stream of messages
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (messageText.isNotEmpty) {
                        try {
                          messageTextController.clear();
                          await _firestore.collection('messages').add({
                            'text': messageText,
                            'sender': loggedInUser?.email,
                            'timestamp': FieldValue.serverTimestamp(),
                            'groupId': widget.groupId,
                          });
                          setState(() {
                            messageText = '';
                          });
                        } catch (e) {
                          print('Error adding document: $e');
                        }
                      } else {
                        print('Message text is empty');
                      }
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget to display messages
class MessageStream extends StatelessWidget {
  final String groupId;

  MessageStream({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Stream to listen for messages
      stream: _firestore
          .collection('messages')
          .where('groupId', isEqualTo: groupId) // Filter by group ID
          .orderBy('timestamp', descending: false) // Order by timestamp
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        } else {
          final messages =
              snapshot.data!.docs.reversed; // Get messages in reverse order
          List<MessageBubble> messageBubbles =
              []; // List to hold message bubbles
          final currentUser = loggedInUser?.email;

          for (var message in messages) {
            final messageText = message.get('text') as String?;
            final messageSender = message.get('sender') as String?;

            if (messageText == null || messageSender == null) {
              continue;
            }

            final messageWidget = MessageBubble(
              sender: messageSender,
              text: messageText,
              isMe: currentUser ==
                  messageSender, // Check if the message is from the current user
            );

            messageBubbles.add(messageWidget);
          }

          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              children: messageBubbles, // Display message bubbles
            ),
          );
        }
      },
    );
  }
}

// Widget to display individual message bubbles
class MessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final bool isMe;

  MessageBubble({required this.sender, required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: const TextStyle(color: Colors.black54, fontSize: 12.0),
          ),
          Material(
            borderRadius: isMe
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(15.0),
                    bottomRight: Radius.circular(15.0),
                    topLeft: Radius.circular(15.0),
                  )
                : const BorderRadius.only(
                    bottomLeft: Radius.circular(15.0),
                    bottomRight: Radius.circular(15.0),
                    topRight: Radius.circular(15.0),
                  ),
            elevation: 5.0,
            color: isMe
                ? Colors.lightBlueAccent
                : Colors.white, // Background color based on sender
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15.0,
                  color: isMe
                      ? Colors.white
                      : Colors.black54, // Text color based on sender
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
