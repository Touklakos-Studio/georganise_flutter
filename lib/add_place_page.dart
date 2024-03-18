import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For using jsonEncode
import 'secure_storage_manager.dart';
import 'global_config.dart';

class AddTokenPage extends StatefulWidget {
  const AddTokenPage({Key? key}) : super(key: key);

  @override
  State<AddTokenPage> createState() => _AddTokenPageState();
}

class _AddTokenPageState extends State<AddTokenPage> {
  final _formKey = GlobalKey<FormState>();
  String _tokenId = '';

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

      var response;
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
        title: const Text('Add Token'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Token ID',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
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
