import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

class GroupInfoScreen extends StatefulWidget {
  static const String id = 'group_info_screen';

  final String groupName;

  const GroupInfoScreen({required this.groupName});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  List<String> members = []; // To store members' emails
  List<String> filteredMembers = []; // To store filtered members based on search
  int memberCount = 0; // To store total member count
  String? admin; // To store admin's email
  bool isLoading = true; // To show loading indicator
  bool showAllMembers = false; // To control "View More" functionality

  @override
  void initState() {
    super.initState();
    fetchGroupMembers();
  }

  Future<void> fetchGroupMembers() async {
    try {
      final groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('name', isEqualTo: widget.groupName)
          .get();

      if (groupSnapshot.docs.isNotEmpty) {
        final groupData = groupSnapshot.docs.first.data();
        setState(() {
          admin = groupData['admin']; // Get the admin's email
          members = List<String>.from(groupData['members'] ?? []);
          memberCount = members.length;
          filteredMembers = members; // Initially show all members
          isLoading = false; // Set loading to false after fetching data
        });
      } else {
        setState(() {
          isLoading = false; // No group found, stop loading
        });
      }
    } catch (e) {
      print('Error fetching group members: $e');
      setState(() {
        isLoading = false; // Stop loading on error
      });
    }
  }

  void filterMembers(String query) {
    setState(() {
      filteredMembers = members
          .where((member) => member.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            const Center(
              child: CircleAvatar(
                radius: 35.0,
                child: Center(
                  child: Icon(
                    Icons.group,
                    size: 50.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.0),
            Center(
              child: Text(
                widget.groupName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 10.0),
            Center(
              child: Text('Group $memberCount members'),
            ),
            SizedBox(height: 20.0),
            // Header for the member list with search icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$memberCount Members',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      showSearch(
                        context: context,
                        delegate: MemberSearchDelegate(
                          filterMembers: filterMembers,
                          allMembers: members,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.0),
            // List of members
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator()) // Show loading indicator
                  : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: showAllMembers ? filteredMembers.length : filteredMembers.take(5).length,
                      itemBuilder: (context, index) {
                        final memberName = filteredMembers[index];
                        return ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                memberName,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              if (memberName == admin)
                                const Padding(
                                  padding: EdgeInsets.only(left: 30.0), // Add spacing
                                  child: Text(
                                    'Group Admin',
                                    style: TextStyle(
                                      color: Colors.lightGreenAccent,
                                    ),
                                    // Style for the "Admin" label
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (!showAllMembers && filteredMembers.length > 5) // Show "View More" button only if there are more than 5 members
                    TextButton(
                      onPressed: () {
                        setState(() {
                          showAllMembers = true; // Show all members
                        });
                      },
                      child: Text('View All (${filteredMembers.length - 5})'),
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

class MemberSearchDelegate extends SearchDelegate {
  final Function(String) filterMembers;
  final List<String> allMembers;

  MemberSearchDelegate({required this.filterMembers, required this.allMembers});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = ''; // Clear the search query
          filterMembers(query); // Reset the member list
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Close the search
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    filterMembers(query); // Filter members based on search query
    return Container(); // No results to display here
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = allMembers
        .where((member) => member.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}
