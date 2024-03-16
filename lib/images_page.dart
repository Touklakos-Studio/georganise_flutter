import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'secure_storage_manager.dart';
import 'create_place_page.dart';
import 'package:latlong2/latlong.dart';

class ImagesPage extends StatefulWidget {
  final LatLng position;

  const ImagesPage({required this.position});

  @override
  _ImagesPageState createState() => _ImagesPageState();
}

class _ImagesPageState extends State<ImagesPage> {
  List<dynamic> _images = [];
  int? _selectedImageId; // Holds the ID of the currently selected image
  final TextEditingController _imageTitleController = TextEditingController();
  final TextEditingController _imageDescriptionController =
      TextEditingController();
  bool _isPublic = true;
  File? _imageFile; // Holds the file for an image picked from the gallery
  bool _showPopup = false; // Controls visibility of the popup

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    try {
      String? authToken = await SecureStorageManager.getAuthToken();
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/image'),
        headers: {'Cookie': 'authToken=$authToken'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _images = json.decode(response.body);
        });
      } else {
        debugPrint('Failed to fetch images');
      }
    } catch (e) {
      debugPrint('An error occurred while fetching images: $e');
    }
  }

  void _toggleImageSelection(int imageId) {
    setState(() {
      _selectedImageId = (_selectedImageId == imageId) ? null : imageId;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _createImage() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    try {
      String? authToken = await SecureStorageManager.getAuthToken();

      List<int> imageBytes = await _imageFile!.readAsBytesSync();
      String base64Image = base64Encode(imageBytes);

      var request = http.MultipartRequest(
          'POST', Uri.parse('http://10.0.2.2:8080/api/image'));
      request.headers['Cookie'] = 'authToken=$authToken';
      request.fields['name'] = _imageTitleController.text;
      request.fields['description'] = _imageDescriptionController.text;
      request.fields['isPublic'] = _isPublic.toString();
      request.fields['imageValue'] = base64Image;

      final response = await request.send();

      if (response.statusCode == 200) {
        _imageTitleController.clear();
        _imageDescriptionController.clear();
        setState(() {
          _imageFile = null;
        });
        await _fetchImages(); // Refresh the list of images
      } else {
        debugPrint('Failed to create image');
      }
    } catch (e) {
      debugPrint('An error occurred while creating an image: $e');
    }
  }

  Widget _buildPopup() {
    if (_selectedImageId == null) return SizedBox.shrink(); // Safety check

    final selectedImage = _images.firstWhere(
        (image) => image['imageId'] == _selectedImageId,
        orElse: () => null);
    if (selectedImage == null) return SizedBox.shrink(); // Safety check

    String base64Image = selectedImage['imageValue'];
    if (base64Image.startsWith('data:image')) {
      base64Image = base64Image.split(',')[1];
    }
    final decodedBytes = base64Decode(base64Image);

    return AlertDialog(
      content: Image.memory(decodedBytes, fit: BoxFit.cover),
      actions: <Widget>[
        TextButton(
          child: Text('Close'),
          onPressed: () => setState(() => _showPopup = false),
        ),
        ElevatedButton(
          child: Text('Select this image'),
          onPressed: () {
            Navigator.pop(context, _selectedImageId);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Images'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _imageTitleController,
                decoration: InputDecoration(
                  labelText: 'Image Title',
                  hintText: 'Enter the title of the image',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _imageDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Image Description',
                  hintText: 'Enter a description for the image',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Public'),
                  Switch(
                    value: _isPublic,
                    onChanged: (bool newValue) {
                      setState(() {
                        _isPublic = newValue;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text('Pick Image'),
              ),
              SizedBox(height: 16),
              if (_imageFile != null)
                _imageFile != null
                    ? Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text("No image selected."),
              if (_imageFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: _createImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: Text('Upload Image'),
                  ),
                ),
              SizedBox(height: 16),
              Text(
                'Your Images',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final image = _images[index];
                    String base64Image = image['imageValue'];
                    if (base64Image.startsWith('data:image')) {
                      base64Image = base64Image.split(',')[1];
                    }
                    final decodedBytes = base64Decode(base64Image);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageId = image['imageId'];
                          _showPopup = true;
                        });
                      },
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: Image.memory(
                              decodedBytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Text(
                            image['name'] ?? 'No Title',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            image['description'] ?? 'No Description',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          if (_selectedImageId == image['imageId'])
                            Icon(Icons.check_circle, color: Colors.green),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedImageId != null) {
            Navigator.pop(context, _selectedImageId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please select an image first')),
            );
          }
        },
        child: Icon(Icons.check),
      ),
      bottomSheet: _showPopup ? _buildPopup() : null,
    );
  }
}
