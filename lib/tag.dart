class Tag {
  final int id;
  final String title;
  final String description;

  Tag({required this.id, required this.title, required this.description});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      title: json['title'],
      description: json['description'],
    );
  }
}
