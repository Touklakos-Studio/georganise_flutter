import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'create_place_page.dart';
import 'list_places_page.dart';
import 'settings_page.dart';
import 'welcome_page.dart';
import 'secure_storage_manager.dart';
import 'add_place_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  bool _isDoubleTap = false; // Declare the _isDoubleTap variable

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
                );
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
              onPressed: () async {
                // Call deleteAuthToken to remove the stored authentication token
                await SecureStorageManager.deleteAuthToken();
                debugPrint('Auth token deleted successfully');

                // Navigate to the WelcomePage and remove all previous routes
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                  (Route<dynamic> route) => false,
                );
              },
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
        initialCenter: LatLng(51.5, -0.09),
        initialZoom: 11,
        interactionOptions:
            const InteractionOptions(flags: ~InteractiveFlag.doubleTapZoom),
        onTap: (tapPosition, latLng) async {
          if (_isDoubleTap) {
            setState(() {
              _markers.add(
                Marker(
                  point: latLng,
                  width: 80.0,
                  height: 80.0,
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.location_pin),
                    iconSize: 60,
                    color: Colors.red,
                    onPressed: () {},
                  ),
                ),
              );
            });

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreatePlacePage(
                  position: latLng,
                ),
              ),
            );

            if (result == false) {
              setState(() {
                _markers.removeLast();
              });
            }

            _isDoubleTap = false;
          } else {
            _isDoubleTap = true;
            Future.delayed(const Duration(milliseconds: 300), () {
              _isDoubleTap = false;
            });
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
