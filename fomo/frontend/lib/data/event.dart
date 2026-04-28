import 'user.dart';

class Event {
  final String id;
  final String title;
  final DateTime date;
  final String location;
  int attending;
  final String description;
  final User poster;
  // final String imageUrl;
  bool isRsvpd;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.attending,
    required this.description,
    required this.poster,
    // required this.imageUrl,
    this.isRsvpd = false,
  });

  factory Event.fromBackend(Map<String, dynamic> json) {
    final posterName = (json['poster_name'] as String?) ?? 'unknown';
    final posterId = (json['poster_id'] as String?) ?? 'unknown';
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      location: json['location'] as String,
      attending: (json['attending'] as num).toInt(),
      description: json['description'] as String,
      poster: User.fromBackend(id: posterId, username: posterName),
      isRsvpd: json['is_rsvpd'] as bool? ?? false,
    );
  }
}
