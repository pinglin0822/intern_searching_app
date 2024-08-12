import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';

class CreateApplicationPage extends StatefulWidget {
  final int postId;

  CreateApplicationPage({required this.postId});

  @override
  _CreateApplicationPageState createState() => _CreateApplicationPageState();
}

class _CreateApplicationPageState extends State<CreateApplicationPage> {
  int _userId = 0;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactNoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _resume;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

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

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _resume = File(result.files.single.path!);
      });
    }
  }

  Future<String> _saveResumeToFile(File resume) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/resumes/';
      final uniqueName = Uuid().v4();
      final file = File('$path${uniqueName}_${resume.path.split('/').last}');
      await file.create(recursive: true);
      await file.writeAsBytes(await resume.readAsBytes());
      return file.path;
    } catch (e) {
      print('Error saving resume: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apply for Job'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Name', style: TextStyle(fontSize: 16.0)),
              SizedBox(height: 8.0),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              Text('Contact Number', style: TextStyle(fontSize: 16.0)),
              SizedBox(height: 8.0),
              TextFormField(
                controller: _contactNoController,
                decoration: InputDecoration(border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your contact number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              Text('Email', style: TextStyle(fontSize: 16.0)),
              SizedBox(height: 8.0),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              Text('Resume', style: TextStyle(fontSize: 16.0)),
              SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickResume,
                      child: Text('Upload Resume'),
                    ),
                  ),
                  SizedBox(width: 16.0),
                  if (_resume != null)
                    Text(
                      '${_resume!.path.split('/').last}',
                      style: TextStyle(fontSize: 16.0),
                    ),
                ],
              ),
              SizedBox(height: 16.0),
              Text('Description', style: TextStyle(fontSize: 16.0)),
              SizedBox(height: 8.0),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(border: OutlineInputBorder()),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a brief description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String resumePath = '';
                    if (_resume != null) {
                      try {
                        resumePath = await _saveResumeToFile(_resume!);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save resume: $e')),
                        );
                        return;
                      }
                    }

                    final application = {
                      'postId': widget.postId,
                      'userId': _userId,
                      'name': _nameController.text,
                      'resume': resumePath,
                      'contactNo': _contactNoController.text,
                      'email': _emailController.text,
                      'description': _descriptionController.text,
                    };

                    await _databaseHelper.insertApplicant(application);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Application submitted successfully!')),
                    );

                    Navigator.pop(context);
                  }
                },
                child: Text('Submit Application'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
