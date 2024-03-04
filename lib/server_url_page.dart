import 'package:flutter/material.dart';
// Add any other imports needed for this page

class ServerURLPage extends StatefulWidget {
  const ServerURLPage({Key? key}) : super(key: key);

  @override
  _ServerURLPageState createState() => _ServerURLPageState();
}

class _ServerURLPageState extends State<ServerURLPage> {
  // Create a text controller and use it to set the initial value
  final TextEditingController _controller =
      TextEditingController(text: "http://localhost:8080");

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
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
      body: Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Use the minimum space needed by the children
          children: [
            const Text(
              'Server URL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Enter server URL',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.link, color: Colors.green.shade800),
              ),
            ),
            const SizedBox(height: 40),
            FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                // Implement your logic to handle server URL submission
                // For example, you might save the value to a server or app settings
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.arrow_forward, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
