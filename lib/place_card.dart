import 'package:flutter/material.dart';
import 'place.dart'; // Make sure this import path matches your file structure
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secure_storage_manager.dart';
import 'global_config.dart';
import 'dart:typed_data';
import 'dart:ui';

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
  Map<int, String> _tagNames = {};

  @override
  void initState() {
    super.initState();
    _fetchImage();
    _initializeTagNames();
  }

  void _initializeTagNames() {
    widget.place.placeTags.forEach((placeTag) {
      int placeTagId = placeTag['placeTagId'];
      _tagNames[placeTagId] =
          "Fetching..."; // Default text before fetch completes
      _fetchTagName(placeTagId).then((name) {
        if (mounted) {
          setState(() {
            _tagNames[placeTagId] =
                name ?? "Unknown Tag"; // Fallback to "Unknown Tag"
          });
        }
      });
    });
  }

  Future<String?> _fetchTagName(int placeTagId) async {
    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null) return "Unknown Tag";
    String baseUrl = GlobalConfig().serverUrl;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tag/placeTag/$placeTagId'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['title'];
      }
    } catch (e) {
      debugPrint('Failed to fetch tag name: $e');
    }
    return "Unknown Tag"; // Return "Unknown Tag" if fetch fails
  }

  Future<void> _fetchImage() async {
    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null || !mounted) return;
    String baseUrl = GlobalConfig().serverUrl;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/image/${widget.place.imageId}'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken',
        },
      );
      if (response.statusCode == 200 && mounted) {
        final String? imageDataString =
            json.decode(response.body)['imageValue'];
        if (imageDataString != null) {
          setState(() => _imageData = base64Decode(imageDataString));
        }
      }
    } catch (e) {
      debugPrint('Error fetching image: $e');
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

  List<Widget> _buildTagWidgets() {
    return widget.place.placeTags.map((tag) {
      int tagId = tag['placeTagId'];
      String tagName = _tagNames[tagId] ??
          "Unknown Tag"; // Use fetched name or "Unknown Tag"
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Chip(
          label: Text(tagName, style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          decoration: _imageData != null
              ? BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: MemoryImage(_imageData!),
                  ),
                )
              : null,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              alignment: Alignment.center,
              color: Colors.black.withOpacity(0.6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ListTile(
                    title: Text(
                      widget.place.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "${widget.place.description}\nLat: ${widget.place.latitude}, Long: ${widget.place.longitude}",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      children:
                          _buildTagWidgets(), // Updated to use the new method
                    ),
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.share),
                        color: Colors.white,
                        onPressed: () {
                          // Implement share functionality
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.cloud_download),
                        color: Colors.white,
                        onPressed: () {
                          // Implement download/export functionality
                        },
                      ),
                      // The IconButton with a person icon
                      IconButton(
                        icon: Icon(Icons.person),
                        color: Colors.white,
                        onPressed: () async {
                          if (!_showUsername) {
                            // Only fetch the username if it hasn't been fetched already
                            String? name =
                                await _fetchUserName(widget.place.userId);
                            if (mounted) {
                              setState(() {
                                _showUsername = true;
                                _userName = name;
                              });
                            }
                          } else {
                            // Hide the username if the icon is pressed again
                            setState(() {
                              _showUsername = false;
                            });
                          }
                        },
                      ),
                      // This Text widget displays the username
                      if (_showUsername && _userName != null)
                        Container(
                          padding: EdgeInsets.all(8.0),
                          color: Colors.black.withOpacity(0.5),
                          child: Text(
                            _userName!,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: _deletePlace,
                      ),
                    ],
                  ), // The ButtonBar for share, download, and delete icons remains unchanged
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
