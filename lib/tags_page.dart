import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'secure_storage_manager.dart'; // Import the SecureStorageManager class

class TagsPage extends StatefulWidget {
  final List<int> initialSelectedTagIds;

  const TagsPage({Key? key, this.initialSelectedTagIds = const []})
      : super(key: key);

  @override
  _TagsPageState createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  List<dynamic> _tags = [];
  List<int> _selectedTagIds = [];
  final TextEditingController _tagTitleController = TextEditingController();
  final TextEditingController _tagDescriptionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTagIds = List.from(widget.initialSelectedTagIds);
    _fetchTags();
  }

  Future<void> _fetchTags() async {
    try {
      String? authToken = await SecureStorageManager.getAuthToken();

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/tag'),
        headers: {
          'Cookie': 'authToken=$authToken', // Add the AuthToken as a cookie
        },
      );

      debugPrint('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        setState(() {
          _tags = json.decode(response.body);
        });
        debugPrint('Tags fetched successfully');
        debugPrint('Response body: ${response.body}');
      } else if (response.statusCode == 401) {
        debugPrint('Authentication failed');
        debugPrint('Response status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      } else {
        debugPrint('Failed to fetch tags');
        debugPrint('Response status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('An error occurred while fetching tags');
      debugPrint('Error: $e');
    }
  }

  void _toggleTagSelection(int tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });
  }

  Future<void> _createTag() async {
    try {
      String? authToken = await SecureStorageManager.getAuthToken();

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/tag'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken',
        },
        body: json.encode({
          'title': _tagTitleController.text,
          'description': _tagDescriptionController.text,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Tag created successfully');
        _tagTitleController.clear();
        _tagDescriptionController.clear();
        await _fetchTags(); // Refetch the tags after creating a new one
      } else if (response.statusCode == 401) {
        debugPrint('Authentication failed');
        debugPrint('Response status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      } else {
        debugPrint('Failed to create tag');
        debugPrint('Response status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('An error occurred while creating a tag');
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Tags'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagTitleController,
                    decoration: InputDecoration(
                      labelText: 'Tag Title',
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _tagDescriptionController,
                    decoration: InputDecoration(
                      labelText: 'Tag Description',
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _createTag,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                  ),
                  child: Text('Create Tag'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tags.length,
              itemBuilder: (context, index) {
                final tag = _tags[index];
                final isSelected = _selectedTagIds.contains(tag['tagId']);

                return ListTile(
                  title: Text(tag['title']),
                  subtitle:
                      Text(tag['description']), // Display the description here
                  trailing: IconButton(
                    icon: Icon(
                      isSelected ? Icons.check : Icons.add,
                      color: isSelected ? Colors.green : null,
                    ),
                    onPressed: () {
                      _toggleTagSelection(tag['tagId']);
                    },
                  ),
                  onTap: () {
                    _toggleTagSelection(tag['tagId']);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, _selectedTagIds);
        },
        child: Icon(Icons.check),
      ),
    );
  }
}
