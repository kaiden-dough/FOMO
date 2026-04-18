import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/event.dart';

class EventItem extends StatelessWidget {
  final Event event;
  final Function(bool) onRSVP;
  final VoidCallback onPressed;

  const EventItem({
    super.key,
    required this.event,
    required this.onRSVP,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(event.poster.avatarUrl),
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(event.poster.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(DateFormat('MMM d, h:mm a').format(event.date), style: const TextStyle(color: Colors.grey)),
              Text(event.location, style: const TextStyle(color: Colors.grey)),
              Text(event.description, style: const TextStyle(color: Colors.grey)),
              Text('${event.attending} attending', style: const TextStyle(color: Colors.grey)),
              RSVPButton(
                initialRsvpd: event.isRsvpd,
                onRSVP: onRSVP,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RSVPButton extends StatefulWidget {

  final bool initialRsvpd;
  final Function(bool) onRSVP;

  const RSVPButton({
    super.key,
    required this.onRSVP,
    this.initialRsvpd = false,
  });

  @override
  State<RSVPButton> createState() => _RSVPButtonState();
}

class _RSVPButtonState extends State<RSVPButton> {
  late bool _rsvpd = false;

  @override
  void initState() {
    super.initState();
    _rsvpd = widget.initialRsvpd;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        setState(() => _rsvpd = !_rsvpd);
        widget.onRSVP(_rsvpd);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _rsvpd ? Color(0x66666666) : Colors.pinkAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(_rsvpd ? 'Cancel RSVP' : 'RSVP'),
    );
  }
}