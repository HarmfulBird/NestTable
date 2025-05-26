import 'package:flutter/material.dart';
import 'Uploaders/table_data_crud.dart';
import 'Uploaders/staff_data_crud.dart';
import 'Uploaders/reservation_data_crud.dart';
import 'Uploaders/item_data_crud.dart';
import 'Uploaders/change_dates.dart';
import '../../Services/role_service.dart';
import '../../Components/navigation.dart';

class PageSelector extends StatefulWidget {
  const PageSelector({super.key});

  @override
  PageSelectorState createState() => PageSelectorState();
}

class PageSelectorState extends State<PageSelector> {
  String? selectedPage;
  bool _isManager = false;
  bool _isLoading = true;
  int _selectedNavIndex = 4;

  final Map<String, Widget Function()> pageConstructors = {
    'Table Data': () => const TableDataUploader(),
    'Staff Data': () => const StaffDataUploader(),
    'Reservation Data': () => const ReservationDataUploader(),
    'Item Data': () => const ItemDataUploader(),
    'Change Dates': () => const ChangeDatesUploader(),
  };

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    try {
      bool isManager = await RoleService.isManager();
      if (mounted) {
        setState(() {
          _isManager = isManager;
          _isLoading = false;
        });
      }
    } catch (e) {
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

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.deepPurple),
    );
  }

  Widget _buildAccessDenied() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'You do not have permission to access the Management page.\nOnly users with Manager role can access this area.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementContent() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF212224),
          padding: const EdgeInsets.symmetric(vertical: 26.0, horizontal: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF212224),
        body: _buildLoadingIndicator(),
      );
    }

    if (!_isManager) {
      return Scaffold(
        backgroundColor: const Color(0xFF212224),
        body: _buildAccessDenied(),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF212224),
      body: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                color: Colors.black,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const Expanded(
                child: SizedBox(
                  height: 48,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                NavigationSidebar(
                  selectedIndex: _selectedNavIndex,
                  onIconTapped: (index) {
                    if (index != _selectedNavIndex) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                Expanded(child: _buildManagementContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
