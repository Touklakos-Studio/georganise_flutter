import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For using jsonEncode
import 'secure_storage_manager.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String _nickname = '';
  String _email = '';
  String _password = '';
  String?
      _errorMessage; // Define the _errorMessage variable as a nullable string

  void _tryRegister() async {
    final isValid = _formKey.currentState?.validate();
    if (isValid == true) {
      _formKey.currentState?.save();

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nickname': _nickname,
          'email': _email,
          'password': _password,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Registration successful');

        // Extract the authToken from the Set-Cookie header
        final String? rawCookie = response.headers['set-cookie'];
        String? authToken;
        if (rawCookie != null) {
          // Here we look for the specific cookie named 'authToken', adjust if your token has a different name
          final RegExp regex = RegExp(r'authToken=([^;]+)');
          final match = regex.firstMatch(rawCookie);
          authToken = match?.group(1); // Extract the authToken value
        }

        // Check if authToken is successfully extracted
        if (authToken != null && authToken.isNotEmpty) {
          await SecureStorageManager.storeAuthToken(authToken);
          debugPrint('Auth token stored successfully');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          debugPrint('No auth token found in the response cookies');
          // Handle the scenario where the authToken is not found in the cookies
        }
      } else {
        debugPrint('Registration failed');
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
                'Register',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Nickname',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSaved: (value) => _nickname =
                    value!, // Make sure you have a variable _nickname to store the value
              ),
              const SizedBox(height: 16),
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
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed:
                    _tryRegister, // Make sure the _tryRegister method is adapted to handle nickname, email, and password
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
