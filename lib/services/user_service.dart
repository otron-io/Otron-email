import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isTestUser() async {
    User? user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    DocumentSnapshot userDoc = await _firestore.collection('test_users').doc(user.email).get();
    return userDoc.exists;
  }

  Future<String?> getCurrentUserEmail() async {
    return _auth.currentUser?.email;
  }
}