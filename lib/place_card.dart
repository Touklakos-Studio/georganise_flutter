import 'package:flutter/material.dart';
import 'place.dart'; // Ensure this matches your file structure
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secure_storage_manager.dart';
import 'global_config.dart';

class PlaceCard extends StatefulWidget {
  final Place place;

  PlaceCard({required this.place});

  @override
  _PlaceCardState createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  bool _showUsername = false;
  String? _userName;

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
            'nickname']; // Assuming the key for the user's name is 'nickname'
      } else {
        debugPrint('Failed to fetch user name: ${response.body}');
        return 'Failed to fetch user name';
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
      return 'Error occurred';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Assuming `tags` might not be directly available as `List<String>` anymore
    // and considering they might need fetching or are complex objects now,
    // the tags display logic might need adjustment or removal if not applicable.

    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(
                  Icons.location_on), // Optional: Add an icon to the list tile
              title: Text(widget.place.name), // Updated to `name`
              subtitle: Text(
                "${widget.place.description}\nLat: ${widget.place.latitude}, Long: ${widget.place.longitude}",
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Display tags if applicable
            // If place.placeTags is not a simple list of strings, this section might need rework
            if (widget.place.placeTags != null &&
                widget.place.placeTags.isNotEmpty) // Checking if tags exist
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  children: widget.place.placeTags
                      .map((tag) => Chip(
                            label: Text(tag
                                .toString()), // Assuming tag can be converted to a string
                          ))
                      .toList(),
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
                          _userName = await _fetchUserName(widget.place.userId);
                          if (_userName == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to fetch username')),
                            );
                          }
                        }
                      },
                    ),
                    if (_showUsername && _userName != null) Text('$_userName'),
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
