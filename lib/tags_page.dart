import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'secure_storage_manager.dart';
import 'global_config.dart';

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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTagIds = List.from(widget.initialSelectedTagIds);
    _fetchTags();
  }

  String baseUrl = GlobalConfig().serverUrl;

  Future<void> _fetchTags() async {
    try {
      String? authToken = await SecureStorageManager.getAuthToken();

      final response = await http.get(
        Uri.parse('$baseUrl/api/tag'),
        headers: {
          'Cookie': 'authToken=$authToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _tags = json.decode(response.body);
        });
        debugPrint('Tags fetched successfully');
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
        Uri.parse('$baseUrl/api/tag'),
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
        await _fetchTags(); // Refetch the tags first
        _searchController.text = _tagTitleController
            .text; // Set the search query to the newly created tag's title
        _searchController.selection = TextSelection.fromPosition(TextPosition(
            offset: _searchController.text
                .length)); // Move the cursor to the end of the search query
        setState(() {}); // Trigger a rebuild to update the search results
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

  Future<void> _deleteTag(int tagId) async {
    try {
      String? authToken = await SecureStorageManager.getAuthToken();

      final response = await http.delete(
        Uri.parse('$baseUrl/api/tag/$tagId'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Tag deleted successfully');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Tag deleted successfully')));
        await _fetchTags(); // Refetch the tags after deleting one
      } else {
        debugPrint('Failed to delete tag');
        debugPrint('Response status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to delete tag')));
      }
    } catch (e) {
      debugPrint('An error occurred while deleting a tag');
      debugPrint('Error: $e');
    }
  }

  Future<void> _fetchTagsByKeyword(String keyword) async {
    try {
      String? authToken = await SecureStorageManager.getAuthToken();

      final response = await http.get(
        Uri.parse('$baseUrl/api/tag/keyword/$keyword'),
        headers: {
          'Cookie': 'authToken=$authToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _tags = json.decode(response.body);
        });
        debugPrint('Tags fetched successfully');
        debugPrint('Response body: ${response.body}');
      } else {
        debugPrint('Failed to fetch tags by keyword');
        debugPrint('Response status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('An error occurred while fetching tags by keyword');
      debugPrint('Error: $e');
    }
  }

  Future<void> _editTagDescription(dynamic tag) async {
    final TextEditingController _editDescriptionController =
        TextEditingController(text: tag['description']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Tag Description'),
          content: TextField(
            controller: _editDescriptionController,
            decoration: InputDecoration(hintText: "Enter new description"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Validate'),
              onPressed: () async {
                await _updateTagDescription(
                    tag['tagId'], _editDescriptionController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateTagDescription(int tagId, String newDescription) async {
    try {
      String? authToken = await SecureStorageManager.getAuthToken();
      String baseUrl = GlobalConfig().serverUrl;
      final response = await http.put(
        Uri.parse('$baseUrl/api/tag/$tagId'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken',
        },
        body: json.encode({
          "description": newDescription,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Tag description updated successfully');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tag description updated successfully')));
        await _fetchTags(); // Refetch tags to get updated list
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized to update tag description: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unauthorized to update tag description')));
      } else {
        debugPrint('Failed to update tag description: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update tag description')));
      }
    } catch (e) {
      debugPrint('Error updating tag description: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating tag description')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Place',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Tags',
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onChanged: (query) async {
                      if (query.isEmpty) {
                        await _fetchTags();
                      } else {
                        await _fetchTagsByKeyword(query);
                      }
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
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
                  subtitle: Text(tag['description']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isSelected ? Icons.check : Icons.add,
                          color: isSelected ? Colors.green : null,
                        ),
                        onPressed: () {
                          _toggleTagSelection(tag['tagId']);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _editTagDescription(tag);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteTag(tag['tagId']);
                        },
                      ),
                    ],
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
        backgroundColor: Colors.green,
        child: Icon(Icons.check, color: Colors.white),
      ),
    );
  }
}
