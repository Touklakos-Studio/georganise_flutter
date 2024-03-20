import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For using jsonEncode
import 'secure_storage_manager.dart';
import 'global_config.dart';

class AddTokenPage extends StatefulWidget {
  const AddTokenPage({super.key});

  @override
  State<AddTokenPage> createState() => _AddTokenPageState();
}

class _AddTokenPageState extends State<AddTokenPage> {
  final _formKey = GlobalKey<FormState>();
  String _tokenId = '';

  // Send a token to backend in order to retrieve places of a specific tag
  void _sendToken() async {
    String baseUrl = GlobalConfig().serverUrl;
    final isValid = _formKey.currentState?.validate();
    if (isValid == true) {
      _formKey.currentState?.save();
      String? authToken = await SecureStorageManager.getAuthToken();

      if (authToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication required")),
        );
        return;
      }

      http.Response response;
      try {
        response = await http.patch(
          Uri.parse('$baseUrl/api/token/$_tokenId'),
          headers: {
            'Content-Type': 'application/json',
            'Cookie': 'authToken=$authToken',
          },
          body: jsonEncode({
            // Add additional body data if required by your API
          }),
        );
      } catch (e) {
        debugPrint('Error sending token: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send token')),
        );
        return;
      }

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token sent successfully')),
        );
        Navigator.pop(context, true); // Add this line
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send token')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Token',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Token',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey, // Grey border when nothing is typed
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.green, // Green border when typing
                      width: 2.0,
                    ),
                  ),
                  // Clear button
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      // Clear the text field content
                      _formKey.currentState?.reset();
                      // Add additional logic if needed
                    },
                  ),
                ),
                onSaved: (value) => _tokenId = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Token ID is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _sendToken,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                ),
                child: const Text('Send Token'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
