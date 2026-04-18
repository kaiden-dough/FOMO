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
}
