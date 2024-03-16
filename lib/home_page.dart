import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'create_place_page.dart';
import 'list_places_page.dart';
import 'settings_page.dart';
import 'welcome_page.dart';
import 'secure_storage_manager.dart';
import 'add_place_page.dart';
import 'package:http/http.dart' as http;
import 'place.dart';
import 'dart:convert'; // For using jsonEncode
import 'global_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  bool _isDoubleTap = false;
  List<Place> _places = [];
  bool _isLoading = true;

  Future<void> _fetchUserIdAndPlaces() async {
    try {
      final int? userId = await _fetchUserId();
      if (userId != null) {
        await _fetchPlaces(userId);
        debugPrint('Fetched places successfully!');
      } else {
        debugPrint('User ID is null.');
      }
    } catch (e) {
      debugPrint('Error fetching places: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<int?> _fetchUserId() async {
    String baseUrl = GlobalConfig().serverUrl;
    String? authToken = await SecureStorageManager.getAuthToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/me'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['userId'];
    } else {
      debugPrint('Failed to fetch user ID: ${response.body}');
      return null;
    }
  }

  Future<void> _fetchPlaces(int userId) async {
    String baseUrl = GlobalConfig().serverUrl;
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
        debugPrint('Fetched places: $data'); // Add this line
        _places = data.map((placeData) => Place.fromJson(placeData)).toList();
        _isLoading = false;
        _markers.addAll(_convertPlacesToMarkers(_places));
      });
    } else {
      debugPrint('Failed to fetch places: ${response.body}');
      throw Exception('Failed to fetch places');
    }
  }

  List<Marker> _convertPlacesToMarkers(List<Place> places) {
    return places.map((place) {
      debugPrint(
          'Place latitude: ${place.latitude}, longitude: ${place.longitude}');
      return Marker(
          point: LatLng(place.latitude, place.longitude),
          width: 80.0,
          height: 80.0,
          child: IconButton(
            icon: Icon(Icons.location_pin),
            iconSize: 60,
            color: Colors.red,
            onPressed: () {
              debugPrint('Marker tapped!');
              _showPlaceDetails(place);
            },
          ));
    }).toList();
  }

  void _showPlaceDetails(Place place) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(place.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.description),
              SizedBox(height: 8),
              Text(
                'Tags: ${place.placeTags.join(', ')}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUserIdAndPlaces();
  }

  Future<void> _logoutUser() async {
    try {
      String baseUrl = GlobalConfig().serverUrl;
      // Attempt to retrieve the authToken from secure storage
      String? authToken = await SecureStorageManager.getAuthToken();

      // Make the POST request to logout the user on the backend
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken',
        },
      );

      // Check the response status code
      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('Logout successful on backend');
      } else {
        debugPrint(
            'Failed to logout on backend. Status code: ${response.statusCode}');
      }

      // Regardless of the response, clear the authToken from secure storage
      await SecureStorageManager.deleteAuthToken();
      debugPrint('Auth token deleted successfully from local storage');

      // Navigate to the WelcomePage and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('An error occurred during logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: content(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.green,
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon:
                  Icon(Icons.add, color: Colors.white), // Add the "Plus" button
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddPlacePage()),
                ).then((value) {
                  // Check if the value is true, indicating a successful place creation
                  debugPrint("Returned from AddPlacePage with value: $value");
                  if (value == true) {
                    // Refresh places and markers on the map
                    _fetchUserIdAndPlaces();
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ListPlacesPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.white),
              onPressed: _logoutUser, // Updated to use _logoutUser
            ),
          ],
        ),
      ),
    );
  }

  Widget content() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(45.7032695, 3.3448536),
        initialZoom: 8,
        interactiveFlags: InteractiveFlag.pinchZoom |
            InteractiveFlag.drag, // Enable pinch zoom and drag
        onTap: (_, latLng) async {
          if (_isDoubleTap) {
            // Double tap detected, proceed with creating a place
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreatePlacePage(
                  position: latLng,
                ),
              ),
            );

            if (result != null && result == true) {
              _fetchUserIdAndPlaces(); // Refresh markers if a new place was successfully created
            } else if (result == false) {
              setState(() {
                _markers
                    .removeLast(); // Remove temporary marker if place creation was cancelled
              });
            }

            _isDoubleTap = false;
          } else {
            // First tap detected, start timer to wait for a second tap
            _isDoubleTap = true;
            await Future.delayed(const Duration(milliseconds: 300));
            _isDoubleTap = false;
          }
        },
      ),
      children: [
        openStreetMapTileLayer,
        MarkerLayer(markers: _markers),
      ],
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    );
