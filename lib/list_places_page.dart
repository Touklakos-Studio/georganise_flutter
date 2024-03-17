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
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/place/keyword/$query'),
          headers: {
            'Content-Type': 'application/json',
            'Cookie': 'authToken=$authToken',
          },
        );

        if (response.statusCode == 200) {
          List<dynamic> data = json.decode(response.body);
          // Fetch and update tag names for places before setting state.
          List<Place> placesWithTags = await _fetchAndUpdateTagNamesForPlaces(
              data.map((placeData) => Place.fromJson(placeData)).toList());
          setState(() {
            _filteredPlaces = placesWithTags;
          });
        } else if (response.statusCode == 404) {
          debugPrint('No places found for the search query: $query');
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No places found for the search $query')));
        } else {
          debugPrint('Failed to search places: ${response.body}');
          throw Exception('Failed to search places');
        }
      } catch (e) {
        debugPrint('Error searching places: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error : Failed to search places')));
      }
    } else {
      debugPrint('User ID is null.');
    }
  }

  Future<List<Place>> _fetchAndUpdateTagNamesForPlaces(
      List<Place> places) async {
    List<Future> fetchTagNamesTasks = [];
    places.forEach((place) {
      place.placeTags.forEach((tag) async {
        // Assuming tag['placeTagId'] exists and _fetchTagName method is defined in your PlaceCard
        fetchTagNamesTasks.add(
          _fetchTagName(tag['placeTagId']).then((tagName) {
            // Update tag name in place object, implement logic accordingly
            tag['tagName'] = tagName ?? "Unknown Tag";
          }),
        );
      });
    });

    // Wait for all fetch tag name tasks to complete
    await Future.wait(fetchTagNamesTasks);
    return places; // Return places with updated tag names
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

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _filteredPlaces.clear();
    });
  }

  void refreshSearch() {
    // Clear the filtered places to reset the search
    setState(() {
      _filteredPlaces.clear();
    });

    // If there's text in the search bar, perform the search; otherwise, fetch all places again
    if (_searchController.text.isNotEmpty) {
      _searchPlaces(_searchController.text.trim());
    } else {
      // If the search query is empty, refetch all places related to the user
      _fetchUserIdAndPlaces();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text('List Places', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _searchPlaces(_searchController.text.trim()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _clearSearch(); // Clear search and show all places
                    },
                  ),
                ),
                onSubmitted: (query) {
                  if (query.isNotEmpty) {
                    _searchPlaces(query);
                  } else {
                    refreshSearch(); // Clear search and show all places
                  }
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredPlaces.isNotEmpty
                          ? _filteredPlaces.length
                          : _places.length,
                      itemBuilder: (context, index) {
                        final place = _filteredPlaces.isNotEmpty
                            ? _filteredPlaces[index]
                            : _places[index];
                        return Column(
                          children: [
                            PlaceCard(
                              place: place,
                              onPlaceDeleted: () => setState(() =>
                                  _places.removeWhere(
                                      (p) => p.placeId == place.placeId)),
                              refreshSearch:
                                  refreshSearch, // Pass the method here
                            ),
                            Divider(color: Colors.grey),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
