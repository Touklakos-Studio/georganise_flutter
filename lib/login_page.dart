import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For using jsonEncode
import 'secure_storage_manager.dart';
import 'global_config.dart';
import 'package:crypto/crypto.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  String _password = '';

  void _tryLogin() async {
    String baseUrl = GlobalConfig().serverUrl;
    final isValid = _formKey.currentState?.validate();
    if (isValid == true) {
      _formKey.currentState?.save();

      // Hash the password with SHA256
      var bytes = utf8.encode(_password); // data being hashed
      var hashedPassword = sha256.convert(bytes).toString();

      http.Response response;
      try {
        response = await http.post(
          Uri.parse('$baseUrl/api/user/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _email,
            'password': hashedPassword,
          }),
        );
      } catch (e) {
        debugPrint('Error logging in: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('The server URL is invalid or unreachable')),
        );
        rethrow;
      }

      if (response.statusCode == 200) {
        debugPrint('Login successful');

        // Extract cookies from response headers
        final String? rawCookie = response.headers['set-cookie'];
        String? authToken;
        if (rawCookie != null) {
          // Assuming the cookie format is "authToken=tokenValue; Path=/; Expires=..."
          final int index = rawCookie.indexOf(';');
          authToken = (index == -1) ? rawCookie : rawCookie.substring(0, index);
          // Further extract authToken value if necessary
          if (authToken.startsWith('authToken=')) {
            authToken =
                authToken.substring('authToken='.length, authToken.length);
          }
        }

        // Check if authToken is extracted successfully
        if (authToken != null && authToken.isNotEmpty) {
          await SecureStorageManager.storeAuthToken(authToken);
          debugPrint('Auth token stored successfully');
        } else {
          debugPrint('No auth token found in the response cookies');
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else if (response.statusCode == 400) {
        debugPrint('Login failed');
        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      } else {
        debugPrint('Login failed');
        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Login',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) => _email = value!,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email address';
                  } else if (!emailRegex.hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                obscureText: true,
                onSaved: (value) => _password = value!,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'A password is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: _tryLogin,
                child: const Icon(Icons.arrow_forward, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
