import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'widgets/sidebar.dart';
import 'post_detail_page.dart';

class MainPage extends StatefulWidget {
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
      _type = prefs.getString('userType') ?? '';
    });
  }

  Future<void> _loadPosts() async {
    List<Map<String, dynamic>> posts = await _databaseHelper.fetchPosts();
    setState(() {
      _posts = posts.where((post) => post['status'] == 'approved').toList();
      _filteredPosts = _posts;
      _isLoading = false; // Set loading to false after data is loaded
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
          title: Text('Filter Posts'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Area:'),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedArea.isNotEmpty ? _selectedArea : null,
                  hint: Text('Select Area'),
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
                SizedBox(height: 16.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Minimum Salary:'),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: _minSalaryController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
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
              child: Text('Apply'),
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
              child: Text('Reset'),
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
        title: Text('Main Page'),
      ),
      drawer: AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search posts...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: _filterPosts,
                  ),
                ),
                SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(Icons.filter_list, size: 30),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredPosts.isNotEmpty
                    ? ListView.builder(
                        itemCount: _filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = _filteredPosts[index];
                          return Column(
                            children: [
                              ListTile(
                                leading: Image.asset(
                                  'lib/image/${post['imageName']}',
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_right, size: 30),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PostDetailPage(post: post),
                                    ),
                                  );
                                },
                              ),
                              Divider(
                                height: 5,
                                thickness: 2,
                              ),
                            ],
                          );
                        },
                      )
                    : Center(
                        child: Text('No posts found'),
                      ),
          ),
        ],
      ),
    );
  }
}
