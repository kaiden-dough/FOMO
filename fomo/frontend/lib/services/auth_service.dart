import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  static const _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
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
    final token = await getToken();
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
    await GoogleSignIn().signOut();
  }

  Future<Account> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: const ['email'],
      clientId: kIsWeb && _googleWebClientId.isNotEmpty ? _googleWebClientId : null,
    );
    if (kIsWeb && _googleWebClientId.isEmpty) {
      throw const AuthException(
        'Missing GOOGLE_WEB_CLIENT_ID. Run Flutter with --dart-define=GOOGLE_WEB_CLIENT_ID=...',
      );
    }

    GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();
    try {
      googleUser ??= await googleSignIn.signIn();
    } catch (e) {
      final message = e.toString();
      if (message.contains('popup_closed')) {
        throw const AuthException(
          'Google popup was closed or blocked. Allow popups and try again.',
        );
      }
      throw AuthException('Google sign-in error: $message');
    }
    if (googleUser == null) {
      throw const AuthException('Google sign-in cancelled.');
    }
    final auth = await googleUser.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;
    if ((idToken == null || idToken.isEmpty) &&
        (accessToken == null || accessToken.isEmpty)) {
      throw const AuthException(
        'Google token not returned. Try again and keep the popup open.',
      );
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_token': idToken,
        'access_token': accessToken,
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

  Future<String?> getToken() async {
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
