import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/otp_service.dart';
import '../shared/auth_shell.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  final _otpService = OtpService();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Email is required.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.sendPasswordResetEmail(email);
      await _otpService.sendOtp(email: email);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(
        AppRoutes.emailOtp,
        arguments: {
          'flow': 'forgot',
          'email': email,
          'title': 'Email OTP Verification',
          'buttonText': 'Verify & Proceed',
          'iconVariant': 'mail-read',
        },
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? e.code);
    } catch (_) {
      _showError('Unable to process password reset.');
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
      rightIcon: Icons.key_outlined,
      rightTitle: 'Password recovery',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Forgot password?',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Color(0xFF252C38),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'If you forgot your password, well, then we\'ll email you instructions to reset your password.',
            style: AuthStyles.subHeading,
          ),
          const SizedBox(height: 24),
          const Text(
            'Email Address *',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF282D36),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: AuthStyles.input(
              hint: 'name@company.com',
              suffix: const Icon(Icons.mail_outline, size: 18),
            ),
          ),
          const SizedBox(height: 20),
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
                : const Text('Submit'),
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

class ForgotPasswordCenteredScreen extends StatefulWidget {
  const ForgotPasswordCenteredScreen({super.key});

  @override
  State<ForgotPasswordCenteredScreen> createState() =>
      _ForgotPasswordCenteredScreenState();
}

class _ForgotPasswordCenteredScreenState
    extends State<ForgotPasswordCenteredScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Email is required.');
      return;
    }
    setState(() => _loading = true);
    try {
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(
        AppRoutes.passwordSuccess,
        arguments: {
          'title': 'Reset Link Sent',
          'subtitle': 'Password reset instructions were sent to your email.',
          'buttonText': 'Back to Sign In',
        },
      );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      body: Stack(
        children: [
          Positioned(
            left: -40,
            bottom: 360,
            child: Transform.rotate(
              angle: -0.15,
              child: Container(
                width: 360,
                height: 48,
                color: const Color(0xFFF8A03D),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(height: 290, color: const Color(0xFFF8EFE5)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 48,
                        color: Color(0xFF1E2C5E),
                      ),
                      const SizedBox(height: 24),
                      AuthCard(
                        children: [
                          const Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF252C38),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'If you forgot your password, well, then we\'ll email you instructions to reset your password.',
                            style: AuthStyles.subHeading,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Email Address *',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF282D36),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: AuthStyles.input(
                              hint: 'name@company.com',
                              suffix: const Icon(Icons.mail_outline, size: 18),
                            ),
                          ),
                          const SizedBox(height: 20),
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
                                : const Text('Submit'),
                          ),
                          const SizedBox(height: 18),
                          TextButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushNamedAndRemoveUntil('/', (_) => false),
                            child: const Text(
                              'Return to Login',
                              style: TextStyle(
                                color: Color(0xFF6A717E),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 54),
                      const Text(
                        'Copyrights © 2025 - DreamsPOS',
                        style: TextStyle(
                          color: Color(0xFF707784),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
