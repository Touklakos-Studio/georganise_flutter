import 'package:latlong2/latlong.dart';

class Place {
  final int placeId;
  final double latitude;
  final double longitude;
  final String name;
  final String description;
  final int? imageId;
  final int userId;
  final List<dynamic> placeTags;
  final LatLng? position;

  Place({
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.description,
    this.imageId,
    required this.userId,
    required this.placeTags,
    this.position,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      placeId: json['placeId'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      name: json['name'],
      description: json['description'],
      imageId: json['imageId'] as int?,
      userId: json['userId'],
      placeTags: json['placeTags'] ?? [], // Assuming placeTags is optional
    );
  }
}
