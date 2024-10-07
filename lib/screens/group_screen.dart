import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flash_chat_project/screens/home_screen.dart';
import 'package:flash_chat_project/screens/individual_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat_project/screens/group_chat_screen.dart';

class GroupsScreen extends StatefulWidget {
  static String id = 'groups_screen';

  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Map<String, String>> allRegisteredUsers = [];
  Map<String, String> userGroups = {};
  List<Map<String, String>> previouslyChattedUsers = [];
  List<Map<String, dynamic>> combinedList = [];
  bool _isCreatingGroup = false;
  bool _isSearching = false;
  final _groupNameController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    getAllRegisteredUsers();
    getUserDetails();
  }


  Future<void> getAllRegisteredUsers() async {
    try {
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      if (usersSnapshot.docs.isNotEmpty) {
        List<Map<String, String>> userList = [];
        for (var doc in usersSnapshot.docs) {
          String displayName = doc['displayName'] ?? 'Unknown';
          String email = doc['email'] ?? 'No email';
          userList.add({'displayName': displayName, 'email': email});
        }
        setState(() {
          allRegisteredUsers = userList;
        });
      }
    } catch (e) {
      print('Error fetching all registered users: $e');
    }
  }

  Future<void> getUserDetails() async {
    try {
      final loggedInUser = _auth.currentUser;
      if (loggedInUser == null) {
        print('No user is currently logged in.');
        return;
      }

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(loggedInUser.email).get();
      List<dynamic> chattedWith = userDoc['chattedwith'] ?? [];

      previouslyChattedUsers = allRegisteredUsers
          .where((user) => chattedWith.contains(user['email']))
          .toList();

      await getUserGroups();
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  Future<void> getUserGroups() async {
    try {
      final loggedInUser = _auth.currentUser;
      if (loggedInUser == null) return;

      String userEmail = loggedInUser.email!;
      QuerySnapshot groupsSnapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: userEmail)
          .get();

      if (groupsSnapshot.docs.isNotEmpty) {
        Map<String, String> groupMap = {};
        for (var doc in groupsSnapshot.docs) {
          String groupId = doc.id;
          String groupName = doc['name'] ?? 'Unnamed Group';
          groupMap[groupId] = groupName;
        }
        setState(() {
          userGroups = groupMap;
          _updateCombinedList();
        });
      } else {
        setState(() {
          userGroups = {};
          _updateCombinedList();
        });
      }
    } catch (e) {
      print('Error fetching user groups: $e');
    }
  }

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
        'members': [userEmail],
        'admin': userEmail,
        'lastActive': FieldValue.serverTimestamp(),
      });

      print('Group created successfully.');
      await getUserGroups();
      setState(() {
        _isCreatingGroup = false;
        _groupNameController.clear();
      });
    } catch (e) {
      print('Error creating group: $e');
    }
  }

  Future<void> updateUserLastActive(String email) async {
    try {
      await _firestore.collection('users').doc(email).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
      print('User $email lastActive updated successfully.');
    } catch (e) {
      print('Error updating user lastActive for $email: $e');
    }
  }

  Future<void> updateGroupLastActive(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating group lastActive: $e');
    }
  }

  Future<void> _updateCombinedList() async {
    List<Map<String, dynamic>> groupsList = await Future.wait(userGroups.entries.map((e) async {
      DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(e.key).get();
      return {
        'type': 'group',
        'id': e.key,
        'name': e.value,
        'lastActive': groupDoc['lastActive'],
      };
    }));

    List<Map<String, dynamic>> usersList = await Future.wait(previouslyChattedUsers.map((e) async {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(e['email']).get();
      return {
        'type': 'user',
        'email': e['email']!,
        'name': e['displayName']!,
        'lastActive': userDoc['lastActive'],
      };
    }));

    List<Map<String, dynamic>> combined = [...groupsList, ...usersList];
    combined.sort((a, b) {
      DateTime aLastActive = (a['lastActive'] as Timestamp).toDate();
      DateTime bLastActive = (b['lastActive'] as Timestamp).toDate();
      return bLastActive.compareTo(aLastActive);
    });

    setState(() {
      combinedList = combined;
    });
  }

  Future<void> _addToChattedWith(String email) async {
    try {
      final loggedInUser = _auth.currentUser;
      if (loggedInUser == null) return;

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(loggedInUser.email).get();
      List<dynamic> chattedWith = userDoc['chattedwith'] ?? [];

      if (!chattedWith.contains(email)) {
        chattedWith.add(email);
        await _firestore.collection('users').doc(loggedInUser.email).update({
          'chattedwith': chattedWith,
        });
        print('User $email added to chattedWith successfully.');
      }
    } catch (e) {
      print('Error updating chattedWith field: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedInUserEmail = _auth.currentUser?.email ?? '';

    List<Map<String, dynamic>> filteredList;

    if (_isSearching) {
      // Create a merged list
      filteredList = [...combinedList];
      for (var user in allRegisteredUsers) {
        if (!filteredList.any((item) => item['email'] == user['email'])) {
          filteredList.add({
            'type': 'user',
            'email': user['email']!,
            'name': user['displayName']!,
          });
        }
      }
    } else {
      filteredList = combinedList;
    }

    // Filter the list based on the search query
    filteredList = filteredList.where((item) {
      final name = item['name']?.toLowerCase() ?? '';
      final email = item['email']?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(), // Pass the group ID
                ),
              );

          },
        ),
        backgroundColor: Colors.grey,
        title: Text(
          _isSearching ? 'Search Results' : 'Groups and Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isCreatingGroup)
            IconButton(
              icon: Icon(_isSearching ? Icons.clear : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                  _isSearching = !_isSearching;
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (query) {
                        setState(() {
                          _searchQuery = query;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Search',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final isGroup = item['type'] == 'group';
                      final itemName = item['name'] ?? '';
                      final itemEmail = item['email'] ?? '';
                      final itemId = item['id'] ?? '';

                      // Check if the current item is the logged-in user
                      final displayName = (itemEmail == loggedInUserEmail)
                          ? '$itemName (You)'
                          : itemName;

                      return ListTile(
                        leading: Icon(isGroup ? Icons.group : Icons.person),
                        title: Text(displayName),
                        subtitle: isGroup ? null : Text(itemEmail),
                        onTap: () {
                          if (isGroup) {
                            updateGroupLastActive(itemId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(groupId: itemId),
                              ),
                            );
                          } else {
                            updateUserLastActive(itemEmail);
                            _addToChattedWith(itemEmail);  // Add user to chattedWith
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IndividualChatScreen(chatUserEmail: itemEmail),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isCreatingGroup)
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: Container(
                width: 300,
                child: Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _groupNameController,
                          decoration: InputDecoration(
                            labelText: 'Enter group name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () {
                            final groupName = _groupNameController.text.trim();
                            if (groupName.isNotEmpty) {
                              createGroup(groupName);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                          child: Text(
                            'Create Group',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isCreatingGroup = false;
                              _groupNameController.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: () {
                setState(() {
                  _isCreatingGroup = true;
                });
              },
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.chat_bubble, color: Colors.white),
                  ),
                  Center(
                    child: Icon(Icons.add, color: Colors.green, size: 18.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
