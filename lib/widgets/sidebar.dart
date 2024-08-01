import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_page.dart';
import '../login_page.dart';
import '../manage_post.dart'; // Import the manage_post.dart file
import '../my_post.dart'; // Import the my_post.dart file

class AppDrawer extends StatefulWidget {
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _username = '';
  String _userType = ''; // Variable to store user type

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Guest';
      _userType = prefs.getString('userType') ?? ''; // Load user type
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Use pushAndRemoveUntil to remove all routes below the LoginPage
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 100.0, // Set the height you want for the header
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Welcome, $_username!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainPage()),
              );
            },
          ),
          // Conditionally show "Manage Post" button for admins
          if (_userType == 'admin') ...[
            ListTile(
              leading: Icon(Icons.manage_accounts),
              title: Text('Manage Posts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManagePostPage()),
                );
              },
            ),
          ],
          // Conditionally show "My Posts" button for employers
          if (_userType == 'employer' || _userType == 'admin') ...[
            ListTile(
              leading: Icon(Icons.post_add),
              title: Text('My Posts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyPostPage()),
                );
              },
            ),
            Divider(),
          ],
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
