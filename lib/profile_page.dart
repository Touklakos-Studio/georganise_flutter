import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'secure_storage_manager.dart';
import 'global_config.dart';
import 'welcome_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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

  // Fetch the user data from the server
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

  // Show a confirmation dialog before deleting the account
  Future<bool> _showDeleteConfirmationDialog() async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible:
          false, // Prevents closing the dialog by tapping outside of it
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete your account?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () =>
                  Navigator.of(context).pop(false), // Explicitly passing false
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () =>
                  Navigator.of(context).pop(true), // Explicitly passing true
            ),
          ],
        );
      },
    );

    return result ??
        false; // Ensures a boolean return, defaulting to false if null
  }

  // Delete the account and log out the user if the user confirms the deletion
  Future<void> _deleteAccountAndLogout() async {
    // First, show the delete confirmation dialog and wait for the user's response
    bool confirmDelete = await _showDeleteConfirmationDialog();

    // If the user confirmed the deletion, proceed
    if (confirmDelete) {
      try {
        String baseUrl = GlobalConfig().serverUrl;
        String? authToken = await SecureStorageManager.getAuthToken();

        final deleteResponse = await http.delete(
          Uri.parse('$baseUrl/api/user/${_userData?['userId'].toString()}'),
          headers: {
            'Content-Type': 'application/json',
            'Cookie': 'authToken=$authToken',
          },
        );

        // If the account is successfully deleted, navigate to the WelcomePage
        if (deleteResponse.statusCode == 200 ||
            deleteResponse.statusCode == 204) {
          await SecureStorageManager.deleteAuthToken();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WelcomePage()),
            (Route<dynamic> route) => false,
          );
        } else {
          // If the deletion was not successful, show an error snackbar
          _showErrorSnackBar('Failed to delete account');
        }
      } catch (e) {
        // Handle any exceptions by showing an error snackbar
        _showErrorSnackBar(
            'An error occurred during account deletion and logout');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: _userData == null
            ? const CircularProgressIndicator()
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
                        const Text(
                          'Nickname',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _userData?['nickname'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _userData?['email'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _deleteAccountAndLogout,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Delete Account'),
                  ),
                ],
              ),
      ),
      backgroundColor: Colors.green,
    );
  }
}
