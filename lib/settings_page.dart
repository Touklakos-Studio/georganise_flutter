import 'package:flutter/material.dart';
// Add any other imports needed for settings, such as shared_preferences for storing settings

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool localizationEnabled = false; // Initial state for localization switch
  bool shareEnabled = false; // Initial state for share switch

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              title: Text(
                'Localization authorization',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              trailing: Switch(
                value: localizationEnabled,
                onChanged: (value) {
                  setState(() {
                    localizationEnabled = value;
                  });
                  // TODO: Add the logic to persist this setting
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.lightGreenAccent,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              title: Text(
                'Share authorization',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              trailing: Switch(
                value: shareEnabled,
                onChanged: (value) {
                  setState(() {
                    shareEnabled = value;
                  });
                  // TODO: Add the logic to persist this setting
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.lightGreenAccent,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.green,
    );
  }
}
