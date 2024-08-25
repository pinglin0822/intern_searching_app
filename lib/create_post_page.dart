import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';
import 'my_post.dart';
// Import Google Maps package
import 'package:geocoding/geocoding.dart'; // Import for geocoding (converting address to coordinates)
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:google_places_autocomplete_text_field/model/prediction.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  int _userId = 0;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _lowestSalaryController = TextEditingController();
  final TextEditingController _highestSalaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _registrationNoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController(); // New controller for the address

  String? _selectedArea;
  XFile? _image;

  final List<String> _areas = [
    'Johor', 'Kedah', 'Kelantan', 'Kuala Lumpur', 'Melaka', 'Negeri Sembilan',
    'Pahang', 'Perak', 'Perlis', 'Penang', 'Sabah', 'Sarawak', 'Selangor', 'Terengganu',
  ];

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final ImagePicker _picker = ImagePicker();

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
    final uniqueName = const Uuid().v4();
    final file = File('$path${uniqueName}_${image.name}');
    await file.create(recursive: true);
    await file.writeAsBytes(await image.readAsBytes());
    return file.path;
  }

  Future<void> _getCoordinatesFromAddress() async {
    try {
      List<Location> locations = await locationFromAddress(_addressController.text);
      if (locations.isNotEmpty) {
        setState(() {
          _latitudeController.text = locations[0].latitude.toString();
          _longitudeController.text = locations[0].longitude.toString();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No coordinates found for this address')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error finding address')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: 
              Column(
                children: [
                  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Job Title', style: TextStyle(fontSize: 16.0)),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a job title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Company Name', style: TextStyle(fontSize: 16.0)),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _companyNameController,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a company name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Registration Number', style: TextStyle(fontSize: 16.0)),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _registrationNoController,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a registration number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Image Upload', style: TextStyle(fontSize: 16.0)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _pickImage,
                          child: const Text('Pick Image'),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      if (_image != null)
                        Text(
                          '${_image!.name}',
                          style: const TextStyle(fontSize: 16.0),
                        ),
                    ],
                  ),
                  if (_image != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Image.file(
                        File(_image!.path),
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Job Area', style: TextStyle(fontSize: 16.0)),
                  const SizedBox(height: 8.0),
                  DropdownButtonFormField<String>(
                    value: _selectedArea,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
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
                    hint: const Text('Select Area'),
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Salary', style: TextStyle(fontSize: 16.0)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Text('From ', style: TextStyle(fontSize: 16.0)),
                      Expanded(
                        child: TextFormField(
                          controller: _lowestSalaryController,
                          decoration: const InputDecoration(
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
                      const Text(' to ', style: TextStyle(fontSize: 16.0)),
                      Expanded(
                        child: TextFormField(
                          controller: _highestSalaryController,
                          decoration: const InputDecoration(
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
                  const SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Job Description', style: TextStyle(fontSize: 16.0)),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a job description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Address', style: TextStyle(fontSize: 16.0)),
                  const SizedBox(height: 8.0),
                  GooglePlacesAutoCompleteTextFormField(
                textEditingController: _addressController,
                googleAPIKey: "AIzaSyBUjSAHP6GNjLJCYQe02yCu5wbZiNLznA4",
                decoration: const InputDecoration(
                  hintText: 'Enter your address',
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
                // proxyURL: _yourProxyURL,
                maxLines: 1,
                overlayContainer: (child) => Material(
                  elevation: 1.0,
                  //color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                ),
                getPlaceDetailWithLatLng: (prediction) {
                  print('placeDetails${prediction.lng}');
                },
                itmClick: (Prediction prediction) =>
                    _addressController.text = prediction.description!,
              ),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: _getCoordinatesFromAddress,
                    child: const Text('Get Coordinates'),
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Latitude', style: TextStyle(fontSize: 16.0)),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a latitude';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Longitude', style: TextStyle(fontSize: 16.0)),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a longitude';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String? imagePath;
                    if (_image != null) {
                      imagePath = await _saveImageToFile(_image!);
                    }

                    final post = {
                      'userId': _userId,
                      'title': _titleController.text ?? "error",
                      'companyName': _companyNameController.text ?? 'error',
                      'lowestSalary': int.parse(_lowestSalaryController.text) ?? 0,
                      'highestSalary': int.parse(_highestSalaryController.text) ?? 0,
                      'description': _descriptionController.text ?? 'error',
                      'longitude': double.parse(_longitudeController.text) ?? 0,
                      'latitude': double.parse(_latitudeController.text) ?? 0,
                      'registration_no': _registrationNoController.text ?? 'error',
                      'status': 'pending',
                      'area': _selectedArea ?? 'error',
                      'imageName': imagePath,
                    };

                    await _databaseHelper.insertPost(post);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MyPostPage()),
                    );
                  }
                },
                child: const Text('Create Post'),
              ),
            ],
              )
              
          ),
        ),
      ),
    );
  }
}
