import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart'; // Import uuid for unique identifiers
import 'database_helper.dart'; // Import your database helper

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  int _userId = 0;
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _lowestSalaryController = TextEditingController();
  final TextEditingController _highestSalaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _registrationNoController = TextEditingController();

  String? _selectedArea; // Variable to store the selected area
  XFile? _image; // Variable to store the selected image

  // List of areas for the dropdown
  final List<String> _areas = [
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
  ];

  // Create an instance of your database helper
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  final ImagePicker _picker = ImagePicker(); // Create an instance of ImagePicker

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage;
    });
  }

  Future<String> _saveImageToFile(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/images/';
    final uniqueName = Uuid().v4(); // Generate a unique name
    final file = File('${path}${uniqueName}_${image.name}');
    await file.create(recursive: true); // Ensure the directory exists
    await file.writeAsBytes(await image.readAsBytes());
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Form key for validation
          child: ListView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Job Title', style: TextStyle(fontSize: 16.0)),
                  SizedBox(height: 8.0),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a job title';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Company Name', style: TextStyle(fontSize: 16.0)),
                  SizedBox(height: 8.0),
                  TextFormField(
                    controller: _companyNameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a company name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Registration Number', style: TextStyle(fontSize: 16.0)),
                  SizedBox(height: 8.0),
                  TextFormField(
                    controller: _registrationNoController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a registration number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Image Upload', style: TextStyle(fontSize: 16.0)),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _pickImage,
                          child: Text('Pick Image'),
                        ),
                      ),
                      SizedBox(width: 16.0),
                      if (_image != null)
                        Text(
                          'Image Selected: ${_image!.name}', // Show the image file name
                          style: TextStyle(fontSize: 16.0),
                        ),
                    ],
                  ),
                  if (_image != null) 
                    Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Image.file(
                        File(_image!.path),
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Job Area', style: TextStyle(fontSize: 16.0)),
                  SizedBox(height: 8.0),
                  DropdownButtonFormField<String>(
                    value: _selectedArea,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _areas.map((String area) {
                      return DropdownMenuItem<String>(
                        value: area,
                        child: Text(area),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedArea = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a job area';
                      }
                      return null;
                    },
                    hint: Text('Select Area'),
                  ),
                  SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Salary', style: TextStyle(fontSize: 16.0)),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      Text('From ', style: TextStyle(fontSize: 16.0)),
                      Expanded(
                        child: TextFormField(
                          controller: _lowestSalaryController,
                          decoration: InputDecoration(
                            labelText: 'Lowest Salary',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the lowest salary';
                            }
                            return null;
                          },
                        ),
                      ),
                      Text(' to ', style: TextStyle(fontSize: 16.0)),
                      Expanded(
                        child: TextFormField(
                          controller: _highestSalaryController,
                          decoration: InputDecoration(
                            labelText: 'Highest Salary',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the highest salary';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Job Description', style: TextStyle(fontSize: 16.0)),
                  SizedBox(height: 8.0),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a job description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Longitude', style: TextStyle(fontSize: 16.0)),
                  SizedBox(height: 8.0),
                  TextFormField(
                    controller: _longitudeController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the longitude';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Latitude', style: TextStyle(fontSize: 16.0)),
                  SizedBox(height: 8.0),
                  TextFormField(
                    controller: _latitudeController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the latitude';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Save the image file to the app's directory
                    String imageName = '';
                    if (_image != null) {
                      imageName = await _saveImageToFile(_image!);
                    }

                    // Collect form data
                    final post = {
                      'title': _titleController.text,
                      'imageName': imageName, // Use the unique image file name
                      'userId': _userId, // Replace with actual userId if available
                      'companyName': _companyNameController.text,
                      'lowestSalary': double.tryParse(_lowestSalaryController.text) ?? 0,
                      'highestSalary': double.tryParse(_highestSalaryController.text) ?? 0,
                      'description': _descriptionController.text,
                      'area': _selectedArea ?? '',
                      'longitude': double.tryParse(_longitudeController.text) ?? 0,
                      'latitude': double.tryParse(_latitudeController.text) ?? 0,
                      'status': 'pending', // Default status
                      'registration_no': _registrationNoController.text,
                    };

                    // Save post using the insertPost method from DatabaseHelper
                    await _databaseHelper.insertPost(post);

                    // Show a confirmation message or navigate back
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Post saved successfully!')),
                    );

                    // Optionally, navigate back to the previous screen
                    Navigator.pop(context,true);
                  }
                },
                child: Text('Save Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
