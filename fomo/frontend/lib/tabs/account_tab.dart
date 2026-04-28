import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AccountTab extends StatefulWidget {
  final VoidCallback? onAuthChanged;

  const AccountTab({super.key, this.onAuthChanged});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoginMode = true;
  bool _loading = false;
  String? _error;
  Account? _account;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    setState(() => _loading = true);
    try {
      final account = await _authService.getCurrentAccount();
      if (!mounted) return;
      setState(() {
        _account = account;
        _error = null;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not connect to backend.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final account = _isLoginMode
          ? await _authService.login(
              username: _usernameController.text,
              password: _passwordController.text,
            )
          : await _authService.register(
              username: _usernameController.text,
              password: _passwordController.text,
            );

      if (!mounted) return;
      setState(() {
        _account = account;
        _passwordController.clear();
      });
      widget.onAuthChanged?.call();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not connect to backend.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _loading = true);
    await _authService.logout();
    if (!mounted) return;
    setState(() {
      _account = null;
      _passwordController.clear();
      _loading = false;
    });
    widget.onAuthChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _account == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_account != null) {
      return _buildAccountCard();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              _isLoginMode ? 'Login' : 'Create Account',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Username must be at least 3 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.length < 8) {
                  return 'Password must be at least 8 characters.';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_isLoginMode ? 'Login' : 'Create Account'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      try {
                        final account = await _authService.signInWithGoogle();
                        if (!mounted) return;
                        setState(() => _account = account);
                        widget.onAuthChanged?.call();
                      } on AuthException catch (e) {
                        if (!mounted) return;
                        setState(() => _error = e.message);
                      } catch (_) {
                        if (!mounted) return;
                        setState(() => _error = 'Google sign-in failed.');
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              icon: const Icon(Icons.login),
              label: const Text('Sign up / Login with Google'),
            ),
            TextButton(
              onPressed: _loading
                  ? null
                  : () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                        _error = null;
                      });
                    },
              child: Text(
                _isLoginMode
                    ? 'Need an account? Sign up'
                    : 'Already have an account? Login',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    final account = _account!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Account',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white10,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Username: ${account.username}'),
                  const SizedBox(height: 8),
                  Text('User ID: ${account.id}'),
                  if (account.createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text('Joined: ${account.createdAt!.toLocal()}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loading ? null : _logout,
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}