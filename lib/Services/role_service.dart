import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if the current user has Manager role
  static Future<bool> isManager() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Extract username from email (remove @nesttable.co.nz)
      String email = currentUser.email ?? '';
      String username = email.replaceAll('@nesttable.co.nz', '');

      // Check if user exists in Staff collection with Manager role
      QuerySnapshot staffQuery =
          await _firestore
              .collection('Staff')
              .where('id', isEqualTo: username)
              .limit(1)
              .get();

      if (staffQuery.docs.isEmpty) {
        return false; // User not found in Staff collection
      }

      DocumentSnapshot staffDoc = staffQuery.docs.first;
      Map<String, dynamic> staffData = staffDoc.data() as Map<String, dynamic>;

      String role = staffData['role'] ?? 'User';
      return role == 'Manager';
    } catch (e) {
      print('Error checking user role: $e');
      return false;
    }
  }

  /// Get the current user's role
  static Future<String> getCurrentUserRole() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return 'Guest';

      // Extract username from email (remove @nesttable.co.nz)
      String email = currentUser.email ?? '';
      String username = email.replaceAll('@nesttable.co.nz', '');

      // Check if user exists in Staff collection
      QuerySnapshot staffQuery =
          await _firestore
              .collection('Staff')
              .where('id', isEqualTo: username)
              .limit(1)
              .get();

      if (staffQuery.docs.isEmpty) {
        return 'Guest'; // User not found in Staff collection
      }

      DocumentSnapshot staffDoc = staffQuery.docs.first;
      Map<String, dynamic> staffData = staffDoc.data() as Map<String, dynamic>;

      return staffData['role'] ?? 'User';
    } catch (e) {
      print('Error getting user role: $e');
      return 'Guest';
    }
  }

  /// Check if the current user is authenticated
  static bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Get current user's username
  static String? getCurrentUsername() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    String email = currentUser.email ?? '';
    return email.replaceAll('@nesttable.co.nz', '');
  }
}
