import 'package:flutter/material.dart';
import 'place.dart'; // Ensure this matches your file structure

class PlaceCard extends StatelessWidget {
  final Place place;

  PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    // Assuming `tags` might not be directly available as `List<String>` anymore
    // and considering they might need fetching or are complex objects now,
    // the tags display logic might need adjustment or removal if not applicable.

    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(
                  Icons.location_on), // Optional: Add an icon to the list tile
              title: Text(place.name), // Updated to `name`
              subtitle: Text(
                "${place.description}\nLat: ${place.latitude}, Long: ${place.longitude}",
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Display tags if applicable
            // If place.placeTags is not a simple list of strings, this section might need rework
            if (place.placeTags != null &&
                place.placeTags.isNotEmpty) // Checking if tags exist
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  children: place.placeTags
                      .map((tag) => Chip(
                            label: Text(tag
                                .toString()), // Assuming tag can be converted to a string
                          ))
                      .toList(),
                ),
              ),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    // Implement share functionality
                  },
                ),
                IconButton(
                  icon: Icon(Icons.cloud_download),
                  onPressed: () {
                    // Implement download/export functionality
                  },
                ),
                IconButton(
                  icon: Icon(Icons.person),
                  onPressed: () {
                    // Implement view owner functionality
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
