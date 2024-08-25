import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';
import 'database_helper.dart';

class ViewApplicantPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const ViewApplicantPage({Key? key, required this.post}) : super(key: key);

  @override
  _ViewApplicantPageState createState() => _ViewApplicantPageState();
}

class _ViewApplicantPageState extends State<ViewApplicantPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _applicants = [];

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    final applicants = await _databaseHelper.getApplicantsForPost(widget.post['id']);
    setState(() {
      _applicants = applicants;
    });
  }

  Future<void> _downloadResume(String resumePath) async {
    try {
      Directory? downloadDirectory;
      if (Platform.isAndroid) {
        downloadDirectory = Directory('/storage/emulated/0/Download');
      }

      if (downloadDirectory != null) {
        String fileName = path.basename(resumePath);
        String newPath = path.join(downloadDirectory.path, fileName);
        File resumeFile = File(resumePath);
        await resumeFile.copy(newPath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resume downloaded to $newPath')),
        );

        // Open the PDF after copying
        final result = await OpenFile.open(newPath);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to open the file')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find download directory')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download resume: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants List'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _applicants.isEmpty
          ? const Center(child: Text('No applicants found', style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              itemCount: _applicants.length,
              itemBuilder: (context, index) {
                final applicant = _applicants[index];

                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicant['name'],
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text('Email: ${applicant['email']}', style: const TextStyle(fontSize: 16, color: Colors.black54)),
                        Text('Contact No: ${applicant['contactNo']}', style: const TextStyle(fontSize: 16, color: Colors.black54)),
                        const SizedBox(height: 12),
                        const Text('Description:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text(applicant['description'] ?? 'No description provided', style: const TextStyle(fontSize: 16, color: Colors.black54)),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () {
                            _downloadResume(applicant['resume']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Download Resume', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
