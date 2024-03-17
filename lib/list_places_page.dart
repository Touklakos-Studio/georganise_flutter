import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secure_storage_manager.dart'; // Make sure this matches your implementation
import 'place.dart';
import 'place_card.dart';
import 'global_config.dart';

class ListPlacesPage extends StatefulWidget {
  @override
  _ListPlacesPageState createState() => _ListPlacesPageState();
}

class _ListPlacesPageState extends State<ListPlacesPage> {
  List<Place> _places = [];
  List<Place> _filteredPlaces = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserIdAndPlaces();
  }

  String baseUrl = GlobalConfig().serverUrl;

  Future<int?> _fetchUserId() async {
    String? authToken = await SecureStorageManager.getAuthToken();
    debugPrint('AuthToken : $authToken');
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/me'),
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
      Uri.parse('$baseUrl/api/place/user/$userId'),
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
    } else if (response.statusCode == 404) {
      debugPrint('No places found');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No places found')),
      );
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

  Future<void> _searchPlaces(String query) async {
    final int? userId = await _fetchUserId();
    if (userId != null) {
      String? authToken = await SecureStorageManager.getAuthToken();

      var response = null;
      try {
        response = await http.get(
          Uri.parse('$baseUrl/api/place/keyword/$query'),
          headers: {
            'Content-Type': 'application/json',
            'Cookie': 'authToken=$authToken',
          },
        );
      } catch (e) {
        debugPrint('Error searching places: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error : Failed to search places')),
        );
      }

      if (response != null) {
        debugPrint('Response : $response');
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _filteredPlaces =
                data.map((placeData) => Place.fromJson(placeData)).toList();
          });
        } else if (response.statusCode == 404) {
          debugPrint('No places found for the search query: $query');
        } else {
          debugPrint('Failed to search places: ${response.body}');
          throw Exception('Failed to search places');
        }
      } else {
        debugPrint('Response is null.');
      }
    } else {
      debugPrint('User ID is null.');
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _filteredPlaces.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search places...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white),
          ),
          style: TextStyle(color: Colors.white),
          onChanged: (query) {
            if (query.isNotEmpty) {
              _searchPlaces(query);
            } else {
              _clearSearch();
            }
          },
        ),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _filteredPlaces.isNotEmpty
                ? ListView.builder(
                    itemCount: _filteredPlaces.length,
                    itemBuilder: (context, index) {
                      final place = _filteredPlaces[index];
                      return Column(
                        children: [
                          PlaceCard(
                            place: place,
                            onPlaceDeleted: () {
                              setState(() {
                                _places.removeWhere(
                                    (p) => p.placeId == place.placeId);
                              });
                            },
                          ),
                          if (index < _filteredPlaces.length - 1)
                            Divider(color: Colors.grey),
                        ],
                      );
                    },
                  )
                : ListView.builder(
                    itemCount: _places.length,
                    itemBuilder: (context, index) {
                      final place = _places[index];
                      return Column(
                        children: [
                          PlaceCard(
                            place: place,
                            onPlaceDeleted: () {
                              setState(() {
                                _places.removeWhere(
                                    (p) => p.placeId == place.placeId);
                              });
                            },
                          ),
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
