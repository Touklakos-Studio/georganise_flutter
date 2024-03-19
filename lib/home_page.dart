import 'package:flutter/material.dart';
import 'package:flutter_application_1/add_place_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'create_place_page.dart';
import 'list_places_page.dart';
import 'profile_page.dart';
import 'welcome_page.dart';
import 'secure_storage_manager.dart';
import 'add_place_page.dart';
import 'package:http/http.dart' as http;
import 'place.dart';
import 'dart:convert'; // For using jsonEncode
import 'global_config.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

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
  Timer? _locationTimer;
  bool _isFetchingLocation = false;

  @override
  void dispose() {
    _locationTimer?.cancel(); // Cancel the timer
    super.dispose();
  }

  Future<void> _fetchUserIdAndPlaces() async {
    try {
      setState(() {
        _markers.clear(); // Clear existing markers
      });
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

      // Fetch the user's nickname for the realtime location description comparison
      final String? nickname = await _fetchUserName(userId);

      setState(() {
        _places =
            data.map((placeData) => Place.fromJson(placeData)).where((place) {
          // Filter out the realtime location place based on its description
          return !(place.description == "Realtime location of $nickname");
        }).toList();
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.description),
                SizedBox(height: 8),
                FutureBuilder<List<String>>(
                  future: _fetchTagNames(place.placeTags),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasData) {
                      return Wrap(
                        spacing: 8.0, // Spacing between chips
                        children: snapshot.data!
                            .map((tagName) => Chip(
                                  label: Text(tagName),
                                  backgroundColor: Colors.green[200],
                                ))
                            .toList(),
                      );
                    } else {
                      return Text("No tags available");
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => _launchMapsUrl(
                  place.latitude, place.longitude, "google_maps"),
              child: Text('Open in Google Maps'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0), // Rounded corners
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  _launchMapsUrl(place.latitude, place.longitude, "waze"),
              child: Text('Open in Waze'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0), // Rounded corners
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.grey, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0), // Rounded corners
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchMapsUrl(
      double latitude, double longitude, String mapApp) async {
    String url = '';
    if (mapApp == "google_maps") {
      url =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    } else if (mapApp == "waze") {
      url = 'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes';
    }

    // Encode the URL
    final encodedUrl = Uri.encodeFull(url);

    // Check and launch the URL
    if (await canLaunch(encodedUrl)) {
      await launch(encodedUrl);
    } else {
      print('Could not launch $encodedUrl');
    }
  }

  Future<List<String>> _fetchTagNames(List<dynamic> placeTags) async {
    List<String> tagNames = [];
    for (var tag in placeTags) {
      int tagId = tag['placeTagId'];
      String tagName = await _fetchTagName(tagId) ?? "Unknown Tag";
      tagNames.add(tagName);
    }
    return tagNames;
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

  Future<void> _toggleLocationTracking() async {
    if (_locationTimer == null) {
      setState(() => _isFetchingLocation = true); // Start fetching location

      final LocationPermission permission =
          await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        setState(() =>
            _isFetchingLocation = false); // Stop fetching location if denied
        return;
      }

      _updateUserLocation(); // This already has setState inside
      _locationTimer = Timer.periodic(Duration(seconds: 20), (timer) {
        _updateUserLocation();
      });
    } else {
      // Stop tracking user location
      setState(() {
        _locationTimer?.cancel();
        _locationTimer = null;
        _markers
            .removeWhere((marker) => marker.key == ValueKey('UserLocation'));
        _isFetchingLocation = false; // Stop fetching location
      });
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
        debugPrint("Fetched nickname for user ${userId}: ${data['nickname']}");
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

  Future<void> _updateUserLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition();
      final int? userId = await _fetchUserId();
      if (userId == null) {
        debugPrint("Failed to fetch user ID");
        return;
      }

      final String? nickname = await _fetchUserName(userId);
      if (nickname == null) {
        debugPrint("Failed to fetch nickname");
        return;
      }

      // Assuming _createOrUpdatePlaceWithLocation is implemented and works asynchronously
      // This method should create a place on your backend and return a Place object
      final Place place = await _createOrUpdatePlaceWithLocation(
          nickname,
          "Realtime location of $nickname",
          position.latitude,
          position.longitude);

      if (!mounted) return; // Check if the widget is still mounted

      setState(() {
        _markers
            .removeWhere((marker) => marker.key == ValueKey('UserLocation'));
        _markers.add(
          Marker(
            key: ValueKey('UserLocation'),
            point: LatLng(position.latitude, position.longitude),
            child: GestureDetector(
              onTap: () => _showPlaceDetails(
                  place), // Ensure _showPlaceDetails is defined and works
              child: Icon(Icons.location_pin, color: Colors.blue, size: 50),
            ),
          ),
        );
        _isFetchingLocation =
            false; // Indicate that location fetching is complete
      });
    } catch (e) {
      if (!mounted)
        return; // Again, check if the widget is still mounted before calling setState
      setState(() => _isFetchingLocation = false);
      debugPrint('Error updating user location: $e');
    }
  }

  Future<Place> _createOrUpdatePlaceWithLocation(String nickname,
      String description, double latitude, double longitude) async {
    String baseUrl = GlobalConfig().serverUrl;
    String? authToken = await SecureStorageManager.getAuthToken();
    Map<String, dynamic> requestBodyPost = {
      "name": nickname,
      "description": description,
      "latitude": latitude,
      "longitude": longitude,
      "realtime": true,
    };

    Map<String, dynamic> requestBodyPut = {
      "latitude": latitude,
      "longitude": longitude,
    };

    // Attempt to create the place with a POST request
    var response = await http.post(
      Uri.parse('$baseUrl/api/place'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie':
            'authToken=$authToken', // Use 'Authorization' with Bearer token
      },
      body: json.encode(requestBodyPost),
    );

    // If the place already exists (HTTP 409), parse the response to get the existing place's ID
    if (response.statusCode == 409) {
      final responseBody = json.decode(response.body);
      final existingPlaceId =
          responseBody['placeId']; // Get the placeId from the response body

      // Perform the PUT request to update the existing place
      response = await http.put(
        Uri.parse('$baseUrl/api/place/$existingPlaceId'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken',
        },
        body: json.encode(requestBodyPut),
      );
    }

    // Handle success for both POST and PUT requests
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return Place.fromJson(data); // Convert the response to a Place object
    } else {
      debugPrint(
          'Failed to create or update place: ${response.body}, status code: ${response.statusCode}');
      throw Exception(
          'Failed to create or update place, status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: content(),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleLocationTracking,
        backgroundColor: Colors.blue,
        child: Icon(_locationTimer == null ? Icons.gps_fixed : Icons.gps_off),
        elevation: 2.0,
      ),
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
                Navigator.push(context,
                        MaterialPageRoute(builder: (context) => AddTokenPage()))
                    .then((result) {
                  // Check if the result is true indicating that a token was sent successfully
                  if (result == true) {
                    // Refresh your HomePage content here if necessary
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ListPlacesPage()),
                );
                if (result == true) {
                  await _fetchUserIdAndPlaces();
                }
                // Only update user location if location tracking is enabled
                if (_locationTimer != null) {
                  await _updateUserLocation();
                }
              },
            ),

            SizedBox(
                width:
                    48), // This SizedBox serves as a placeholder for the FAB.
            IconButton(
              icon: Icon(Icons.account_circle, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
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
    return Stack(
      children: <Widget>[
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(45.7032695, 3.3448536),
            initialZoom: 8,
            interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
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
                  _updateUserLocation();
                } else if (result == false) {
                  if (mounted) {
                    setState(() {
                      _markers
                          .removeLast(); // Remove temporary marker if place creation was cancelled
                    });
                  }
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
        ),
        if (_isFetchingLocation) // Check if the location is currently being fetched
          Positioned(
            child: Container(
              alignment: Alignment.center,
              color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
              child: CircularProgressIndicator(), // Loading indicator
            ),
          ),
      ],
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    );
