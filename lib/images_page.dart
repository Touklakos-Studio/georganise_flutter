import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'secure_storage_manager.dart';
import 'create_place_page.dart';
import 'package:latlong2/latlong.dart';
import 'global_config.dart';

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
      String baseUrl = GlobalConfig().serverUrl;
      String? authToken = await SecureStorageManager.getAuthToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/image'),
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
      String baseUrl = GlobalConfig().serverUrl;

      String? authToken = await SecureStorageManager.getAuthToken();

      List<int> imageBytes = await _imageFile!.readAsBytesSync();
      String base64Image = base64Encode(imageBytes);

      Map<String, dynamic> body = {
        'name': _imageTitleController.text,
        'description': _imageDescriptionController.text,
        'isPublic': _isPublic,
        'imageValue': base64Image,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/image'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken',
        },
        body: json.encode(body),
      );

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
    if (_selectedImageId == null) return SizedBox.shrink();

    final selectedImage = _images.firstWhere(
      (image) => image['imageId'] == _selectedImageId,
      orElse: () => null,
    );
    if (selectedImage == null) return SizedBox.shrink();

    String base64Image = selectedImage['imageValue'];
    if (base64Image.startsWith('data:image')) {
      base64Image = base64Image.split(',')[1];
    }
    final decodedBytes = base64Decode(base64Image);

    return AlertDialog(
      title: Text(selectedImage['name'] ?? 'No Title'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.memory(decodedBytes, fit: BoxFit.cover),
            SizedBox(height: 10),
            Text("ID: ${selectedImage['imageId']}",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(selectedImage['description'] ?? 'No Description'),
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton.icon(
          icon: Icon(Icons.edit, color: Colors.white),
          label: Text('Edit', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0)),
            elevation: 5.0,
          ),
          onPressed: () {
            _editImage(selectedImage);
          },
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.delete, color: Colors.white),
          label: Text('Delete', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0)),
            elevation: 5.0,
          ),
          onPressed: () {
            _confirmDeleteImage(selectedImage['imageId']);
          },
        ),
        ElevatedButton(
          child:
              Text('Select this image', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0)),
            elevation: 5.0,
          ),
          onPressed: () {
            Navigator.pop(context, _selectedImageId);
          },
        ),
        ElevatedButton(
          child: Text('Close', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0)),
            elevation: 5.0,
          ),
          onPressed: () => setState(() => _showPopup = false),
        ),
      ],
    );
  }

  Future<void> _deleteImage(int imageId) async {
    try {
      String baseUrl = GlobalConfig().serverUrl;
      String? authToken = await SecureStorageManager.getAuthToken();

      final response = await http.delete(
        Uri.parse('$baseUrl/api/image/$imageId'),
        headers: {'Cookie': 'authToken=$authToken'},
      );

      if (response.statusCode == 200) {
        // Image deleted successfully
        debugPrint('Image deleted successfully');
        await _fetchImages(); // Refresh the list of images
      } else {
        // Failed to delete image
        debugPrint('Failed to delete image');
      }
    } catch (e) {
      // An error occurred while deleting the image
      debugPrint('An error occurred while deleting the image: $e');
    }
  }

  Future<void> _confirmDeleteImage(int imageId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button for close dialog
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this image?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                _deleteImage(imageId); // Call the delete method
              },
            ),
          ],
        );
      },
    );
  }

  void _editImage(dynamic selectedImage) {
    _imageTitleController.text = selectedImage['name'] ?? '';
    _imageDescriptionController.text = selectedImage['description'] ?? '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Image Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _imageTitleController,
                decoration: InputDecoration(
                  labelText: 'Image Title',
                ),
              ),
              TextField(
                controller: _imageDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Image Description',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () async {
                await _updateImage(
                  selectedImage['imageId'],
                  _imageTitleController.text,
                  _imageDescriptionController.text,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateImage(
      int imageId, String name, String description) async {
    try {
      String baseUrl = GlobalConfig().serverUrl;
      String? authToken = await SecureStorageManager.getAuthToken();

      final response = await http.put(
        Uri.parse('$baseUrl/api/image/$imageId'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'isPublic': true, // You can modify this as needed
        }),
      );

      if (response.statusCode == 200) {
        // Image information updated successfully
        debugPrint('Image information updated successfully');
        await _fetchImages(); // Refresh the list of images
      } else {
        debugPrint('Failed to update image information');
        debugPrint('Response: ${response.body}');
        debugPrint('Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('An error occurred while updating image information: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Images',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
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
                child:
                    Text('Pick Image', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 16),
              if (_imageFile != null)
                _imageFile != null
                    ? Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green),
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
                      backgroundColor: Colors.green,
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
                      child: GridTile(
                        footer: Material(
                          color: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(4)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: GridTileBar(
                            backgroundColor: Colors.black45,
                            title: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                image['name'] ?? 'No Title',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            subtitle: Text(
                              'ID: ${image['imageId']}',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        child: Image.memory(
                          decodedBytes,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _showPopup ? _buildPopup() : null,
    );
  }
}
