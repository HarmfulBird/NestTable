import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Service class for managing user roles and authentication-related operations.
// Handles role checking, user status verification, and staff data retrieval from Firestore.
class RoleService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Checks if the currently logged-in user is a manager
  static Future<bool> isManager() async {
    try {
      // Get the currently authenticated user
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No user logged in');
        return false;
      }

      // Extract email from the current user
      String email = currentUser.email ?? '';
      if (email.isEmpty) {
        print('User has no email');
        return false;
      }

      // Extract username by removing the company domain from email
      String username = email.replaceAll('@nesttable.co.nz', '');
      if (username.isEmpty) {
        print('Invalid username format');
        return false;
      }

      // Query Firestore to find the staff record matching the username
      QuerySnapshot staffQuery =
        await _firestore
          .collection('Staff')
          .where('id', isEqualTo: username)
          .limit(1)
          .get();

      // Check if any staff records were found
      if (staffQuery.docs.isEmpty) {
        print('Staff record not found for user: $username');
        return false;
      }

      // Get the first (and only) staff document from the query results
      DocumentSnapshot staffDoc = staffQuery.docs.first;
      if (!staffDoc.exists) {
        print('Staff document exists in query but not in Firestore');
        return false;
      }

      // Extract the staff data from the document
      Map<String, dynamic>? staffData = staffDoc.data() as Map<String, dynamic>?;
      if (staffData == null) {
        print('Staff document data is null');
        return false;
      }

      // Get the role from staff data and check if it's 'Manager'
      String role = staffData['role'] as String? ?? 'User';
      return role == 'Manager';
    } catch (e, stackTrace) {
      // Log any errors that occur during the role checking process
      print('Error checking user role: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Gets the role of the currently logged-in user (returns 'Guest' if not found)
  static Future<String> getCurrentUserRole() async {
    try {
      // Get the currently authenticated user
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return 'Guest';

      // Extract email from the current user
      String email = currentUser.email ?? '';
      if (email.isEmpty) return 'Guest';

      // Extract username by removing the company domain from email
      String username = email.replaceAll('@nesttable.co.nz', '');
      if (username.isEmpty) return 'Guest';

      // Query Firestore to find the staff record matching the username
      QuerySnapshot staffQuery =
        await _firestore
          .collection('Staff')
          .where('id', isEqualTo: username)
          .limit(1)
          .get();

      // Return 'Guest' if no staff records found
      if (staffQuery.docs.isEmpty) {
        return 'Guest';
      }

      // Get the first staff document from the query results
      DocumentSnapshot staffDoc = staffQuery.docs.first;
      if (!staffDoc.exists) return 'Guest';

      // Extract the staff data from the document
      Map<String, dynamic>? staffData = staffDoc.data() as Map<String, dynamic>?;
      if (staffData == null) return 'Guest';

      // Return the role from staff data, defaulting to 'User' if not specified
      return staffData['role'] as String? ?? 'User';
    } catch (e, stackTrace) {
      // Log any errors and return 'Guest' as a safe default
      print('Error getting user role: $e');
      print('Stack trace: $stackTrace');
      return 'Guest';
    }
  }

  // Checks if there is a user currently logged in
  static bool isLoggedIn() {
    // Simple check to see if Firebase Auth has a current user
    return _auth.currentUser != null;
  }

  // Gets the username of the currently logged-in user (extracts from email)
  static String? getCurrentUsername() {
    // Get the currently authenticated user
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    // Extract email from the current user
    String email = currentUser.email ?? '';
    if (email.isEmpty) return null;

    // Extract and return username by removing the company domain from email
    return email.replaceAll('@nesttable.co.nz', '');
  }
}
