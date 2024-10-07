import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../constants/constants.dart';

class IndividualChatScreen extends StatefulWidget {
  final String chatUserEmail; // Email of the user you are chatting with

  const IndividualChatScreen({super.key, required this.chatUserEmail});

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  final TextEditingController _controller = TextEditingController();
  late String currentUserEmail;
  late String chatUserEmail;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance; // Initialize Firebase Auth
    _firestore = FirebaseFirestore.instance; // Initialize Firestore
    currentUserEmail = _auth.currentUser!.email!; // Get current user's email
    chatUserEmail = widget.chatUserEmail; // Get chat user email from widget

    // Mark all messages as read when the chat screen is opened
    markMessagesAsRead(chatUserEmail, currentUserEmail);
  }

  // Function to mark messages as read and reset unread count
  Future<void> markMessagesAsRead(String sender, String receiver) async {
    // Update all unread messages to read
    await _firestore
        .collection('messages')
        .where('sender', isEqualTo: sender)
        .where('receiver', isEqualTo: receiver)
        .where('read', isEqualTo: false)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'read': true});
      }
    });

    // Reset the unread count for the sender
    await _firestore.collection('users').doc(receiver).update({
      'unreadCount.$sender': 0, // Reset unread count to 0
    });
  }

  // Function to send a message
  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      // Add a new message to Firestore
      await _firestore.collection('messages').add({
        'sender': currentUserEmail,
        'receiver': chatUserEmail,
        'message': _controller.text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false, // New message is unread by default
      });
      _controller.clear(); // Clear the text field after sending
    }
  }

  // Stream to get messages for the current chat
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getMessagesStream() {
    // Stream for messages sent by the current user
    final userMessagesStream = _firestore
        .collection('messages')
        .where('sender', isEqualTo: currentUserEmail)
        .where('receiver', isEqualTo: chatUserEmail)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs);

    // Stream for messages sent by the chat user
    final chatMessagesStream = _firestore
        .collection('messages')
        .where('sender', isEqualTo: chatUserEmail)
        .where('receiver', isEqualTo: currentUserEmail)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs);

    // Combine both streams into a single stream
    return Rx.combineLatest2(
      userMessagesStream,
      chatMessagesStream,
          (List<QueryDocumentSnapshot<Map<String, dynamic>>> userMessages,
          List<QueryDocumentSnapshot<Map<String, dynamic>>> chatMessages) {
        // Merge and sort all messages by timestamp
        final allMessages = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        allMessages.addAll(userMessages);
        allMessages.addAll(chatMessages);
        allMessages.sort((a, b) {
          final timestampA = (a.data()['timestamp'] as Timestamp).toDate();
          final timestampB = (b.data()['timestamp'] as Timestamp).toDate();
          return timestampA.compareTo(timestampB);
        });
        return allMessages; // Return sorted messages
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Text('Chat with $chatUserEmail'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              stream: getMessagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages found.'));
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: false,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data();
                    final messageText = message['message'] ?? 'No message';
                    final messageSender = message['sender'] ?? 'Unknown sender';
                    final isCurrentUser = messageSender == currentUserEmail;

                    return ChatBubble(
                      message: messageText,
                      isMe: isCurrentUser,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: kMessageTextFieldDecoration,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;

  const ChatBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: isMe ? Colors.lightBlueAccent : Colors.grey[300],
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
          ),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 16.0,
              color: isMe ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
