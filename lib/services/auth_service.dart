import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  static bool _googleInitialized = false;

  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await ensureUserDoc(credential.user);
    return credential;
  }

  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await ensureUserDoc(credential.user);
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final credential = await _auth.signInWithPopup(provider);
      await ensureUserDoc(credential.user);
      return credential;
    }

    await _initializeGoogleSignIn();
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
    final idToken = googleUser.authentication.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google Sign-In did not return an ID token.',
      );
    }

    final googleCredential = GoogleAuthProvider.credential(idToken: idToken);
    final credential = await _auth.signInWithCredential(googleCredential);
    await ensureUserDoc(credential.user);
    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _initializeGoogleSignIn();
      await _googleSignIn.signOut();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed in user found to update password.',
      );
    }
    await user.updatePassword(newPassword);
  }

  Future<void> ensureUserDoc(User? user) async {
    if (user == null) {
      return;
    }

    final userRef = _firestore.collection('users').doc(user.uid);
    final userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      return;
    }

    final provider = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : '';

    await userRef.set({
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'provider': provider,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) {
      return;
    }
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }
}
