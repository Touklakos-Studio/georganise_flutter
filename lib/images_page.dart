import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'secure_storage_manager.dart';
import 'package:latlong2/latlong.dart';
import 'global_config.dart';

class ImagesPage extends StatefulWidget {
  final LatLng position;

  const ImagesPage({super.key, required this.position});

  @override
  _ImagesPageState createState() => _ImagesPageState();
}

class _ImagesPageState extends State<ImagesPage> {
  List<dynamic> _images = [];
  int? _selectedImageId; // Holds the ID of the currently selected image
  final TextEditingController _imageTitleController = TextEditingController();
  final TextEditingController _imageDescriptionController =
      TextEditingController();
  final TextEditingController _searchController =
      TextEditingController(); // Search controller
  bool _isPublic = true;
  File? _imageFile; // Holds the file for an image picked from the gallery
  bool _showPopup = false; // Controls visibility of the popup
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchImages();
    _fetchUserId().then((userId) {
      setState(() {
        _currentUserId = userId;
      });
    });
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
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    // Check if title or description is empty
    if (_imageTitleController.text.isEmpty ||
        _imageDescriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and description cannot be empty.'),
          backgroundColor:
              Colors.red, // Make the background color red to indicate an error
        ),
      );
      return; // Stop execution if validation fails
    }

    try {
      String baseUrl = GlobalConfig().serverUrl;
      String? authToken = await SecureStorageManager.getAuthToken();

      List<int> imageBytes = _imageFile!.readAsBytesSync();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image created successfully'),
          ),
        );
        await _fetchImages(); // Refresh the list of images
      } else {
        debugPrint('Failed to create image');
      }
    } catch (e) {
      debugPrint('An error occurred while creating an image: $e');
    }
  }

  Future<void> _searchImages(String keyword) async {
    if (keyword.trim().isEmpty) {
      // If the search query is empty, fetch all images instead.
      await _fetchImages();
      return;
    }

    try {
      String baseUrl = GlobalConfig().serverUrl;
      String? authToken = await SecureStorageManager.getAuthToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/image/keyword/$keyword'),
        headers: {'Cookie': 'authToken=$authToken'},
      );

      if (response.statusCode == 200) {
        debugPrint('Fetched images for the keyword: $keyword');
        setState(() {
          _images = json.decode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to fetch images for the keyword: $keyword')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while fetching images: $e')),
      );
    }
  }

  Widget _buildPopup() {
    if (_selectedImageId == null) return const SizedBox.shrink();

    final selectedImage = _images.firstWhere(
      (image) => image['imageId'] == _selectedImageId,
      orElse: () => null,
    );
    if (selectedImage == null) return const SizedBox.shrink();

    // Check if the current user is the owner of the image
    bool isUserImageOwner = _currentUserId == selectedImage['userId'];

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
            const SizedBox(height: 10),
            Text("ID: ${selectedImage['imageId']}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(selectedImage['description'] ?? 'No Description'),
          ],
        ),
      ),
      actions: <Widget>[
        if (isUserImageOwner)
          ElevatedButton.icon(
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Edit', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0)),
              elevation: 5.0,
            ),
            onPressed: () {
              _editImage(selectedImage);
            },
          ),
        if (isUserImageOwner)
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('Delete', style: TextStyle(color: Colors.white)),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0)),
            elevation: 5.0,
          ),
          onPressed: () {
            Navigator.pop(context, _selectedImageId);
          },
          child:
              const Text('Select this image', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0)),
            elevation: 5.0,
          ),
          onPressed: () => setState(() => _showPopup = false),
          child: const Text('Close', style: TextStyle(color: Colors.white)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image deleted successfully'),
          ),
        );
        await _fetchImages(); // Refresh the list of images
      } else {
        // Failed to delete image
        debugPrint('Failed to delete image');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete image'),
          ),
        );
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
          title: const Text('Confirm Deletion'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this image?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              child: const Text('Delete'),
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
          title: const Text('Edit Image Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _imageTitleController,
                decoration: const InputDecoration(
                  labelText: 'Image Title',
                  hintText: 'Enter the title of the image',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _imageDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Image Description',
                  hintText: 'Enter a description for the image',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2.0),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
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

  Future<int?> _fetchUserId() async {
    String baseUrl = GlobalConfig().serverUrl;
    String? authToken = await SecureStorageManager.getAuthToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/me'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['userId'];
    } else {
      debugPrint('Failed to fetch user ID: ${response.body}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Images',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(
          color: Colors.white, // This sets the back arrow to white
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: Colors.green,
                      ),
                ),
                child: TextFormField(
                  controller: _imageTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Image Title',
                    hintText: 'Enter the title of the image',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: Colors.green,
                      ),
                ),
                child: TextFormField(
                  controller: _imageDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Image Description',
                    hintText: 'Enter a description for the image',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Public'),
                  Switch(
                    value: _isPublic,
                    onChanged: (bool newValue) {
                      setState(() {
                        _isPublic = newValue;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child:
                    const Text('Pick Image', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 16),
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
                    : const Text("No image selected."),
              if (_imageFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: _createImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Upload Image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Your Images',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText:
                      'Search Images', // Change this to your preferred label
                  labelStyle: const TextStyle(
                    color:
                        Colors.grey, // Set the color of the label text to grey
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize
                        .min, // This is important to align your icons properly
                    children: [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          // Add any additional logic you want to execute when the clear button is pressed
                          _fetchImages(); // Fetch all images again to reset the search
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          _searchImages(_searchController.text
                              .trim()); // Implement your search logic here
                        },
                      ),
                    ],
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1.0), // Set the enabled border color to grey
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.green,
                        width: 2.0), // Set the focused border color to green
                  ),
                ),
                onSubmitted: (value) {
                  // Implement what happens when a search query is submitted
                  _searchImages(value.trim());
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            subtitle: Text(
                              'ID: ${image['imageId']}',
                              style: const TextStyle(fontSize: 12),
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
