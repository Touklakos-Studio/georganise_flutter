import 'package:flutter/material.dart';
import 'place_card.dart'; // If you use a custom widget for displaying places

class ListPlacesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use a SafeArea to avoid any padding issues with system UI
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
              // Implement search functionality
            },
          ),
        ],
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount:
              10, // TODO : Replace with the actual number of PlaceCard you have
          itemBuilder: (context, index) {
            return Column(
              children: [
                PlaceCard(), // Your PlaceCard widget
                if (index ==
                    4) // Assuming index 4 is where you want to insert the divider
                  Divider(color: Colors.white),
              ],
            );
          },
        ),
      ),
    );
  }
}
