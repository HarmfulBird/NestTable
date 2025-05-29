import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_service.dart';

// Service class for managing user preferences stored in Firestore
// Handles loading and saving user-specific settings like default view
class UserPreferenceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gets the current user's default view preference from Firestore
  // Returns 'Tables' as default if no preference is set or user not found
  static Future<String> getDefaultView() async {
    try {
      // Get current user's username
      String? username = RoleService.getCurrentUsername();
      if (username == null) return 'Tables';

      // Query staff collection for user's document
      QuerySnapshot staffQuery =
        await _firestore
          .collection('Staff')
          .where('id', isEqualTo: username)
          .limit(1)
          .get();

      if (staffQuery.docs.isNotEmpty) {
        Map<String, dynamic> data = staffQuery.docs.first.data() as Map<String, dynamic>;
        return data['defaultView'] ?? 'Tables';
      }

      return 'Tables'; // Default if user not found
    } catch (e) {
      print('Error getting default view: $e');
      return 'Tables'; // Default on error
    }
  }

  // Saves the user's default view preference to Firestore
  // Returns true if successful, false otherwise
  static Future<bool> setDefaultView(String defaultView) async {
    try {
      // Get current user's username
      String? username = RoleService.getCurrentUsername();
      if (username == null) return false;

      // Query staff collection for user's document
      QuerySnapshot staffQuery =
        await _firestore
          .collection('Staff')
          .where('id', isEqualTo: username)
          .limit(1)
          .get();

      if (staffQuery.docs.isNotEmpty) {
        // Update existing document with new default view
        await staffQuery.docs.first.reference.update({
          'defaultView': defaultView,
        });
        return true;
      }

      return false; // User not found
    } catch (e) {
      print('Error setting default view: $e');
      return false;
    }
  }

  // Gets the page index for navigation based on the default view string
  // Maps string values to their corresponding navigation indices
  static int getDefaultViewIndex(String defaultView) {
    switch (defaultView) {
      case 'Tables':
        return 0;
      case 'Reservations':
        return 1;
      case 'Orders':
        return 2;
      default:
        return 0; // Default to Tables
    }
  }

  // Gets the default view string from navigation index
  // Maps navigation indices back to their string representations
  static String getDefaultViewFromIndex(int index) {
    switch (index) {
      case 0:
        return 'Tables';
      case 1:
        return 'Reservations';
      case 2:
        return 'Orders';
      default:
        return 'Tables';
    }
  }
}
