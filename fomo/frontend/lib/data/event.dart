import 'user.dart';

class Event {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  int attending;
  final String description;
  final User poster;
  final double? latitude;
  final double? longitude;
  // final String imageUrl;
  bool isRsvpd;

  Event({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.attending,
    required this.description,
    required this.poster,
    this.latitude,
    this.longitude,
    // required this.imageUrl,
    this.isRsvpd = false,
  });

  DateTime get date => startTime;

  factory Event.fromBackend(Map<String, dynamic> json) {
    final posterName = (json['poster_name'] as String?) ?? 'unknown';
    final posterId = (json['poster_id'] as String?) ?? 'unknown';
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(
        (json['start_time'] as String?) ?? (json['date'] as String),
      ),
      endTime: DateTime.parse(
        (json['end_time'] as String?) ??
            (json['start_time'] as String?) ??
            (json['date'] as String),
      ),
      location: json['location'] as String,
      attending: (json['attending'] as num).toInt(),
      description: json['description'] as String,
      poster: User.fromBackend(id: posterId, username: posterName),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isRsvpd: json['is_rsvpd'] as bool? ?? false,
    );
  }
}
