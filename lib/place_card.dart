import 'package:flutter/material.dart';
import 'place.dart'; // Ensure this matches your file structure

class PlaceCard extends StatelessWidget {
  final Place place;

  PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(place.title),
              subtitle: Text(
                place.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Wrap(
                spacing: 8.0,
                children: place.tags
                    .map((tag) => Chip(
                          label: Text(tag),
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
