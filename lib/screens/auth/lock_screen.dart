import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../shared/auth_shell.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String email;
  final String? displayName;
  final String? photoUrl;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      _showError('Password is required.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.signInWithEmailPassword(widget.email, password);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? e.code);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.displayName?.trim().isNotEmpty == true
        ? widget.displayName!
        : widget.email.split('@').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: Color(0xFF1E2C5E),
                  ),
                  const SizedBox(height: 24),
                  AuthCard(
                    children: [
                      const Text(
                        'Welcome back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          color: Color(0xFF6A717E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: const Color(0xFFD5D8E0),
                        backgroundImage: (widget.photoUrl?.isNotEmpty ?? false)
                            ? NetworkImage(widget.photoUrl!)
                            : null,
                        child: (widget.photoUrl?.isEmpty ?? true)
                            ? const Icon(
                                Icons.person,
                                size: 58,
                                color: Color(0xFF6A717E),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF252C38),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        decoration: AuthStyles.input(
                          hint: 'Enter your password',
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loading ? null : _unlock,
                        style: AuthStyles.primaryButton,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Text('Log In'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  const Text(
                    'Terms & Condition     Privacy     Help     English',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6A717E)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Copyrights © 2025 - DreamsPOS',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6A717E)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
