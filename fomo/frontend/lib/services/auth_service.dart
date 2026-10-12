import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
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

  const Account({required this.id, required this.username, this.createdAt});
}

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'auth_username';
  static const _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const _mobileRedirect = String.fromEnvironment('AUTH_REDIRECT_URL');
  static const _linkPendingKey = 'auth_google_link_pending';
  static const _oauthPendingKey = 'auth_google_pending';
  static bool get googleConfigured =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  static Future<bool> hasPendingGoogleSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_oauthPendingKey) ?? false;
  }

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

  Future<Map<String, dynamic>> getAuthConfig() async {
    final response = await _client.get(Uri.parse('$_baseUrl/auth/config'));
    if (response.statusCode != 200) {
      throw const AuthException(
        'Could not load sign-in options. Please try again.',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: _authHeaders(token),
      );
      if (response.statusCode != 204 && response.statusCode != 401) {
        throw const AuthException('Could not sign out. Please try again.');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_linkPendingKey);
    await prefs.remove(_oauthPendingKey);
    if (googleConfigured) {
      await sb.Supabase.instance.client.auth.signOut(
        scope: sb.SignOutScope.local,
      );
    }
  }

  Future<void> signInWithGoogle({bool linkAccount = false}) async {
    if (!googleConfigured) {
      throw const AuthException('Google sign-in is not available yet.');
    }
    if (!kIsWeb && _mobileRedirect.isEmpty) {
      throw const AuthException(
        'Google sign-in is not configured for this device yet.',
      );
    }
    await sb.Supabase.instance.client.auth.signOut(
      scope: sb.SignOutScope.local,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_linkPendingKey, linkAccount);
    await prefs.setBool(_oauthPendingKey, true);
    try {
      final started = await sb.Supabase.instance.client.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        queryParams: const {'prompt': 'select_account'},
        redirectTo: kIsWeb
            ? '${Uri.base.origin}/'
            : _mobileRedirect,
      );
      if (!started) throw const AuthException('Could not open Google sign-in.');
    } catch (_) {
      await prefs.remove(_oauthPendingKey);
      await prefs.remove(_linkPendingKey);
      rethrow;
    }
  }

  Future<Account?> completeGoogleSignIn() async {
    if (!googleConfigured) return null;
    final session = sb.Supabase.instance.client.auth.currentSession;
    final prefs = await SharedPreferences.getInstance();
    if (session == null || prefs.getBool(_oauthPendingKey) != true) return null;
    final link = prefs.getBool(_linkPendingKey) ?? false;
    final token = await getToken();
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/supabase'),
      headers: link && token != null
          ? _authHeaders(token)
          : {'Content-Type': 'application/json'},
      body: jsonEncode({
        'access_token': session.accessToken,
        'link_account': link,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_readErrorMessage(response.body));
    }
    await prefs.remove(_linkPendingKey);
    await prefs.remove(_oauthPendingKey);
    return _saveAccount(response.body);
  }

  Future<Account> _saveAccount(String body) async {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, data['token'] as String);
    await prefs.setString(_usernameKey, data['username'] as String);
    return Account(
      id: data['user_id'] as String,
      username: data['username'] as String,
    );
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
      body: jsonEncode({'username': username.trim(), 'password': password}),
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
