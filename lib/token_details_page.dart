import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secure_storage_manager.dart';
import 'global_config.dart';
import 'package:flutter/services.dart';

class TokenDetailsPage extends StatefulWidget {
  final List<dynamic> tokenDetails;

  const TokenDetailsPage({super.key, required this.tokenDetails});

  @override
  _TokenDetailsPageState createState() => _TokenDetailsPageState();
}

class _TokenDetailsPageState extends State<TokenDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
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
          .showSnackBar(const SnackBar(content: Text("Auth token is not available")));
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
          const SnackBar(content: Text('Token access right updated successfully')));
      Navigator.of(context).pop(
          true); // Assuming you might have a mechanism to refresh the parent page.
    } else if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized to update token access right')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update token access right')));
    }
  }

  Widget _editTokenAccessRightButton(int tokenId, String currentAccessRight) {
    return IconButton(
      icon: const Icon(Icons.edit, color: Colors.blue),
      onPressed: () {
        _showEditTokenDialog(tokenId, currentAccessRight);
      },
    );
  }

  void _showEditTokenDialog(int tokenId, String currentAccessRight) {
    bool isWriter = currentAccessRight == "WRITER";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Token Access Right"),
              content: SwitchListTile(
                title: Text(isWriter ? "Writer" : "Reader"),
                value: isWriter,
                onChanged: (bool value) {
                  setState(() {
                    isWriter = value;
                  });
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Update'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _updateTokenAccessRight(
                        tokenId, isWriter ? "WRITER" : "READER");
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _deleteTokenButton(int tokenId) {
    return IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () => _showDeleteConfirmation(tokenId),
    );
  }

  void _showDeleteConfirmation(int tokenId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Token"),
          content: const Text("Are you sure you want to delete this token?"),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteToken(tokenId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteToken(int tokenId) async {
    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Auth token is not available")));
      return;
    }

    String baseUrl = GlobalConfig().serverUrl;
    final response = await http.delete(
      Uri.parse('$baseUrl/api/token/$tokenId'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Token deleted successfully')));
      // Optionally refresh the list or navigate back
      setState(() {
        widget.tokenDetails.removeWhere((token) => token['tokenId'] == tokenId);
      });
    } else if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized to delete token')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to delete token')));
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token copied to clipboard'),
        ),
      );
    });
  }

  Future<String> _fetchNickname(int? userId) async {
    // Check if userId is null and return a default nickname value
    if (userId == null) {
      return "None";
    }

    String? authToken = await SecureStorageManager.getAuthToken();
    if (authToken == null) throw Exception("Auth token is not available");

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
      return data['nickname'];
    } else {
      throw Exception('Failed to fetch user nickname');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Token Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actionsIconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Token ID',
                labelStyle: const TextStyle(
                  color: Colors.grey, // Greyish text color
                ),
                // Adding clear button
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear(); // Clear text field content
                  },
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey, // Greyish border when not focused
                    width: 2.0,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.green, // Greyish border when typing
                    width: 2.0,
                  ),
                ),
              ),
              onSubmitted: (value) {
                // Implement search functionality here if needed
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTokenDetails.length,
              itemBuilder: (BuildContext context, int index) {
                var token = _filteredTokenDetails[index];
                bool canModify = token['creatorId'] == token['userId'];

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                      "Token ID: ${token['tokenId']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Access Right: ${token['accessRight']}"),
                        Text("Token Value: ${token['tokenValue']}"),
                        FutureBuilder<String>(
                          future: _fetchNickname(token['creatorId']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return Text("Creator: ${snapshot.data}");
                            } else {
                              return const Text("Loading creator...");
                            }
                          },
                        ),
                        FutureBuilder<String>(
                          future: _fetchNickname(token['userId']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return Text("User: ${snapshot.data}");
                            } else {
                              return const Text("Loading user...");
                            }
                          },
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Copy to Clipboard button is shown to everyone
                        IconButton(
                          icon: const Icon(Icons.content_copy, color: Colors.grey),
                          onPressed: () =>
                              _copyToClipboard(token['tokenValue']),
                        ),
                        // Conditionally show edit and delete buttons
                        if (true) ...[
                          _editTokenAccessRightButton(
                              token['tokenId'], token['accessRight']),
                          _deleteTokenButton(token['tokenId']),
                        ],
                      ],
                    ),
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
