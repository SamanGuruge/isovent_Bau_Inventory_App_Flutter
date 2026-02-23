import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../services/auth_service.dart';
import '../shared/auth_shell.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pass1 = _newPassword.text;
    final pass2 = _confirmPassword.text;

    if (pass1.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (pass1 != pass2) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.email == widget.email) {
        await _authService.updatePassword(pass1);
      } else {
        await _authService.sendPasswordResetEmail(widget.email);
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.passwordSuccess,
        arguments: {
          'title': 'Success',
          'subtitle': 'Your password reset request has been processed.',
          'buttonText': 'Back to Sign In',
        },
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? e.code);
    } catch (_) {
      _showError('Unable to change password.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      rightIcon: Icons.key,
      rightTitle: 'Update your password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Reset password?',
            style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w700,
              color: Color(0xFF252C38),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter New Password & Confirm Password to get inside',
            style: AuthStyles.subHeading,
          ),
          const SizedBox(height: 24),
          const Text(
            'New Password *',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF282D36),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newPassword,
            obscureText: _obscure1,
            decoration: AuthStyles.input(
              hint: 'New password',
              suffix: IconButton(
                onPressed: () => setState(() => _obscure1 = !_obscure1),
                icon: Icon(
                  _obscure1
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Confirm Password *',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF282D36),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPassword,
            obscureText: _obscure2,
            decoration: AuthStyles.input(
              hint: 'Confirm password',
              suffix: IconButton(
                onPressed: () => setState(() => _obscure2 = !_obscure2),
                icon: Icon(
                  _obscure2
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
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
                : const Text('Change Password'),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (_) => false),
            child: const Text(
              'Return to Login',
              style: TextStyle(color: Color(0xFF6A717E), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
