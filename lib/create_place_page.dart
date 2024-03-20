import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'tags_page.dart';
import 'images_page.dart';
import 'secure_storage_manager.dart';
import 'global_config.dart';
import 'place.dart';

class CreatePlacePage extends StatefulWidget {
  final LatLng position;
  final int? selectedImageId;
  final Place? placeToEdit;

  const CreatePlacePage({
    super.key,
    required this.position,
    this.selectedImageId,
    this.placeToEdit,
  });

  @override
  _CreatePlacePageState createState() => _CreatePlacePageState();
}

class _CreatePlacePageState extends State<CreatePlacePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  File? _image;
  int? _selectedImageId;
  List<int> _selectedTagIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.placeToEdit != null) {
      _titleController.text = widget.placeToEdit!.name;
      _descriptionController.text = widget.placeToEdit!.description;
      _latitudeController.text = widget.placeToEdit!.latitude.toString();
      _longitudeController.text = widget.placeToEdit!.longitude.toString();
      _selectedImageId = widget.placeToEdit!.imageId;

      // Assume placeTags contains placeTagIds
      _fetchTagIds(widget.placeToEdit!.placeTags)
          .then((tagIds) => setState(() => _selectedTagIds = tagIds));
      debugPrint(_selectedTagIds.toString());
    }
  }

  // Retrieve tagIds from placeTagIds
  Future<List<int>> _fetchTagIds(List<dynamic> placeTagIds) async {
    List<int> tagIds = [];
    String baseUrl = GlobalConfig().serverUrl;
    String? authToken = await SecureStorageManager.getAuthToken();

    for (var placeTag in placeTagIds) {
      // Correctly extract placeTagId from the map
      var placeTagId = placeTag['placeTagId']; // Assuming placeTag is a Map

      final response = await http.get(
        Uri.parse('$baseUrl/api/tag/placeTag/$placeTagId'),
        headers: {'Cookie': 'authToken=$authToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['tagId'] != null) {
          tagIds.add(data['tagId']);
        }
      } else {
        // Handle error or add some error logging
        debugPrint(
            'Failed to fetch tagId for placeTagId $placeTagId: ${response.body}');
      }
    }

    return tagIds;
  }

  // Create a new place or update an existing place
  Future<void> _submitPlaceData() async {
    if (!_validateInputs()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and description are required')),
      );
      return;
    }

    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null) {
      debugPrint("Auth token is null");
      return;
    }

    String baseUrl = GlobalConfig().serverUrl;
    String url = widget.placeToEdit == null
        ? '$baseUrl/api/place'
        : '$baseUrl/api/place/${widget.placeToEdit!.placeId}';

    Map<String, dynamic> requestBody = {
      "name": _titleController.text,
      "description": _descriptionController.text,
      "latitude": _latitudeController.text.isNotEmpty
          ? double.parse(_latitudeController.text)
          : widget.position.latitude,
      "longitude": _longitudeController.text.isNotEmpty
          ? double.parse(_longitudeController.text)
          : widget.position.longitude,
      "realtime": false,
    };

    if (_selectedTagIds.isNotEmpty) {
      requestBody["tagIds"] = _selectedTagIds;
    } else {
      requestBody["tagIds"] = [];
    }

    if (_selectedImageId != null) {
      requestBody["imageId"] = _selectedImageId;
    }

    var response = await (widget.placeToEdit == null
        ? http.post(Uri.parse(url), body: json.encode(requestBody), headers: {
            'Content-Type': 'application/json',
            'Cookie': 'authToken=$authToken',
          })
        : http.put(Uri.parse(url), body: json.encode(requestBody), headers: {
            'Content-Type': 'application/json',
            'Cookie': 'authToken=$authToken',
          }));

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('Place submitted successfully');
      Navigator.pop(context, true);
    } else {
      debugPrint('Failed to submit place. Status code: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred while submitting the place')),
      );
    }
  }

  // Pick an image from the gallery
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

  // Select tags for the place
  Future<void> _selectTags() async {
    final selectedTagIds = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              TagsPage(initialSelectedTagIds: _selectedTagIds)),
    );

    if (selectedTagIds != null) {
      setState(() {
        _selectedTagIds = List.from(selectedTagIds);
      });
    }
  }

  // Validate the input fields
  bool _validateInputs() {
    return _titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String pageTitle =
        widget.placeToEdit == null ? 'Create Place' : 'Edit Place';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          pageTitle,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.placeToEdit != null) ...[
              TextField(
                controller: _latitudeController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  fillColor: Colors.white,
                  filled: true,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _longitudeController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  fillColor: Colors.white,
                  filled: true,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _selectedTagIds.map((tagId) {
                return Chip(
                  label: Text('Tag $tagId'),
                  deleteIcon: const Icon(Icons.cancel),
                  onDeleted: () {
                    setState(() {
                      _selectedTagIds.remove(tagId);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectTags,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add a tag'),
            ),
            const SizedBox(height: 16),
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
                    const Text('Pick Image'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _submitPlaceData,
              child: const Icon(Icons.arrow_forward, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
