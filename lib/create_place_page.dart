import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

class CreatePlacePage extends StatefulWidget {
  final LatLng position;

  const CreatePlacePage({required this.position});

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
    // Parse the user-entered tags
    List<int> tagIds = _tagsController.text
        .split(',')
        .map((tag) => int.tryParse(tag.trim()) ?? 0)
        .toList();

    var url = Uri.parse('http://10.0.2.2:8080/api/place');

    var request = http.MultipartRequest('POST', url);

    // Add the other fields to the request
    request.fields['name'] = _titleController.text;
    request.fields['description'] = _descriptionController.text;
    request.fields['latitude'] = widget.position.latitude.toString();
    request.fields['longitude'] = widget.position.longitude.toString();
    request.fields['tagIds'] = json.encode(tagIds);

    // Add the image file to the request, if it exists
    if (_image != null) {
      var imageStream =
          http.ByteStream(Stream.fromIterable([_image!.readAsBytesSync()]));
      var imageLength = await _image!.length();
      request.files.add(http.MultipartFile('image', imageStream, imageLength,
          filename: _image!.path.split('/').last));
    }

    // Send the request
    var response = await request.send();

    if (response.statusCode == 201) {
      debugPrint('Place created successfully');
      final resBody = await response.stream.bytesToString();
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: $resBody');
      Navigator.pop(context, true); // Or navigate as needed
    } else {
      final resBody = await response.stream.bytesToString();
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
          onPressed: () =>
              Navigator.of(context).pop(false), // Place was not created
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
            Text(
              'Latitude: ${widget.position.latitude}, Longitude: ${widget.position.longitude}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
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
