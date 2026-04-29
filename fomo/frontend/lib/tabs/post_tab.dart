import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../data/event.dart';
import '../data/user.dart';

class PostTab extends StatefulWidget {

  final Future<void> Function(Event) onEventPosted;

  const PostTab({super.key, required this.onEventPosted});

  @override
  State<PostTab> createState() => _PostTabState();
}

class _PostTabState extends State<PostTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationFocusNode = FocusNode();
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _resolvingAddress = false;
  bool _loadingSuggestions = false;
  Timer? _locationDebounce;
  List<_AddressSuggestion> _locationSuggestions = [];
  _AddressSuggestion? _selectedSuggestion;

  // Mock current user
  final User currentUser = User(
    id: 'current',
    name: 'You',
    avatarUrl: 'https://via.placeholder.com/50',
  );
 
  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _locationFocusNode.dispose();
    _locationDebounce?.cancel();
    super.dispose();
  }

  void _onLocationChanged(String value) {
    if (_selectedSuggestion != null && value.trim() != _selectedSuggestion!.label) {
      _selectedSuggestion = null;
    }
    _locationDebounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _locationSuggestions = [];
        _loadingSuggestions = false;
      });
      return;
    }

    _locationDebounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _loadingSuggestions = true);
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&limit=5&addressdetails=1&q=${Uri.encodeQueryComponent(query)}',
        );
        final response = await http.get(
          uri,
          headers: {'User-Agent': 'FOMO/1.0 address-autocomplete'},
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final parsed = jsonDecode(response.body) as List<dynamic>;
          final suggestions = parsed
              .map((e) => e as Map<String, dynamic>)
              .map(
                (e) => _AddressSuggestion(
                  label: (e['display_name'] as String?) ?? '',
                  latitude: double.tryParse((e['lat'] as String?) ?? ''),
                  longitude: double.tryParse((e['lon'] as String?) ?? ''),
                ),
              )
              .where((s) => s.label.isNotEmpty)
              .toList();
          if (!mounted) return;
          setState(() => _locationSuggestions = suggestions);
        } else if (mounted) {
          setState(() => _locationSuggestions = []);
        }
      } catch (_) {
        if (mounted) setState(() => _locationSuggestions = []);
      } finally {
        if (mounted) setState(() => _loadingSuggestions = false);
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedStartTime = picked);
  }

  Future<void> _submit() async {
    if (_resolvingAddress) return;
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedStartTime != null &&
        _selectedEndTime != null) {
      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
      );
      final endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedEndTime!.hour,
        _selectedEndTime!.minute,
      );
      if (!endDateTime.isAfter(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }
      setState(() => _resolvingAddress = true);
      double? latitude;
      double? longitude;
      if (_selectedSuggestion != null &&
          _locationController.text.trim() == _selectedSuggestion!.label &&
          _selectedSuggestion!.latitude != null &&
          _selectedSuggestion!.longitude != null) {
        latitude = _selectedSuggestion!.latitude;
        longitude = _selectedSuggestion!.longitude;
      } else {
        try {
          final results = await locationFromAddress(_locationController.text.trim());
          if (results.isNotEmpty) {
            latitude = results.first.latitude;
            longitude = results.first.longitude;
          }
        } catch (_) {}
      }

      if (latitude == null || longitude == null) {
        if (!mounted) return;
        setState(() => _resolvingAddress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid address (street/city/state).'),
          ),
        );
        return;
      }

      final event = Event(
        id: Uuid().v4(),
        title: _titleController.text,
        startTime: startDateTime,
        endTime: endDateTime,
        location: _locationController.text,
        attending: 1, // Assuming the creator is attending
        description: _descriptionController.text,
        poster: currentUser,
        latitude: latitude,
        longitude: longitude,
        isRsvpd: true,
      );
      
      await widget.onEventPosted(event);

      if (!mounted) return;
      _titleController.clear();
      _locationController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedDate = null;
        _selectedStartTime = null;
        _selectedEndTime = null;
        _selectedSuggestion = null;
        _resolvingAddress = false;
      });
    } else if (_selectedDate == null ||
        _selectedStartTime == null ||
        _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date, start time, and end time')),
      );
    } else {
      setState(() => _resolvingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Post an Event', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                focusNode: _locationFocusNode,
                onChanged: _onLocationChanged,
                decoration: const InputDecoration(
                  labelText: 'Location (real address)',
                  hintText: '123 Main St, City, State',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a location' : null,
              ),
              if (_loadingSuggestions) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (_locationSuggestions.isNotEmpty && _locationFocusNode.hasFocus) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: _locationSuggestions.map((suggestion) {
                      return ListTile(
                        dense: true,
                        title: Text(
                          suggestion.label,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          _locationController.text = suggestion.label;
                          setState(() {
                            _selectedSuggestion = suggestion;
                            _locationSuggestions = [];
                          });
                          _locationFocusNode.unfocus();
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a description' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDate == null
                          ? 'Pick a Date'
                          : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedStartTime == null
                          ? 'Start Time'
                          : _selectedStartTime!.format(context)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedEndTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedEndTime = picked);
                        }
                      },
                      icon: const Icon(Icons.schedule),
                      label: Text(_selectedEndTime == null
                          ? 'End Time'
                          : _selectedEndTime!.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _resolvingAddress ? null : () => _submit(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _resolvingAddress ? 'Validating address...' : 'Post Event',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressSuggestion {
  final String label;
  final double? latitude;
  final double? longitude;

  const _AddressSuggestion({
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}