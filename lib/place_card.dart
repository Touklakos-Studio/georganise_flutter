import 'package:flutter/material.dart';
// Add any other imports needed for this widget, such as models or controllers

class PlaceCard extends StatefulWidget {
  @override
  _PlaceCardState createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0), // Add margin to the card
      child: Padding(
        padding: EdgeInsets.all(8.0), // Add padding inside the card
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Use the minimum space needed by the children
          children: <Widget>[
            ListTile(
              title: Text('Title'),
              subtitle: Text(
                'Description, Lorem Ipsum fakindhu nhun anu nhuaz nhuind nahuzn uhnazduhnu abu buhbz uhbuazdb uhu buazdhb uhzalb huhduzab uh ubhazud buazb.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: 8.0), // Add padding around the tag area
              child: Wrap(
                spacing: 8.0,
                children: <Widget>[
                  Chip(
                    label: Text('tag1'),
                  ),
                  Chip(
                    label: Text('tag2'),
                  ),
                  Chip(
                    label: Text('tag3'),
                  ),
                ],
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
                // If you're not the owner, show the person icon
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
