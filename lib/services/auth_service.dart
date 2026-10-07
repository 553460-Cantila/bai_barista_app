import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _google = GoogleSignIn();

  Future<String> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    return _roleFor(cred.user!.uid);
  }

  /// New accounts always start as 'customer'. Staff accounts (including the
  /// embedded BAI@google.com one) are created directly in the Firebase
  /// console, not through this method.
  Future<String> register(String firstName, String lastName, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final fullName = '$firstName $lastName'.trim();
    await _db.collection('users').doc(cred.user!.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'name': fullName, // kept so the rest of the app can keep reading `name`
      'email': email,
      'role': 'customer',
    });
    await cred.user!.updateDisplayName(fullName);
    return 'customer';
  }

  Future<String> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) throw Exception('Google sign-in was cancelled.');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);

    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) {
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': cred.user!.displayName ?? '',
        'email': cred.user!.email ?? '',
        'role': 'customer',
      });
      return 'customer';
    }
    return doc.data()?['role'] ?? 'customer';
  }

  Future<String> _roleFor(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return 'customer';
    return doc.data()?['role'] ?? 'customer';
  }

  /// True if this account can change its password here (i.e. it signed up
  /// with email/password, not Google-only).
  bool get canChangePassword {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  /// Re-authenticates with the current password, then sets the new one.
  /// Works for customers and staff alike — the embedded BAI@google.com
  /// staff login is a normal email/password account, so this applies to it too.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No signed-in user.');
    }
    if (!canChangePassword) {
      throw Exception('This account signed in with Google — change the password in your Google Account instead.');
    }
    final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  // ---- Profile ----

  User? get currentUser => _auth.currentUser;

  /// Live view of the signed-in user's `users/{uid}` document.
  Stream<Map<String, dynamic>?> profileStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots().map((d) => d.data());
  }

  /// Updates the editable profile fields. Email is intentionally not editable
  /// here because it is the Firebase Auth login identity.
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No signed-in user.');
    final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    await _db.collection('users').doc(user.uid).set({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'name': fullName,
    }, SetOptions(merge: true));
    await user.updateDisplayName(fullName);
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }
}