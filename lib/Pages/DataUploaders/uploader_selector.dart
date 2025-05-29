import 'package:flutter/material.dart';
import 'Uploaders/table_data_crud.dart';
import 'Uploaders/staff_data_crud.dart';
import 'Uploaders/reservation_data_crud.dart';
import 'Uploaders/item_data_crud.dart';
import 'Uploaders/change_dates.dart';
import '../../Services/role_service.dart';
import '../../Components/navigation.dart';

// Main widget that provides a selector interface for different data management pages
// Only accessible to users with manager role permissions
class PageSelector extends StatefulWidget {
  const PageSelector({super.key});

  @override
  PageSelectorState createState() => PageSelectorState();
}

class PageSelectorState extends State<PageSelector> {
  String? selectedPage;
  bool _isManager = false;
  bool _isLoading = true;
  final int _selectedNavIndex = 4;
  int _refreshKey = 0;

  // Maps page names to their corresponding widget constructors
  // Each widget gets a unique key based on the refresh counter for proper rebuilding
  Map<String, Widget Function()> get pageConstructors => {
    'Table Data': () => TableDataUploader(key: ValueKey('table_$_refreshKey')),
    'Staff Data': () => StaffDataUploader(key: ValueKey('staff_$_refreshKey')),
    'Reservation Data': () =>ReservationDataUploader(key: ValueKey('reservation_$_refreshKey')),
    'Item Data': () => ItemDataUploader(key: ValueKey('item_$_refreshKey')),
    'Change Dates': () => ChangeDatesUploader(key: ValueKey('dates_$_refreshKey')),
  };

  @override
  // Initializes the widget state and checks user role permissions
  void initState() {
    super.initState();
    _checkRole();
  }

  // Checks if the current user has manager role and updates the UI accordingly
  Future<void> _checkRole() async {
    try {
      bool isManager = await RoleService.isManager();
      // Only update state if the widget is still mounted to prevent memory leaks
      if (mounted) {
        setState(() {
          _isManager = isManager;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle role check errors gracefully and show user feedback
      if (mounted) {
        setState(() {
          _isManager = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Refreshes the currently selected page by incrementing the refresh key
  void _refreshCurrentPage() {
    if (selectedPage != null) {
      setState(() {
        _refreshKey++;
      });
    }
  }

  // Builds a loading spinner widget displayed while checking user permissions
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.deepPurple),
    );
  }

  // Builds an access denied screen for users without manager permissions
  Widget _buildAccessDenied() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Security icon to visually indicate access restriction
              Icon(Icons.security, size: 80, color: Colors.red.shade400),
              const SizedBox(height: 20),
              const Text(
                'Access Denied',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Explanation message for the access restriction
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'You do not have permission to access the Management page.\nOnly users with Manager role can access this area.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              // Button to navigate back to previous screen
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the main management interface with navigation buttons and selected page content
  Widget _buildManagementContent() {
    return Column(
      children: [
        // Top navigation bar with back button, page selectors, and refresh button
        Container(
          color: const Color(0xFF212224),
          padding: const EdgeInsets.fromLTRB(30, 30, 30, 20),
          child: Row(
            children: [
              // Back navigation button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF3E3F41),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // Horizontally scrollable page selector buttons
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      // Generate buttons for each available page
                      children:
                          pageConstructors.keys.map((String name) {
                            final isSelected = selectedPage == name;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedPage = name;
                                  });
                                },
                                // Style button differently based on selection state
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                    isSelected
                                      ? Colors.deepPurple
                                      : const Color(0xFF3E3F41),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(name),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
              // Refresh button to reload the current page
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF3E3F41),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _refreshCurrentPage,
                  tooltip: 'Refresh Current Page',
                ),
              ),
            ],
          ),
        ),
        // Content area that displays the selected page or placeholder message
        Expanded(
          child:
            selectedPage != null
              ? pageConstructors[selectedPage]!()
              : const Center(
                child: Text(
                  "No page selected",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
        ),
      ],
    );
  }

  @override
  // Builds the main widget based on loading state and user permissions
  Widget build(BuildContext context) {
    // Show loading indicator while checking user role
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF212224),
        body: _buildLoadingIndicator(),
      );
    }

    // Show access denied screen for non-manager users
    if (!_isManager) {
      return Scaffold(
        backgroundColor: const Color(0xFF212224),
        body: _buildAccessDenied(),
      );
    }

    // Main management interface for authorized manager users
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF212224),
      body: Column(
        children: [
          // Top status bar spacer
          Row(
            children: [
              const Expanded(
                child: SizedBox(
                  height: 25,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ],
          ),
          // Main content area with sidebar navigation and management content
          Expanded(
            child: Row(
              children: [
                // Left sidebar navigation component
                NavigationSidebar(
                  selectedIndex: _selectedNavIndex,
                  onIconTapped: (index) {
                    // Navigate away if a different nav item is selected
                    if (index != _selectedNavIndex) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                // Main content area with page selector and selected page
                Expanded(child: _buildManagementContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
