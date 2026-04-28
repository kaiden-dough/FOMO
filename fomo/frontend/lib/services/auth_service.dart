import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class Account {
  final String id;
  final String username;
  final DateTime? createdAt;

  const Account({
    required this.id,
    required this.username,
    this.createdAt,
  });
}

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'auth_username';
  static const _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );

  final http.Client _client;

  String get _baseUrl {
    if (_backendUrl.isNotEmpty) {
      return _backendUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  Future<Account?> getCurrentAccount() async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await _client.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 401) {
      await logout();
      return null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_readErrorMessage(response.body));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Account(
      id: data['id'] as String,
      username: data['username'] as String,
      createdAt: DateTime.tryParse((data['created_at'] ?? '') as String),
    );
  }

  Future<Account> register({
    required String username,
    required String password,
  }) async {
    return _authenticate('/auth/register', username, password);
  }

  Future<Account> login({
    required String username,
    required String password,
  }) async {
    return _authenticate('/auth/login', username, password);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Account> _authenticate(
    String endpoint,
    String username,
    String password,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'password': password,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_readErrorMessage(response.body));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    final savedUsername = data['username'] as String;
    final id = data['user_id'] as String;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, savedUsername);

    return Account(id: id, username: savedUsername);
  }

  Map<String, String> _authHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  String _readErrorMessage(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
    } catch (_) {
      // Fall through to generic error.
    }
    return 'Request failed. Please try again.';
  }
}
