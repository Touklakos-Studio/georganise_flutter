import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secure_storage_manager.dart'; // Make sure this matches your implementation
import 'place.dart';
import 'place_card.dart';

class ListPlacesPage extends StatefulWidget {
  @override
  _ListPlacesPageState createState() => _ListPlacesPageState();
}

class _ListPlacesPageState extends State<ListPlacesPage> {
  List<Place> _places = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserIdAndPlaces();
  }

  Future<int?> _fetchUserId() async {
    String? authToken = await SecureStorageManager.getAuthToken();
    debugPrint('AuthToken : $authToken');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/user/me'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['userId']; // Ensure this returns an int or null
    } else {
      debugPrint('Failed to fetch user ID: ${response.body}');
      return null; // Return null or handle error differently if user ID can't be fetched
    }
  }

  Future<void> _fetchPlaces(int userId) async {
    String? authToken = await SecureStorageManager.getAuthToken();
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/place/user/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _places = data.map((placeData) => Place.fromJson(placeData)).toList();
        _isLoading = false;
      });
    } else {
      debugPrint('Failed to fetch places: ${response.body}');
      throw Exception('Failed to fetch places');
    }
  }

  Future<void> _fetchUserIdAndPlaces() async {
    try {
      final int? userId = await _fetchUserId(); // userId can be null.
      if (userId != null) {
        await _fetchPlaces(
            userId); // _fetchPlaces is now only called with a non-null userId.
      } else {
        debugPrint('User ID is null.');
        // Handle the case where the user ID couldn't be fetched. Maybe show an error message.
      }
    } catch (e) {
      debugPrint('Error fetching places: $e');
      setState(() => _isLoading = false);
      // Optionally, show an error message to the user.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Places', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Future implementation of search functionality
            },
          ),
        ],
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _places.length,
                itemBuilder: (context, index) {
                  final place = _places[index];
                  return Column(
                    children: [
                      PlaceCard(place: place),
                      if (index < _places.length - 1)
                        Divider(color: Colors.grey),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
