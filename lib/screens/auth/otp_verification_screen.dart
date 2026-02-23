import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/otp_service.dart';
import '../shared/auth_shell.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.flow,
    required this.email,
    required this.title,
    required this.buttonText,
    required this.rightIcon,
    this.name,
    this.password,
  });

  final String flow;
  final String email;
  final String title;
  final String buttonText;
  final IconData rightIcon;
  final String? name;
  final String? password;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpService = OtpService();
  final _authService = AuthService();
  final _controllers = List<TextEditingController>.generate(
    4,
    (_) => TextEditingController(),
  );
  final _focusNodes = List<FocusNode>.generate(4, (_) => FocusNode());

  Timer? _timer;
  int _seconds = 59;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 59;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_seconds == 0) {
        timer.cancel();
        return;
      }
      setState(() => _seconds--);
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otpCode.length != 4) {
      _showError('Enter the 4-digit code.');
      return;
    }
    setState(() => _loading = true);

    try {
      final ok = _otpService.verifyOtp(email: widget.email, code: _otpCode);
      if (!ok) {
        _showError('Invalid or expired OTP. Please try again.');
        return;
      }

      if (widget.flow == 'register') {
        final name = widget.name ?? '';
        final password = widget.password ?? '';
        final cred = await _authService.signUpWithEmailPassword(
          widget.email,
          password,
        );
        await cred.user?.updateDisplayName(name);
        await _authService.ensureUserDoc(cred.user);
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
        return;
      }

      if (widget.flow == 'forgot') {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.resetPassword,
          arguments: {'email': widget.email},
        );
        return;
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.passwordSuccess);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? e.code);
    } catch (_) {
      _showError('Failed to verify OTP.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resend() async {
    await _otpService.sendOtp(email: widget.email);
    _startTimer();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('A new OTP has been sent.')));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final masked = _otpService.maskEmail(widget.email);
    return AuthShell(
      rightIcon: widget.rightIcon,
      rightTitle: 'Secure verification',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Color(0xFF252C38),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Please enter the OTP received to confirm your account ownership. A code has been sent to $masked',
            style: AuthStyles.subHeading,
          ),
          const SizedBox(height: 26),
          Row(
            children: List<Widget>.generate(4, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 3 ? 0 : 12),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFD9DCE3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFD9DCE3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFF8A03D),
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && index < 3) {
                        _focusNodes[index + 1].requestFocus();
                      }
                    },
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Center(
            child: Chip(
              backgroundColor: const Color(0xFFFFECEB),
              label: Text(
                '00:${_seconds.toString().padLeft(2, '0')} s',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Didn\'t get the OTP? ',
                style: TextStyle(fontSize: 16, color: Color(0xFF6A717E)),
              ),
              GestureDetector(
                onTap: _resend,
                child: const Text(
                  'Resend OTP',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF252C38),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _loading ? null : _verify,
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
                : Text(widget.buttonText),
          ),
        ],
      ),
    );
  }
}
