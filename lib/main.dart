import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'firebase_options.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/lock_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/password_success_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/errors/error_pages.dart';
import 'screens/home_screen.dart';
import 'screens/inventory/inventory_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/inventory_repository.dart';

IconData _otpIconFromArgs(Map<String, dynamic> args) {
  final variant = (args['iconVariant'] as String?) ?? '';
  switch (variant) {
    case 'email':
      return Icons.email_outlined;
    case 'mail-read':
      return Icons.mark_email_read_outlined;
    case 'two-step':
      return Icons.verified_user_outlined;
    default:
      return Icons.verified_user_outlined;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint(
    '[Firebase] initialized projectId=${Firebase.app().options.projectId}',
  );
  runApp(const IsoventInventoryApp());
}

class IsoventInventoryApp extends StatelessWidget {
  const IsoventInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isovent Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.forgotPasswordCentered: (_) =>
            const ForgotPasswordCenteredScreen(),
        AppRoutes.error404: (_) => const Error404Screen(),
        AppRoutes.error500: (_) => const Error500Screen(),
        '/inventory': (_) => const InventoryDashboardScreen(),
        '/home': (_) => const HomeScreen(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        switch (settings.name) {
          case AppRoutes.emailOtp:
          case AppRoutes.twoStepOtp:
            if (args is Map<String, dynamic>) {
              return MaterialPageRoute(
                builder: (_) => OtpVerificationScreen(
                  flow: (args['flow'] ?? 'generic') as String,
                  email: (args['email'] ?? 'demo@example.com') as String,
                  title: (args['title'] ?? 'Email OTP Verification') as String,
                  buttonText: (args['buttonText'] ?? 'Submit') as String,
                  rightIcon: _otpIconFromArgs(args),
                  name: args['name'] as String?,
                  password: args['password'] as String?,
                ),
              );
            }
            return MaterialPageRoute(builder: (_) => const Error404Screen());
          case AppRoutes.resetPassword:
            final email = args is Map<String, dynamic>
                ? (args['email'] as String? ?? '')
                : '';
            return MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: email),
            );
          case AppRoutes.passwordSuccess:
            if (args is Map<String, dynamic>) {
              return MaterialPageRoute(
                builder: (_) => PasswordSuccessScreen(
                  title: (args['title'] as String?) ?? 'Success',
                  subtitle:
                      (args['subtitle'] as String?) ??
                      'Your new password has been successfully saved',
                  buttonText:
                      (args['buttonText'] as String?) ?? 'Back to Sign In',
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => const PasswordSuccessScreen(),
            );
          case AppRoutes.lock:
            if (args is Map<String, dynamic>) {
              return MaterialPageRoute(
                builder: (_) => LockScreen(
                  email: (args['email'] as String? ?? 'demo@example.com'),
                  displayName: args['displayName'] as String?,
                  photoUrl: args['photoUrl'] as String?,
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => const LockScreen(email: 'demo@example.com'),
            );
        }
        return MaterialPageRoute(builder: (_) => const Error404Screen());
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _repo = InventoryRepository();
  String? _seededUid;
  bool _seeding = false;
  bool _seedDoneForThisSession = false;
  bool _seedScheduleQueued = false;

  void _resetSeedFlags() {
    _seededUid = null;
    _seeding = false;
    _seedDoneForThisSession = false;
    _seedScheduleQueued = false;
  }

  void _scheduleSeed(User user) {
    final alreadySeeded = _seedDoneForThisSession && _seededUid == user.uid;
    if (_seedScheduleQueued || _seeding || alreadySeeded) {
      return;
    }
    _seedScheduleQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _seedScheduleQueued = false;
      _seedForUser(user);
    });
  }

  Future<void> _seedForUser(User user) async {
    final alreadySeeded = _seedDoneForThisSession && _seededUid == user.uid;
    if (_seeding || alreadySeeded) {
      return;
    }
    if (mounted) {
      setState(() => _seeding = true);
    }
    try {
      await _repo.ensureSeedData();
      if (mounted) {
        setState(() {
          _seededUid = user.uid;
          _seedDoneForThisSession = true;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        final details = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Access denied while initializing inventory. Please check Firestore rules and sign in again.\n$details',
            ),
          ),
        );
        await FirebaseAuth.instance.signOut();
      });
      debugPrint('[Seed] initialization error: $e');
      if (mounted) {
        setState(() {
          _seededUid = user.uid;
          _seedDoneForThisSession = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _seeding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final User? user = snapshot.data ?? FirebaseAuth.instance.currentUser;
        if (user == null) {
          _resetSeedFlags();
          return const LoginScreen();
        }

        _scheduleSeed(user);
        if (_seeding && !_seedDoneForThisSession) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const HomeScreen();
      },
    );
  }
}
