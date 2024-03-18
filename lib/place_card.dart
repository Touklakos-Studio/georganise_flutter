import 'package:flutter/material.dart';
import 'place.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secure_storage_manager.dart';
import 'global_config.dart';
import 'dart:typed_data';
import 'dart:ui';
import 'create_place_page.dart';
import 'package:latlong2/latlong.dart';

class PlaceCard extends StatefulWidget {
  final Place place;
  final VoidCallback onPlaceDeleted;
  final VoidCallback
      refreshSearch; // Add this callback for refreshing the search

  PlaceCard(
      {required this.place,
      required this.onPlaceDeleted,
      required this.refreshSearch});

  @override
  _PlaceCardState createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  bool _showUsername = false;
  String? _userName;
  Uint8List? _imageData;
  String? _currentUserNickname;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchImage();
    _fetchCurrentUserData(); // Fetch the current user's data
  }

  void _initializeData() async {
    await _fetchUserNameForPlace();
    // If there are other data initialization steps, include them here
  }

  Future<void> _fetchUserNameForPlace() async {
    String? userName = await _fetchUserName(widget.place.userId);
    if (mounted) {
      setState(() {
        _userName = userName;
      });
    }
  }

  Future<void> _fetchCurrentUserData() async {
    try {
      String? authToken = await SecureStorageManager.getAuthToken();
      if (authToken == null) {
        debugPrint("Auth token is null");
        return;
      }
      String baseUrl = GlobalConfig().serverUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/me'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _currentUserNickname = data['nickname'];
            debugPrint("Current user nickname: $_currentUserNickname");
          });
        }
      } else {
        debugPrint('Failed to fetch current user data: ${response.body}');
      }
    } catch (e) {
      debugPrint('An error occurred while fetching current user data: $e');
    }
  }

  Future<List<String>> _fetchTagNames(List<dynamic> placeTags) async {
    List<String> tagNames = [];
    for (var tag in placeTags) {
      int tagId = tag['placeTagId'];
      String? tagName = await _fetchTagName(tagId);
      tagName = tagName ?? "Unknown Tag";
      tagNames.add(tagName);
    }
    return tagNames;
  }

  Future<String?> _fetchTagName(int tagId) async {
    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null) return "Unknown Tag";
    String baseUrl = GlobalConfig().serverUrl;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tag/placeTag/$tagId'),
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
    return "Unknown Tag";
  }

  Future<void> _fetchImage() async {
    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null || !mounted) return;
    if (widget.place.imageId == null) return;
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
          setState(() {
            _imageData = base64Decode(imageDataString);
          });
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
        debugPrint(
            "Fetched nickname for user ${widget.place.userId}: ${data['nickname']}");
        return data['nickname'];
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Place'),
          content: Text('Are you sure you want to delete this place?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
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
                    widget
                        .onPlaceDeleted(); // Notify parent widget to remove the item from the list
                    Navigator.of(context).pop(); // Close the dialog
                    widget
                        .refreshSearch(); // Refresh the search in the parent widget
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
                  FutureBuilder<List<String>>(
                    future: _fetchTagNames(widget.place.placeTags),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<String>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasData) {
                        return Padding(
                          padding: const EdgeInsets.all(
                              10.0), // Add padding around the Wrap widget
                          child: Wrap(
                            runSpacing:
                                4.0, // Vertical space between lines of tags
                            children: snapshot.data!
                                .map((tag) => Chip(
                                      label: Text(tag,
                                          style:
                                              TextStyle(color: Colors.white)),
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.all(
                                          4.0), // Add padding inside each Chip
                                    ))
                                .toList(),
                          ),
                        );
                      } else {
                        return Text("No tags available");
                      }
                    },
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
                      IconButton(
                        icon: Icon(Icons.person),
                        color: Colors.white,
                        onPressed: () async {
                          if (!_showUsername) {
                            String? name =
                                await _fetchUserName(widget.place.userId);
                            if (mounted) {
                              setState(() {
                                _showUsername = true;
                                _userName = name;
                              });
                            }
                          } else {
                            setState(() {
                              _showUsername = false;
                            });
                          }
                        },
                      ),
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
                        onPressed: _currentUserNickname == _userName
                            ? _deletePlace
                            : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        color: Colors.green, // Set the icon color to green
                        onPressed: _currentUserNickname == _userName
                            ? () async {
                                final bool? result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreatePlacePage(
                                      position: LatLng(widget.place.latitude,
                                          widget.place.longitude),
                                      placeToEdit: widget.place,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  widget
                                      .refreshSearch(); // Reload the list to reflect any changes
                                  _fetchImage(); // Refetch the image in case it has been updated
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
