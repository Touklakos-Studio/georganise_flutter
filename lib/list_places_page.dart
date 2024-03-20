import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secure_storage_manager.dart'; // Make sure this matches your implementation
import 'place.dart';
import 'place_card.dart';
import 'global_config.dart';

class ListPlacesPage extends StatefulWidget {
  const ListPlacesPage({super.key});

  @override
  _ListPlacesPageState createState() => _ListPlacesPageState();
}

class _ListPlacesPageState extends State<ListPlacesPage> {
  List<Place> _places = [];
  List<Place> _filteredPlaces = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  int _searchKey = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  String baseUrl = GlobalConfig().serverUrl;

  // Fetch user ID to use in other API calls
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

  // Fetch user's places from the backend
  Future<void> _fetchPlaces() async {
    String? authToken = await SecureStorageManager.getAuthToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/place'),
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
        const SnackBar(content: Text('No places found')),
      );
    } else {
      debugPrint('Failed to fetch places: ${response.body}');
      throw Exception('Failed to fetch places');
    }
  }

  // Search for places based on the query
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      // If the search query is empty, show all places
      _clearSearch();
      return;
    }

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
            _searchKey = DateTime.now()
                .millisecondsSinceEpoch; // Update the key to force rebuild of PlaceCards.
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

  // Fetch tag names for places and update the place object with tag names
  Future<List<Place>> _fetchAndUpdateTagNamesForPlaces(
      List<Place> places) async {
    List<Future> fetchTagNamesTasks = [];
    for (var place in places) {
      place.placeTags.forEach((tag) async {
        // Assuming tag['placeTagId'] exists and _fetchTagName method is defined in your PlaceCard
        fetchTagNamesTasks.add(
          _fetchTagName(tag['placeTagId']).then((tagName) {
            // Update tag name in place object, implement logic accordingly
            tag['tagName'] = tagName ?? "Unknown Tag";
          }),
        );
      });
    }

    // Wait for all fetch tag name tasks to complete
    await Future.wait(fetchTagNamesTasks);
    return places; // Return places with updated tag names
  }

  // Fetch tag name for a place tag ID
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

  // Clear search and show all places
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _filteredPlaces.clear();
      _fetchPlaces(); // Fetch all places again
    });
  }

  // Refresh search results based on the search query or show all places if query is empty or null
  void refreshSearch() {
    setState(() {
      _isLoading = true; // Show loading indicator while fetching
    });

    // Optionally clear the search field or handle it differently based on your UX design
    //_searchController.clear();

    _fetchPlaces().then((_) {
      // If you are maintaining a separate list for search results,
      // you might want to clear it or handle it appropriately here
      if (_searchController.text.isNotEmpty) {
        _searchPlaces(_searchController.text.trim());
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }).catchError((error) {
      debugPrint("Error refreshing places: $error");
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text('List Places', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  labelStyle: const TextStyle(
                    color:
                        Colors.grey, // Set the color of the label text to grey
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize
                        .min, // This is important to align your icons properly
                    children: [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _clearSearch(); // Clear search and show all places
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          _searchPlaces(_searchController.text.trim());
                          _fetchPlaces();
                        },
                      ),
                    ],
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1.0), // Set the enabled border color to grey
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.green,
                        width: 2.0), // Set the focused border color to green
                  ),
                ),
                onSubmitted: (query) {
                  if (query.isNotEmpty) {
                    _searchPlaces(query);
                    _fetchPlaces();
                  } else {
                    refreshSearch(); // Clear search and show all places
                  }
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
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
                              key: ValueKey('$_searchKey-${place.placeId}'),
                              place: _filteredPlaces.isNotEmpty
                                  ? _filteredPlaces[index]
                                  : _places[index],
                              onPlaceDeleted: () => setState(() =>
                                  _places.removeWhere(
                                      (p) => p.placeId == place.placeId)),
                              refreshSearch: () {
                                _searchPlaces(_searchController.text
                                    .trim()); // Optionally refresh the search
                              }, // Pa  ss the method here
                            ),
                            const Divider(color: Colors.grey),
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
