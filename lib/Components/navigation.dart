import 'package:flutter/material.dart';
import '../custom_icons_icons.dart';
import '../Pages/login_page.dart';
import '../Services/role_service.dart';

// Main navigation sidebar widget that provides menu navigation for the application
class NavigationSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onIconTapped;

  const NavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onIconTapped,
  });

  @override
  State<NavigationSidebar> createState() => _NavigationSidebarState();
}

// State class that manages the navigation sidebar's dynamic behavior
class _NavigationSidebarState extends State<NavigationSidebar> {
  bool _isManager = false;

  // Initialize the widget and check user role when created
  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  // Check if the current user is a manager and update the state
  Future<void> _checkUserRole() async {
    bool isManager = await RoleService.isManager();
    // Only update state if widget is still mounted to prevent memory leaks
    if (mounted) {
      setState(() {
        _isManager = isManager;
      });
    }
  }

  // Build the navigation sidebar widget with all menu items
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80, // Fixed width for consistent sidebar size
      color: Color(int.parse("0xFFE0ACD5")), // Light purple background color
      child: Column(
        children: [
          SizedBox(height: 20), // Top spacing
          // Logo icon that triggers logout dialog when tapped
          InkWell(
            onTap: () {
              // Show confirmation dialog before logout
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: const Color(
                      0xFF2F3031,
                    ), // Dark background for dialog
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(color: Colors.white),
                    ),
                    actions: [
                      // Cancel button - just closes the dialog
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      // Logout button - closes dialog and navigates to login page
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Logout',
                          style: TextStyle(color: Colors.red.shade400),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            child: Icon(
              CustomIcons.logo,
              color: Colors.black,
              size: 50,
            ), // App logo
          ),
          SizedBox(height: 40), // Spacing between logo and navigation items
          // Navigation menu items with corresponding icons and labels
          _buildIconButton(0, CustomIcons.th_large_outline, "Tables", false),
          SizedBox(height: 1),
          _buildIconButton(1, CustomIcons.reservations, "Reservations", true),
          SizedBox(height: 1),
          _buildIconButton(2, CustomIcons.order, "Orders", true),
          SizedBox(height: 1),
          _buildIconButton(3, CustomIcons.group, "Servers", true),
          Spacer(), // Push bottom items to the bottom
          _buildIconButton(4, CustomIcons.management, "Management", true),
          SizedBox(height: 10),
          _buildIconButton(5, CustomIcons.settings, "Settings", true),
          SizedBox(height: 20), // Bottom spacing
        ],
      ),
    );
  }

  // Create a navigation button with icon, label, and selection state
  Widget _buildIconButton(
    int index,
    IconData icon,
    String label,
    bool addThickness,
  ) {
    // Determine the visual state of the button
    final bool isSelected = widget.selectedIndex == index;
    final bool isManagementButton = index == 4;
    final bool isRestricted = isManagementButton && !_isManager;

    return GestureDetector(
      onTap: () => widget.onIconTapped(index), // Handle navigation tap
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Highlight selected button with dark background
          color: isSelected ? Color(0xFF212224) : Colors.transparent,
        ),
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(addThickness ? 4.0 : 0.0),
                  child: _iconLayer(icon, isSelected, 50, isRestricted),
                ),
                // Show lock icon for restricted management access
                if (isRestricted)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.lock, color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4), // Spacing between icon and label
            Text(
              label,
              style: TextStyle(
                // Dynamic color based on selection and restriction status
                color:
                    isSelected
                        ? Colors.white // White for selected items
                        : isRestricted
                        ? Colors.grey // Grey for restricted items
                        : Colors.black, // Black for normal items
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Create an icon with appropriate color based on selection and restriction status
  Widget _iconLayer(
    IconData icon,
    bool isSelected,
    double size,
    bool isRestricted,
  ) {
    return Icon(
      icon, // Apply color based on the button's state
      color:
          isSelected
              ? Colors.white // White for selected state
              : isRestricted
              ? Colors.grey // Grey for restricted access
              : Colors.black, // Black for normal state
      size: size,
    );
  }
}
