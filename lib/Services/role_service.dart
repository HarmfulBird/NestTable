import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> isManager() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No user logged in');
        return false;
      }

      String email = currentUser.email ?? '';
      if (email.isEmpty) {
        print('User has no email');
        return false;
      }

      String username = email.replaceAll('@nesttable.co.nz', '');
      if (username.isEmpty) {
        print('Invalid username format');
        return false;
      }

      QuerySnapshot staffQuery = await _firestore
          .collection('Staff')
          .where('id', isEqualTo: username)
          .limit(1)
          .get();

      if (staffQuery.docs.isEmpty) {
        print('Staff record not found for user: $username');
        return false;
      }

      DocumentSnapshot staffDoc = staffQuery.docs.first;
      if (!staffDoc.exists) {
        print('Staff document exists in query but not in Firestore');
        return false;
      }

      Map<String, dynamic>? staffData = staffDoc.data() as Map<String, dynamic>?;
      if (staffData == null) {
        print('Staff document data is null');
        return false;
      }

      String role = staffData['role'] as String? ?? 'User';
      return role == 'Manager';
    } catch (e, stackTrace) {
      print('Error checking user role: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  static Future<String> getCurrentUserRole() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return 'Guest';

      String email = currentUser.email ?? '';
      if (email.isEmpty) return 'Guest';

      String username = email.replaceAll('@nesttable.co.nz', '');
      if (username.isEmpty) return 'Guest';

      QuerySnapshot staffQuery = await _firestore
          .collection('Staff')
          .where('id', isEqualTo: username)
          .limit(1)
          .get();

      if (staffQuery.docs.isEmpty) {
        return 'Guest';
      }

      DocumentSnapshot staffDoc = staffQuery.docs.first;
      if (!staffDoc.exists) return 'Guest';

      Map<String, dynamic>? staffData = staffDoc.data() as Map<String, dynamic>?;
      if (staffData == null) return 'Guest';

      return staffData['role'] as String? ?? 'User';
    } catch (e, stackTrace) {
      print('Error getting user role: $e');
      print('Stack trace: $stackTrace');
      return 'Guest';
    }
  }

  static bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  static String? getCurrentUsername() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    String email = currentUser.email ?? '';
    if (email.isEmpty) return null;

    return email.replaceAll('@nesttable.co.nz', '');
  }
}
