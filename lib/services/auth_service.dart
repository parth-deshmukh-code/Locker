import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User?   get currentUser     => _auth.currentUser;
  String? get uid             => _auth.currentUser?.uid;
  Stream<User?> get authState => _auth.authStateChanges();

  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e.code);
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e.code);
    }
  }

  Future<void> logout() => _auth.signOut();

  String _msg(String code) {
    switch (code) {
      case 'user-not-found':        return 'No account found with this email';
      case 'wrong-password':        return 'Incorrect password';
      case 'email-already-in-use':  return 'Email already registered';
      case 'weak-password':         return 'Password must be at least 6 characters';
      case 'invalid-email':         return 'Invalid email address';
      default:                      return 'Error: $code';
    }
  }
}
