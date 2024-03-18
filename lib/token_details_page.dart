import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secure_storage_manager.dart';
import 'global_config.dart';

class TokenDetailsPage extends StatefulWidget {
  final List<dynamic> tokenDetails;

  const TokenDetailsPage({Key? key, required this.tokenDetails})
      : super(key: key);

  @override
  _TokenDetailsPageState createState() => _TokenDetailsPageState();
}

class _TokenDetailsPageState extends State<TokenDetailsPage> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredTokenDetails = [];

  @override
  void initState() {
    super.initState();
    _filteredTokenDetails = widget.tokenDetails;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _filteredTokenDetails = widget.tokenDetails
          .where((token) =>
              token['tokenId']
                  .toString()
                  .contains(_searchController.text.trim()) ||
              _searchController.text.trim().isEmpty)
          .toList();
    });
  }

  Future<void> _updateTokenAccessRight(int tokenId, String accessRight) async {
    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Auth token is not available")));
      return;
    }
    String baseUrl = GlobalConfig().serverUrl;
    final response = await http.put(
      Uri.parse('$baseUrl/api/token/$tokenId'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken'
      },
      body: jsonEncode({"accessRight": accessRight}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Token access right updated successfully')));
      Navigator.of(context).pop(
          true); // Assuming you might have a mechanism to refresh the parent page.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update token access right')));
    }
  }

  Widget _editTokenAccessRightButton(int tokenId, String currentAccessRight) {
    return IconButton(
      icon: Icon(Icons.edit, color: Colors.blue),
      onPressed: () {
        _showEditTokenDialog(tokenId, currentAccessRight);
      },
    );
  }

  void _showEditTokenDialog(int tokenId, String currentAccessRight) {
    bool _isWriter = currentAccessRight == "WRITER";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Edit Token Access Right"),
              content: SwitchListTile(
                title: Text(_isWriter ? "Writer" : "Reader"),
                value: _isWriter,
                onChanged: (bool value) {
                  setState(() {
                    _isWriter = value;
                  });
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Update'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _updateTokenAccessRight(
                        tokenId, _isWriter ? "WRITER" : "READER");
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Token Details'),
        backgroundColor: Colors.green,
        actions: <Widget>[],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Token ID',
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTokenDetails.length,
              itemBuilder: (BuildContext context, int index) {
                var token = _filteredTokenDetails[index];
                // Token ListTile...
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text("Token ID: ${token['tokenId']}",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "Access Right: ${token['accessRight']}\nToken Value: ${token['tokenValue']}"),
                    trailing: _editTokenAccessRightButton(
                        token['tokenId'], token['accessRight']),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
