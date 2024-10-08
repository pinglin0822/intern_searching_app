import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'widgets/sidebar.dart';
import 'post_detail_page.dart';

class ManagePostPage extends StatefulWidget {
  const ManagePostPage({Key? key}) : super(key: key);

  @override
  _ManagePostPageState createState() => _ManagePostPageState();
}

class _ManagePostPageState extends State<ManagePostPage> {
  String _username = '';
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _filteredPosts = [];
  bool _isLoading = true;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  String _selectedArea = '';
  double _minSalary = 0;
  final TextEditingController _minSalaryController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadSessionData();
    _loadPosts();
  }

  Future<void> _loadSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
    });
  }

  Future<void> _loadPosts() async {
    List<Map<String, dynamic>> posts = await _databaseHelper.fetchPosts();
    setState(() {
      _posts = posts
        .where((post) => post['status'] == 'pending')
        .toList()
        .cast<Map<String, dynamic>>()
        ..sort((a, b) => (b['id'] as int).compareTo(a['id'] as int)); // Sort by descending ID
      _filteredPosts = _posts;
      _isLoading = false;
    });
  }

  void _filterPosts(String query) {
    setState(() {
      _filteredPosts = _posts.where((post) {
        final titleLower = post['title'].toLowerCase();
        final companyNameLower = post['companyName'].toLowerCase();
        final areaLower = post['area'].toLowerCase();
        final searchLower = query.toLowerCase();

        final isInTitle = titleLower.contains(searchLower);
        final isInCompanyName = companyNameLower.contains(searchLower);
        final isInArea = areaLower.contains(searchLower);
        final isInSalaryRange = post['lowestSalary'] >= _minSalary;
        final isInAreaFilter = _selectedArea.isEmpty || areaLower == _selectedArea;

        return (isInTitle || isInCompanyName || isInArea) &&
               isInSalaryRange &&
               isInAreaFilter;
      }).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Posts'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Area:'),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedArea.isNotEmpty ? _selectedArea : null,
                  hint: const Text('Select Area'),
                  items: [
                    'Any',
                    'Johor',
                    'Kedah',
                    'Kelantan',
                    'Kuala Lumpur',
                    'Melaka',
                    'Negeri Sembilan',
                    'Pahang',
                    'Perak',
                    'Perlis',
                    'Penang',
                    'Sabah',
                    'Sarawak',
                    'Selangor',
                    'Terengganu',
                  ].map((area) {
                    return DropdownMenuItem<String>(
                      value: area.toLowerCase() == 'any' ? '' : area.toLowerCase(),
                      child: Text(area),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedArea = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Minimum Salary:'),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _minSalaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min Salary',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _minSalary = double.tryParse(value) ?? 0;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _filterPosts(_searchController.text);
              },
              child: const Text('Apply'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedArea = '';
                  _minSalary = 0;
                  _minSalaryController.text = _minSalary.toString();
                });
                _filterPosts(_searchController.text);
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToPostDetail(Map<String, dynamic> post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailPage(post: post),
      ),
    );

    if (result == true) {
      // Refresh posts if the result indicates that there was a change
      _loadPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Posts'),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search posts...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: _filterPosts,
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.filter_list, size: 30),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredPosts.isNotEmpty
                    ? ListView.builder(
                        itemCount: _filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = _filteredPosts[index];
                          final imagePath = post['imageName']?? 'lib/image/no_Image.jpg';
                          final file = File(imagePath);
                          return Column(
                            children: [
                              ListTile(
                                leading: Image.file(
                                  file,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'lib/image/no_Image.jpg',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                                title: Text(post['title']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post['companyName']),
                                    Text(post['area']),
                                  ],
                                ),
                                trailing: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_right, size: 30),
                                  ],
                                ),
                                onTap: () {
                                  _navigateToPostDetail(post);
                                },
                              ),
                              const Divider(
                                height: 5,
                                thickness: 2,
                              ),
                            ],
                          );
                        },
                      )
                    : const Center(
                        child: Text('No posts found'),
                      ),
          ),
        ],
      ),
    );
  }
}
