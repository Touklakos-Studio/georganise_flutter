import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secure_storage_manager.dart';
import 'global_config.dart';
import 'token_details_page.dart';

class TagDetailsPage extends StatefulWidget {
  final int tagId;

  const TagDetailsPage({
    Key? key,
    required this.tagId,
  }) : super(key: key);

  @override
  _TagDetailsPageState createState() => _TagDetailsPageState();
}

class _TagDetailsPageState extends State<TagDetailsPage> {
  Future<Map<String, dynamic>> fetchTagDetails() async {
    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null) {
      throw Exception("Auth token is null");
    }
    String baseUrl = GlobalConfig().serverUrl;
    final response = await http.get(
      Uri.parse('$baseUrl/api/tag/${widget.tagId}'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      debugPrint('Failed to fetch tag details: ${response.body}');
      throw Exception('Failed to fetch tag details');
    }
  }

  Future<Map<String, dynamic>> fetchPlaceDetails(int placeTagId) async {
    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null) {
      throw Exception("Auth token is null");
    }
    String baseUrl = GlobalConfig().serverUrl;
    final response = await http.get(
      Uri.parse('$baseUrl/api/place/placeTag/$placeTagId'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      debugPrint(
          'Failed to fetch place details for placeTagId $placeTagId: ${response.body}');
      throw Exception('Failed to fetch place details');
    }
  }

  void _generateToken(String accessRight) async {
    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null) {
      debugPrint("Auth token is null");
      return;
    }
    String baseUrl = GlobalConfig().serverUrl;
    final response = await http.post(
      Uri.parse('$baseUrl/api/token/new'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken',
      },
      body: jsonEncode({
        "accessRight": accessRight,
        "userId": null,
        "tagId": widget.tagId,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('Token generated successfully');
      // Optionally, show a success message or handle the token
    } else {
      debugPrint('Failed to generate token: ${response.body}');
      // Optionally, show an error message
    }
  }

  void _showGenerateTokenDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool _isWriter = false; // Default access right
        return AlertDialog(
          title: Text("Generate Token"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text("Select Access Right:"),
                  SwitchListTile(
                    title: Text(_isWriter ? "Writer" : "Reader"),
                    value: _isWriter,
                    onChanged: (bool value) {
                      setState(() {
                        _isWriter = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Generate Token'),
              onPressed: () {
                Navigator.of(context).pop();
                _generateToken(_isWriter ? "WRITER" : "READER");
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<dynamic>> fetchTokenDetails() async {
    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null) {
      debugPrint("Auth token is null");
      throw Exception("Auth token is null");
    }
    String baseUrl = GlobalConfig().serverUrl;
    final response = await http.get(
      Uri.parse('$baseUrl/api/token/tag/${widget.tagId}'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken',
      },
    );

    if (response.statusCode == 200) {
      debugPrint('Token details fetched successfully');
      debugPrint(response.body);
      return json.decode(response.body);
    } else {
      debugPrint('Failed to fetch token details: ${response.body}');
      return [];
    }
  }

  void _navigateToTokenDetailsPage(List<dynamic> tokenDetails) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TokenDetailsPage(tokenDetails: tokenDetails),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Tag Details", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchTagDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}",
                  style: TextStyle(color: Colors.red)),
            );
          } else {
            var data = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.tag, color: Colors.green),
                          title: Text(data["title"],
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          subtitle: Text('Tag ID: ${data["tagId"]}',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey)),
                        ),
                        Divider(),
                        Text('Description: ${data["description"]}',
                            style: TextStyle(fontSize: 16)),
                        SizedBox(height: 20),
                        Text('Associated Places:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        ...data["placeTags"].map<Widget>((tag) {
                          return FutureBuilder<Map<String, dynamic>>(
                            future: fetchPlaceDetails(tag["placeTagId"]),
                            builder: (context, placeSnapshot) {
                              if (placeSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return ListTile(
                                  leading: CircularProgressIndicator(),
                                  title: Text('Loading place details...'),
                                );
                              } else if (placeSnapshot.hasError) {
                                return ListTile(
                                  leading: Icon(Icons.error, color: Colors.red),
                                  title: Text('Error loading place details'),
                                );
                              } else {
                                var placeData = placeSnapshot.data!;
                                return ListTile(
                                  leading:
                                      Icon(Icons.place, color: Colors.green),
                                  title: Text(placeData["name"],
                                      style: TextStyle(fontSize: 16)),
                                  subtitle: Text(
                                    'Description: ${placeData["description"]}\nLocation: ${placeData["latitude"]}, ${placeData["longitude"]}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                );
                              }
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _showGenerateTokenDialog,
              icon: Icon(Icons.vpn_key, color: Colors.white),
              label: Text('Generate Token'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green, // Text color
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                fetchTokenDetails().then((tokenDetails) {
                  if (tokenDetails.isNotEmpty) {
                    _navigateToTokenDetailsPage(tokenDetails);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("No tokens generated for this tag."),
                    ));
                  }
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Error fetching token details."),
                  ));
                });
              },
              icon: Icon(Icons.visibility, color: Colors.white),
              label: Text('View Tokens'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue, // Text color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
