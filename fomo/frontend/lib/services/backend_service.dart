import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/event.dart';
import '../data/user.dart';
import 'auth_service.dart';

class BackendService {
  BackendService({http.Client? client}) : _client = client ?? http.Client();

  static const _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );
  final http.Client _client;
  final AuthService _authService = AuthService();

  String get _baseUrl {
    if (_backendUrl.isNotEmpty) return _backendUrl;
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  Future<List<Event>> fetchEvents() async {
    final data = await _getJson('/events');
    final events = (data['events'] as List<dynamic>)
        .map((e) => Event.fromBackend(e as Map<String, dynamic>))
        .toList();
    return events;
  }

  Future<List<Event>> fetchMyRsvps() async {
    final data = await _getJson('/me/rsvps');
    return (data['events'] as List<dynamic>)
        .map((e) => Event.fromBackend(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> postEvent({
    required String id,
    required String title,
    required DateTime date,
    required String location,
    required String description,
  }) async {
    await _postJson('/events', {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'location': location,
      'description': description,
    });
  }

  Future<void> rsvp(String eventId) async {
    await _postJson('/events/$eventId/rsvp', null, expectBody: false);
  }

  Future<void> unrsvp(String eventId) async {
    await _delete('/events/$eventId/rsvp');
  }

  Future<({List<User> following, List<User> followers, List<User> suggested})> fetchFriends() async {
    final data = await _getJson('/friends');
    List<User> mapUsers(String key) {
      return (data[key] as List<dynamic>)
          .map((u) => u as Map<String, dynamic>)
          .map((u) => User.fromBackend(id: u['id'] as String, username: u['username'] as String))
          .toList();
    }

    return (
      following: mapUsers('following'),
      followers: mapUsers('followers'),
      suggested: mapUsers('suggested'),
    );
  }

  Future<void> follow(String userId) async {
    await _postJson('/friends/$userId/follow', null, expectBody: false);
  }

  Future<void> unfollow(String userId) async {
    await _delete('/friends/$userId/follow');
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final token = await _authService.getToken();
    if (token == null) throw const AuthException('Login required.');
    final response = await _client.get(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token),
    );
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic>? body, {
    bool expectBody = true,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw const AuthException('Login required.');
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token),
      body: body == null ? null : jsonEncode(body),
    );
    if (!expectBody) {
      _ensureSuccess(response);
      return const {};
    }
    return _decodeOrThrow(response);
  }

  Future<void> _delete(String path) async {
    final token = await _authService.getToken();
    if (token == null) throw const AuthException('Login required.');
    final response = await _client.delete(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token),
    );
    _ensureSuccess(response);
  }

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw AuthException(_readErrorMessage(response.body));
  }

  Map<String, dynamic> _decodeOrThrow(http.Response response) {
    _ensureSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _readErrorMessage(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail;
    } catch (_) {}
    return 'Request failed.';
  }
}
