import 'package:flutter/material.dart';
import 'place.dart'; // Make sure this import path matches your file structure
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secure_storage_manager.dart';
import 'global_config.dart';
import 'dart:typed_data';

class PlaceCard extends StatefulWidget {
  final Place place;
  final VoidCallback onPlaceDeleted; // Add this line

  PlaceCard({required this.place, required this.onPlaceDeleted});

  @override
  _PlaceCardState createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  bool _showUsername = false;
  String? _userName;
  Uint8List? _imageData;

  @override
  void initState() {
    super.initState();
    _fetchImage();
    // Call to fetch user name removed from initState since it should be triggered by a button press
  }

  Future<void> _fetchImage() async {
    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null || !mounted) {
      debugPrint("Auth token is null or widget is unmounted");
      return;
    }

    try {
      String baseUrl = GlobalConfig().serverUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/image/${widget.place.imageId}'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken',
        },
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          final String? imageDataString = data['imageValue'];
          if (imageDataString != null) {
            _imageData = base64Decode(imageDataString);
          } else {
            debugPrint("Image data is null");
          }
        });
      } else if (!mounted) {
        debugPrint('Widget unmounted before request completion');
      } else {
        debugPrint('Failed to fetch image: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error fetching image: $e');
      }
    }
  }

  Future<String?> _fetchUserName(int userId) async {
    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null) {
      debugPrint("Auth token is null");
      return null;
    }

    try {
      String baseUrl = GlobalConfig().serverUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data[
            'nickname']; // Assuming 'nickname' is the key for the username
      } else {
        debugPrint('Failed to fetch user name: ${response.body}');
        return 'Failed to fetch user name';
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
      return 'Error occurred';
    }
  }

  Future<void> _deletePlace() async {
    // Show a confirmation dialog before deleting the place
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Place'),
          content: Text('Are you sure you want to delete this place?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                // Send a DELETE request to your server
                String? authToken = await SecureStorageManager.getAuthToken();
                if (authToken == null) {
                  debugPrint("Auth token is null");
                  return;
                }

                try {
                  String baseUrl = GlobalConfig().serverUrl;
                  final response = await http.delete(
                    Uri.parse('$baseUrl/api/place/${widget.place.placeId}'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Cookie': 'authToken=$authToken',
                    },
                  );

                  if (response.statusCode == 200) {
                    // Place deleted successfully, call the callback to refresh the list
                    widget.onPlaceDeleted();
                    Navigator.of(context).pop();
                  } else {
                    debugPrint('Failed to delete place: ${response.body}');
                  }
                } catch (e) {
                  debugPrint('Error deleting place: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_imageData != null)
              Container(
                width: double.infinity,
                height: 200, // Adjust the size according to your needs
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: MemoryImage(_imageData!),
                  ),
                ),
              ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text(widget.place.name),
              subtitle: Text(
                "${widget.place.description}\nLat: ${widget.place.latitude}, Long: ${widget.place.longitude}",
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    // Implement share functionality
                  },
                ),
                IconButton(
                  icon: Icon(Icons.cloud_download),
                  onPressed: () {
                    // Implement download/export functionality
                  },
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.person),
                      onPressed: () async {
                        setState(() {
                          _showUsername = !_showUsername;
                        });
                        if (_showUsername && _userName == null) {
                          String? name =
                              await _fetchUserName(widget.place.userId);
                          if (mounted) {
                            setState(() {
                              _userName = name;
                            });
                          }
                        }
                      },
                    ),
                    if (_showUsername && _userName != null) Text(_userName!),
                  ],
                ),
                ButtonBar(
                  alignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // ...
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: _deletePlace,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
