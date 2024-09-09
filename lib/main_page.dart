import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'widgets/sidebar.dart';
import 'post_detail_page.dart';
import 'create_post_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _username = '';
  String _type = '';
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _filteredPosts = [];
  bool _isLoading = true; // New state variable to track loading state
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  String _selectedArea = '';
  double _minSalary = 0;
  final TextEditingController _minSalaryController =
      TextEditingController(text: '0');
  String _statusText = '';
  List<String> _suggestions = [];
  final String _apiKey = 'sk-X6pD1ld26wH7OgVfLldYTySnjeNb2Wj8EnPJKAO1d2KdSpZO';

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
      _type = prefs.getString('userType') ?? '';
    });
  }

  Future<void> _loadPosts() async {
    List<Map<String, dynamic>> posts = await _databaseHelper.fetchPosts();
    setState(() {
      _posts = posts
          .where((post) => post['status'] == 'approved')
          .toList()
          .cast<Map<String, dynamic>>()
        ..sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      _filteredPosts = _posts;
      _isLoading = false; // Set loading to false after data is loaded
    });
  }

  void _filterPosts() async {
    final query = _searchController.text;
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
        final isInAreaFilter =
            _selectedArea.isEmpty || areaLower == _selectedArea;

        return (isInTitle || isInCompanyName || isInArea) &&
            isInSalaryRange &&
            isInAreaFilter;
      }).toList();
    });
    if (query.isNotEmpty) {
      await _generateKeywords(query);
    }
  }

  Future<void> _generateKeywords(String query) async {
    final url = Uri.parse('https://api.chatanywhere.tech/v1/chat/completions');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo', // Use gpt-3.5-turbo or gpt-4
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant.',
            },
            {
              'role': 'user',
              'content': 'Generate 5 similar job title keywords for: $query,just give me the list',
            },
          ],
          'max_tokens': 50,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response Data: $data'); // Log the response data for debugging
        final String text = data['choices'][0]['message']['content'].trim();
        final List<String> keywords = text.split('\n');
        setState(() {
          _suggestions = keywords.map((keyword) => keyword.trim()).toList();
          _statusText =
          "Keywords that you may also interested: ${_suggestions.join(', ')}";
      if (query.isEmpty) {
        _statusText = '';
      }
        });
      } else {
        print(
            'Failed to generate keywords. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
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
                      value:
                          area.toLowerCase() == 'any' ? '' : area.toLowerCase(),
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
                _filterPosts();
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
                _filterPosts();
              },
              child: const Text('Reset'),
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
        title: const Text('Main Page'),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search posts...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4.0),
                IconButton(
                  icon: const Icon(Icons.search, size: 30),
                  onPressed: _filterPosts,
                ),
                const SizedBox(width: 4.0),
                IconButton(
                  icon: const Icon(Icons.filter_list, size: 30),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ),
          _statusText.isNotEmpty ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            color: Colors.yellow[100], // Light yellow background color
            child: Text(
              _statusText,
              style: const TextStyle(
                fontSize: 16.0,
              ),
            ),
          ):Container(),
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
                          final imagePath = post['imageName'];
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
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PostDetailPage(post: post),
                                    ),
                                  );
                                  if (result == true) {
                                    // Refresh the posts if the result indicates that new data was added
                                    _loadPosts();
                                  }
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
      floatingActionButton: (_type == 'admin' || _type == 'employer')
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePostPage(),
                  ),
                );
                if (result == true) {
                  // Refresh the posts if the result indicates that new data was added
                  _loadPosts();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
