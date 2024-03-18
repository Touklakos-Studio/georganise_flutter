import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secure_storage_manager.dart';
import 'global_config.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Lighter background color
      appBar: AppBar(
        title: Text("Tag Details", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green, // Modern teal color
        elevation: 0, // Remove shadow for a flat design
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
            // Assuming the data is received correctly
            var data = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2, // Slight shadow for depth
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Rounded corners
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Description',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        Text(data["description"],
                            style: TextStyle(fontSize: 16)),
                        SizedBox(height: 16),
                        Text('Associated Places:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Column(
                          children: data["placeTags"].map<Widget>((tag) {
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
                                    leading:
                                        Icon(Icons.error, color: Colors.red),
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
                                        style: TextStyle(fontSize: 14)),
                                  );
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
