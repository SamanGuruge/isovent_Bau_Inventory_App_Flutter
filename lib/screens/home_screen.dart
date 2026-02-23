import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Isovent Inventory')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Home', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text('Signed in as: ${user?.email ?? 'Unknown user'}'),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/inventory'),
                  child: const Text('Open Inventory'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.register),
                  child: const Text('Register'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
                  child: const Text('Forgot Password'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.forgotPasswordCentered),
                  child: const Text('Forgot Centered'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.twoStepOtp,
                    arguments: {
                      'flow': 'generic',
                      'email': user?.email ?? 'demo@example.com',
                      'title': '2 Step Verification',
                      'buttonText': 'Submit',
                      'iconVariant': 'two-step',
                    },
                  ),
                  child: const Text('2-Step OTP'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.lock,
                    arguments: {
                      'email': user?.email ?? 'demo@example.com',
                      'displayName': user?.displayName,
                      'photoUrl': user?.photoURL,
                    },
                  ),
                  child: const Text('Lock Screen'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.resetPassword,
                    arguments: {'email': user?.email ?? 'demo@example.com'},
                  ),
                  child: const Text('Reset Password'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.passwordSuccess),
                  child: const Text('Success Page'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.error404),
                  child: const Text('Error 404'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.error500),
                  child: const Text('Error 500'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await AuthService().signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
