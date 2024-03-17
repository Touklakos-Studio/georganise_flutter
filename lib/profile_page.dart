import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'secure_storage_manager.dart';
import 'global_config.dart';
import 'welcome_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
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
        setState(() {
          _userData = data;
        });
      } else {
        debugPrint('Failed to fetch user data: ${response.body}');
      }
    } catch (e) {
      debugPrint('An error occurred while fetching user data: $e');
    }
  }

  Future<void> _deleteAccountAndLogout() async {
    // Show a confirmation dialog before deleting the account
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete your account?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Close the dialog without deleting the account
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                try {
                  String baseUrl = GlobalConfig().serverUrl;
                  // Attempt to retrieve the authToken from secure storage
                  String? authToken = await SecureStorageManager.getAuthToken();

                  // Make the DELETE request to delete the user account on the backend
                  final deleteResponse = await http.delete(
                    Uri.parse(
                        '$baseUrl/api/user/${_userData?['userId'].toString()}'), // Convert userId to string
                    headers: {
                      'Content-Type': 'application/json',
                      'Cookie': 'authToken=$authToken',
                    },
                  );

                  // Check the response status code for account deletion
                  if (deleteResponse.statusCode == 200 ||
                      deleteResponse.statusCode == 204) {
                    // Proceed with the logout process
                    final logoutResponse = await http.post(
                      Uri.parse('$baseUrl/api/user/logout'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Cookie': 'authToken=$authToken',
                      },
                    );

                    // Check the response status code for logout
                    if (logoutResponse.statusCode == 200 ||
                        logoutResponse.statusCode == 204) {
                      debugPrint('Logout successful on backend');
                    } else {
                      debugPrint(
                          'Failed to logout on backend. Status code: ${logoutResponse.statusCode}');
                    }

                    // Regardless of the response, clear the authToken from secure storage
                    await SecureStorageManager.deleteAuthToken();
                    debugPrint(
                        'Auth token deleted successfully from local storage');

                    // Navigate to the WelcomePage and remove all previous routes
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const WelcomePage()),
                      (Route<dynamic> route) => false,
                    );
                    debugPrint('Account deletion successful on backend');
                  } else {
                    debugPrint(
                        'Failed to delete account on backend. Status code: ${deleteResponse.statusCode}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete account'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint(
                      'An error occurred during account deletion and logout: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'An error occurred during account deletion and logout'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  Navigator.of(context)
                      .pop(); // Close the dialog after deleting the account or handling errors
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: _userData == null
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nickname',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _userData?['nickname'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _userData?['email'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _deleteAccountAndLogout(),
                    child: Text('Delete Account'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
      ),
      backgroundColor: Colors.green,
    );
  }
}
