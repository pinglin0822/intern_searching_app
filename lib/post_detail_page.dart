import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'edit_post.dart';
import 'create_application.dart';
import 'view_applicant.dart';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String _userType = '';
  int _userId = 0;
  late Map<String, dynamic> _post;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
    _post = widget.post;
  }

  Future<void> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userType = prefs.getString('userType') ?? '';
      _userId = prefs.getInt('userId') ?? 0;
    });
  }

  Future<void> _showConfirmationDialogDelete(
      BuildContext context, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Action'),
          content: Text('Are you sure you want to $message this post?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deletePost();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted')),
                );
                Navigator.of(context).pop(true);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showConfirmationDialog(
      BuildContext context, String newStatus, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Action'),
          content: Text('Are you sure you want to $message this post?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _updatePostStatus(newStatus);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Post status updated to $newStatus')),
                );
                Navigator.of(context).pop(true);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost() async {
    await _databaseHelper.deletePost(widget.post['id']);
  }

  Future<void> _updatePostStatus(String newStatus) async {
    await _databaseHelper.updatePostStatus(widget.post['id'], newStatus);
  }

  void _refreshPostDetails(Map<String, dynamic> updatedPost) {
    setState(() {
      _post = updatedPost;
      _moveCameraToLocation();
    });
    
  }

  void _moveCameraToLocation() {
  if (_mapController != null) {
    final LatLng newLocation = LatLng(_post['latitude'], _post['longitude']);
    _mapController!.animateCamera(
      CameraUpdate.newLatLng(newLocation),
    );
  }
}


  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(true);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final imagePath = post['imageName'] ?? 'no_Image.jpg';
    final filePath = File(imagePath);
    final LatLng postLocation = LatLng(post['latitude'], post['longitude']);

    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: AppBar(
            title: Text(post['title']),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
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
                const SizedBox(height: 16.0),
                Text(
                  post['title'],
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  post['companyName'],
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'From RM${post['lowestSalary']} to RM${post['highestSalary']}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Job Description and Requirement:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  post['description'] ?? 'No description provided',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24.0),
                const Text(
                  'Location:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 200.0,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: postLocation,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId(post['title']),
                        position: postLocation,
                      ),
                    },
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    gestureRecognizers: Set()
                      ..add(Factory<EagerGestureRecognizer>(
                          () => EagerGestureRecognizer())),
                  ),
                ),
                const SizedBox(height: 24.0),
                Row(
                  children: [
                    if (_userType == 'student') ...[
                      const SizedBox(height: 50.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateApplicationPage(
                                  postId: post['id'],
                                ),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text('Apply Post',
                                style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (_userId == post['userId']) ...[
                      const SizedBox(height: 50.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewApplicantPage(
                                  post: post,
                                ),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text('View Applicants',
                                style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (_userId == post['userId']) ...[
                      const SizedBox(height: 50.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditPostPage(
                                  post: post,
                                  onUpdate: _refreshPostDetails,
                                ),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text('Edit Post',
                                style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (_userType == 'admin' || _userId == post['userId']) ...[
                      const SizedBox(height: 80.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _showConfirmationDialogDelete(context, 'delete');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text('Delete Post',
                                style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 50.0),
              ],
            ),
          ),
          bottomNavigationBar:
              (_userType == 'admin' && post['status'] == 'pending')
                  ? BottomAppBar(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(
                            onPressed: () {
                              _showConfirmationDialog(
                                  context, 'approved', 'approve');
                            },
                            child: Text(
                              'Approve',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                          VerticalDivider(
                            color: Colors.grey[400],
                            width: 1, // Width of the divider
                          ),
                          TextButton(
                            onPressed: () {
                              _showConfirmationDialog(
                                  context, 'rejected', 'reject');
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
        ));
  }
}
