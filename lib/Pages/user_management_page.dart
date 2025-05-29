import 'package:flutter/material.dart';
import 'DataUploaders/Uploaders/staff_data_crud.dart';
import '../Components/navigation.dart';
import '../main.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212224),
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // Top bar section
          Row(
            children: [
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: const Row(children: [SizedBox(height: 25)]),
                ),
              ),
            ],
          ),
          // Main content with navigation and user management
          Expanded(
            child: Row(
              children: [
                // Left sidebar navigation
                NavigationSidebar(
                  selectedIndex: 5, // Settings page index
                  onIconTapped: (index) {
                    if (index != 5) {
                      // Navigate to the selected page
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                      );
                    } else {
                      // If settings is selected, go back to settings
                      Navigator.pop(context);
                    }
                  },
                ),
                // Main content area
                Expanded(
                  child: Column(
                    children: [
                      // Header section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        color: const Color(0xFF2F3031),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'User Management',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Staff data uploader content
                      const Expanded(child: StaffDataUploader()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
