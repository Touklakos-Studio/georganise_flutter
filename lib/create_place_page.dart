import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'tags_page.dart';
import 'images_page.dart';
import 'secure_storage_manager.dart';
import 'global_config.dart';

class CreatePlacePage extends StatefulWidget {
  final LatLng position; // Make position optional
  final int? selectedImageId;

  const CreatePlacePage({required this.position, this.selectedImageId});

  @override
  _CreatePlacePageState createState() => _CreatePlacePageState();
}

class _CreatePlacePageState extends State<CreatePlacePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  File? _image; // For storing the picked image file
  int? _selectedImageId;
  List<int> _selectedTagIds = []; // Add this line to define _selectedTagIds

  // Function to handle image picking
  Future<void> _pickImage() async {
    final selectedImageId = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ImagesPage(position: widget.position)),
    );

    if (selectedImageId != null) {
      setState(() {
        _selectedImageId = selectedImageId;
      });
    }
  }

  Future<void> _selectTags() async {
    final selectedTagIds = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TagsPage(initialSelectedTagIds: _selectedTagIds),
      ),
    );

    // Check if 'selectedTagIds' is not null to prevent overwriting with null
    if (selectedTagIds != null) {
      setState(() {
        _selectedTagIds = List.from(selectedTagIds);
      });
    }
  }

  bool _validateInputs() {
    return _titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty;
  }

  Future<void> _sendPlaceData(List<int> selectedTagIds) async {
    if (!_validateInputs()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Title and description are required')),
      );
      return;
    }

    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null) {
      debugPrint("Auth token is null");
      return null;
    }

    String baseUrl = GlobalConfig().serverUrl;
    var url = Uri.parse('$baseUrl/api/place');

    Map<String, dynamic> requestBody = {
      "name": _titleController.text,
      "description": _descriptionController.text,
      "latitude": widget.position.latitude,
      "longitude": widget.position.longitude,
      "tagIds": selectedTagIds,
    };

    if (_selectedImageId != null) {
      requestBody["imageId"] = _selectedImageId;
    }

    var response = await http.post(
      url,
      body: json.encode(requestBody),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken',
      },
    );

    if (response.statusCode == 200) {
      debugPrint('Place created successfully');
      final resBody = json.decode(response.body);
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: $resBody');
      Navigator.pop(context, true); // Or navigate as needed
    } else {
      final resBody = json.decode(response.body);
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
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _selectedTagIds.map((tagId) {
                return Chip(
                  label: Text(
                      'Tag $tagId'), // Replace this with the actual tag title
                  deleteIcon: Icon(Icons.cancel),
                  onDeleted: () {
                    setState(() {
                      _selectedTagIds.remove(tagId);
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectTags,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              icon: Icon(Icons.add),
              label: Text('Add a tag'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedImageId != null)
                    Text('Selected image ID: $_selectedImageId')
                  else
                    Text('Pick Image'),
                ],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _sendPlaceData(_selectedTagIds),
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
