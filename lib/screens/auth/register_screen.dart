import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../services/otp_service.dart';
import '../shared/auth_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otpService = OtpService();

  bool _loading = false;
  bool _agree = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError('All fields are required.');
      return;
    }
    if (!_agree) {
      _showError('Please accept Terms & Privacy to continue.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _otpService.sendOtp(email: email);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(
        AppRoutes.emailOtp,
        arguments: {
          'flow': 'register',
          'name': name,
          'email': email,
          'password': password,
          'title': 'Email OTP Verification',
          'buttonText': 'Verify & Proceed',
          'iconVariant': 'email',
        },
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? e.code);
    } catch (_) {
      _showError('Failed to start registration.');
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
      rightIcon: Icons.how_to_reg,
      rightTitle: 'Create a new Isovent Bau Inventory account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Register',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF252C38),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create New Isovent Bau Inventory Account',
            style: AuthStyles.subHeading,
          ),
          const SizedBox(height: 14),
          const Text(
            'Name *',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF282D36),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: AuthStyles.input(
              hint: 'Full name',
              suffix: const Icon(Icons.person_outline, size: 18),
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          const Text(
            'Password *',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF282D36),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: AuthStyles.input(
              hint: 'Enter password',
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
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
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF282D36),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            decoration: AuthStyles.input(
              hint: 'Confirm password',
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Checkbox(
                value: _agree,
                onChanged: (value) => setState(() => _agree = value ?? false),
                activeColor: const Color(0xFFF8A03D),
              ),
              const Text(
                'I agree to the ',
                style: TextStyle(fontSize: 16, color: Color(0xFF6A717E)),
              ),
              const Text(
                'Terms & Privacy',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFCA6D17),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loading ? null : _register,
            style: AuthStyles.primaryButton,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : const Text('Sign Up'),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already on our platform? ',
                style: TextStyle(color: Color(0xFF7B808B), fontSize: 16),
              ),
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text(
                  'Sign In Instead',
                  style: TextStyle(
                    color: Color(0xFF1F2430),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
