import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;

  PostDetailPage({required this.post});

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String _userType = '';

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userType = prefs.getString('userType') ?? '';
    });
  }

  Future<void> _showConfirmationDialog(BuildContext context, String newStatus, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevents dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Action'),
          content: Text('Are you sure you want to $message this post?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _updatePostStatus(newStatus);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Post status updated to $newStatus')),
                );
                Navigator.of(context).pop(true); // Go back to the previous screen
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePostStatus(String newStatus) async {
    // Update the post's status in the database
    await _databaseHelper.updatePostStatus(widget.post['id'], newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final imagePath = post['imageName'] ?? 'no_Image.jpg';
    final filePath = File(imagePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(post['title']),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.file(
              filePath,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'lib/image/no_Image.jpg',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                );
              },
            ),
            SizedBox(height: 16.0),
            Text(
              post['title'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              post['companyName'],
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16.0),
            Text(
              'From RM${post['lowestSalary']} to RM${post['highestSalary']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              'Job Description and Requirement:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              post['description'] ?? 'No description provided',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24.0),
            Text(
              'Location:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${post['area']}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      bottomNavigationBar: (_userType == 'admin' && post['status'] == 'pending')
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () {
                      _showConfirmationDialog(context, 'approved', 'approve');
                    },
                    child: Text(
                      'Approve',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _showConfirmationDialog(context, 'rejected', 'reject');
                    },
                    child: Text(
                      'Reject',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
