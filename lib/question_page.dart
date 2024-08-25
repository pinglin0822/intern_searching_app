import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuestionPage extends StatefulWidget {
  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _suggestions = [];
  final String _apiKey = 'sk-X6pD1ld26wH7OgVfLldYTySnjeNb2Wj8EnPJKAO1d2KdSpZO';  // Replace with your OpenAI API key

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
          'model': 'gpt-3.5-turbo',  // Use gpt-3.5-turbo or gpt-4
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant.',
            },
            {
              'role': 'user',
              'content': 'Generate 5 similar keywords for: $query',
            },
          ],
          'max_tokens': 50,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response Data: $data');  // Log the response data for debugging
        final String text = data['choices'][0]['message']['content'].trim();
        final List<String> keywords = text.split('\n');
        setState(() {
          _suggestions = keywords.map((keyword) => keyword.trim()).toList();
        });
      } else {
        print('Failed to generate keywords. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Keyword Generator'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter a keyword',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _generateKeywords(_controller.text);
              },
              child: Text('Generate Keywords'),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_suggestions[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
