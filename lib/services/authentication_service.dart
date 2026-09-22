import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'account_cloud_service.dart';

class AuthenticationService {
  AuthenticationService._();

  static final AuthenticationService instance = AuthenticationService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn.instance;
  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User> signInWithGoogle() async {
    if (!_googleInitialized) {
      await _google.initialize();
      _googleInitialized = true;
    }

    final account = await _google.authenticate();
    final authentication = account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: authentication.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      throw StateError('Não foi possível acessar sua conta Google.');
    }
    await AccountCloudService().ensureProfile();
    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleInitialized) await _google.signOut();
  }
}
