import 'package:flutter/material.dart';
import 'place_card.dart';
import 'place.dart'; // Make sure this import path matches your file structure

class ListPlacesPage extends StatelessWidget {
  // Example places data
  final List<Place> places = List.generate(
    10,
    (index) => Place(
      title: 'Place $index',
      description: 'Description for place $index, a great place to visit.',
      tags: ['tag1', 'tag2'],
    ),
  );

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
              // Implement search functionality
            },
          ),
        ],
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount: places.length,
          itemBuilder: (context, index) {
            final place = places[index];
            return Column(
              children: [
                PlaceCard(place: place),
                if (index < places.length - 1) Divider(color: Colors.grey),
              ],
            );
          },
        ),
      ),
    );
  }
}
