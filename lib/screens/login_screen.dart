import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../app_routes.dart';
import '../services/auth_service.dart';
import '../theme/app_ui.dart';
import 'shared/auth_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_validateEmailPassword()) {
      return;
    }
    await _runAuthAction(
      () => _authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    await _runAuthAction(_authService.signInWithGoogle);
  }

  Future<void> _forgotPassword() async {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? e.code);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _showError('Google sign-in was canceled.');
      } else {
        _showError(e.description ?? 'Google sign-in failed.');
      }
    } catch (_) {
      _showError('Authentication failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateEmailPassword() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Email and password are required.');
      return false;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 980;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  Expanded(child: _buildAuthPanel(context, isDesktop: true)),
                  Expanded(child: _buildIllustrationPanel()),
                ],
              )
            : _buildAuthPanel(context, isDesktop: false),
      ),
    );
  }

  Widget _buildAuthPanel(BuildContext context, {required bool isDesktop}) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48 : 20,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const AuthBrandHeader(),
              SizedBox(height: isDesktop ? 100 : 42),
              const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2430),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Access the Isovent Bau Inventory using your email and password.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6A707C),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 26),
              const AuthFieldLabel('Email *'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: AuthStyles.input(
                  hint: 'name@company.com',
                  suffix: const Icon(Icons.mail_outline, size: 18),
                ),
              ),
              const SizedBox(height: 16),
              const AuthFieldLabel('Password *'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: AuthStyles.input(
                  hint: '••••••••',
                  suffix: IconButton(
                    splashRadius: 18,
                    iconSize: 18,
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    activeColor: const Color(0xFFF8A03D),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() => _rememberMe = value ?? false);
                          },
                    side: const BorderSide(color: Color(0xFFCFD3DC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Text(
                    'Remember Me',
                    style: TextStyle(color: Color(0xFF666B75), fontSize: 15),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isLoading ? null : _forgotPassword,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFFCA6D17),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: AuthStyles.primaryButton,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'New on our platform? ',
                    style: TextStyle(color: Color(0xFF7B808B), fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pushNamed(AppRoutes.register);
                          },
                    child: const Text(
                      'Create an account',
                      style: TextStyle(
                        color: Color(0xFF1F2430),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: const [
                  Expanded(child: Divider(color: Color(0xFFE2E5EA))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(color: Color(0xFF9096A3), fontSize: 16),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE2E5EA))),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      background: const Color(0xFF2561D8),
                      icon: const Icon(
                        Icons.facebook,
                        color: Colors.white,
                        size: 30,
                      ),
                      onTap: () => _showError('Facebook sign-in not enabled.'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SocialButton(
                      background: Colors.white,
                      border: const Color(0xFFD9DCE4),
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFFDB4437),
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: _isLoading ? null : _signInWithGoogle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SocialButton(
                      background: const Color(0xFF1D2D63),
                      icon: const Icon(
                        Icons.apple,
                        color: Colors.white,
                        size: 30,
                      ),
                      onTap: () => _showError('Apple sign-in not enabled.'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 96 : 40),
              const Text(
                'Copyrights © 2026 - FalconIT',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF707784), fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustrationPanel() {
    return Container(
      color: const Color(0xFFF9DEC2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 430,
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F2),
                    borderRadius: BorderRadius.circular(120),
                  ),
                ),
                const Icon(
                  Icons.phone_android_rounded,
                  size: 230,
                  color: Color(0xFF334B65),
                ),
                Positioned(
                  right: 115,
                  child: Container(
                    width: 118,
                    height: 168,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF8A03D),
                        width: 3,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_circle_outlined,
                          size: 54,
                          color: Color(0xFFF39A36),
                        ),
                        SizedBox(height: 10),
                        _MiniLine(),
                        SizedBox(height: 8),
                        _MiniLine(width: 56),
                        SizedBox(height: 8),
                        _MiniLine(width: 44),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  left: 76,
                  top: 6,
                  child: Icon(
                    Icons.settings,
                    size: 56,
                    color: Color(0xFFE0E3E8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 38),
            const Text(
              'Inventory access with secure authentication',
              style: TextStyle(
                color: Color(0xFF5C616C),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.background,
    required this.icon,
    required this.onTap,
    this.border,
  });

  final Color background;
  final Color? border;
  final Widget icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: background,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: border ?? Colors.transparent),
          ),
        ),
        child: icon,
      ),
    );
  }
}

class _MiniLine extends StatelessWidget {
  const _MiniLine({this.width = 64});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFF2A551),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
