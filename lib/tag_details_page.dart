import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secure_storage_manager.dart';
import 'global_config.dart';
import 'token_details_page.dart';

class TagDetailsPage extends StatefulWidget {
  final int tagId;

  const TagDetailsPage({
    super.key,
    required this.tagId,
  });

  @override
  _TagDetailsPageState createState() => _TagDetailsPageState();
}

class _TagDetailsPageState extends State<TagDetailsPage> {
  String _nickname = '';
  bool _includeNickname = false;

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

    // Prepare the request body with conditionally included nickname
    Map<String, dynamic> requestBody = {
      "accessRight": accessRight,
      "userId": null, // Adjust according to your API's requirements
      "tagId": widget.tagId,
    };
    if (_includeNickname && _nickname.isNotEmpty) {
      requestBody['nickname'] = _nickname; // Include the nickname if applicable
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/token/new'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken',
      },
      body: jsonEncode(requestBody),
    );

    // Response handling remains the same
    if (response.statusCode == 200 &&
        (_includeNickname && _nickname.isNotEmpty)) {
      debugPrint('Token generated and added to user successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Token generated and added to user successfully')),
      );
    } else if (response.statusCode == 200) {
      debugPrint('Token generated successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token generated successfully')),
      );
    } else if (response.statusCode == 401) {
      debugPrint('Failed to generate token: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('You are not authorized to generate a token on this tag')),
      );
    } else {
      debugPrint('Failed to generate token: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to generate token. Please try again.')),
      );
    }
  }

  void _showGenerateTokenDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isWriter = false; // Default access right
        return AlertDialog(
          title: const Text("Generate Token"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text("Select Access Right:"),
                    SwitchListTile(
                      title: Text(isWriter ? "Writer" : "Reader"),
                      value: isWriter,
                      onChanged: (bool value) {
                        setState(() {
                          isWriter = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    SwitchListTile(
                      title: const Text("Include Nickname"),
                      value: _includeNickname,
                      onChanged: (bool value) {
                        setState(() {
                          _includeNickname = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    if (_includeNickname)
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Nickname',
                          labelStyle: TextStyle(
                            color: Colors
                                .grey, // Set the color of the label text to green
                          ),
                          // Border when TextField is not in focus
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey, width: 2.0),
                          ),
                          // Border when TextField is in focus
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.green, width: 2.0),
                          ),
                        ),
                        onChanged: (value) {
                          _nickname = value;
                        },
                      ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green, // Background color
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _generateToken(isWriter ? "WRITER" : "READER");
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green, // Background color
              ),
              child: const Text('Generate Token'),
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
        title: const Text("Tag Details", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white, // makes back arrow white
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchTagDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red)),
            );
          } else {
            var data = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.tag, color: Colors.green),
                          title: Text(data["title"],
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          subtitle: Text('Tag ID: ${data["tagId"]}',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.grey)),
                        ),
                        const Divider(),
                        Text('Description: ${data["description"]}',
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 20),
                        const Text('Associated Places:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...data["placeTags"].map<Widget>((tag) {
                          return FutureBuilder<Map<String, dynamic>>(
                            future: fetchPlaceDetails(tag["placeTagId"]),
                            builder: (context, placeSnapshot) {
                              if (placeSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const ListTile(
                                  leading: CircularProgressIndicator(),
                                  title: Text('Loading place details...'),
                                );
                              } else if (placeSnapshot.hasError) {
                                return const ListTile(
                                  leading: Icon(Icons.error, color: Colors.red),
                                  title: Text('Error loading place details'),
                                );
                              } else {
                                var placeData = placeSnapshot.data!;
                                return ListTile(
                                  leading: const Icon(Icons.place,
                                      color: Colors.green),
                                  title: Text(placeData["name"],
                                      style: const TextStyle(fontSize: 16)),
                                  subtitle: Text(
                                    'Description: ${placeData["description"]}\nLocation: ${placeData["latitude"]}, ${placeData["longitude"]}',
                                    style: const TextStyle(fontSize: 14),
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
              icon: const Icon(Icons.vpn_key, color: Colors.white),
              label: const Text('Generate Token'),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("No tokens generated for this tag."),
                    ));
                  }
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Error fetching token details."),
                  ));
                });
              },
              icon: const Icon(Icons.visibility, color: Colors.white),
              label: const Text('View Tokens'),
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
