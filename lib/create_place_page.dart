import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';

class CreatePlacePage extends StatefulWidget {
  @override
  _CreatePlacePageState createState() => _CreatePlacePageState();
}

class _CreatePlacePageState extends State<CreatePlacePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  File? _image; // For storing the picked image file

  // Function to handle image picking
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _sendPlaceData() async {
    var url = Uri.parse(
        'https://jsonplaceholder.typicode.com/posts'); // TODO : Replace with your API endpoint

    var request = http.MultipartRequest('POST', url)
      ..fields['title'] = _titleController.text
      ..fields['description'] = _descriptionController.text
      ..fields['tags'] = _tagsController.text;

    if (_image != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _image!.path,
      ));
    }

    var response = await request.send();

    if (response.statusCode == 201) {
      // Adjusted to expect 200 OK from JSONPlaceholder
      debugPrint('Place created successfully');
      final resBody = await response.stream.bytesToString();
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: $resBody');
      Navigator.pop(context); // Or navigate as needed
    } else {
      final resBody =
          await response.stream.bytesToString(); // Retrieve the response body
      debugPrint('Failed to create place');
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: $resBody');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while creating the place')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Place',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'Tags',
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  image: _image != null
                      ? DecorationImage(
                          image: FileImage(_image!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _image == null
                    ? Center(child: Icon(Icons.image, size: 50))
                    : null,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendPlaceData,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              child: Text(
                'Create Place',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
