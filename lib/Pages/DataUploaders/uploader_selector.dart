import 'package:flutter/material.dart';
import 'Uploaders/table_data_crud.dart';
import 'Uploaders/staff_data_crud.dart';
import 'Uploaders/reservation_data_crud.dart';
import 'Uploaders/item_data_crud.dart';
import 'Uploaders/change_dates.dart';
import '../../Services/role_service.dart';

class PageSelector extends StatefulWidget {
  const PageSelector({super.key});

  @override
  PageSelectorState createState() => PageSelectorState();
}

class PageSelectorState extends State<PageSelector> {
  String? selectedPage;
  bool _isManager = false;
  bool _isLoading = true;

  final Map<String, Widget Function()> pageConstructors = {
    'Table Data': () => TableDataUploader(),
    'Staff Data': () => StaffDataUploader(),
    'Reservation Data': () => ReservationDataUploader(),
    'Item Data': () => ItemDataUploader(),
    'Change Dates': () => ChangeDatesUploader(),
  };

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool isManager = await RoleService.isManager();
    setState(() {
      _isManager = isManager;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212224),
      appBar: AppBar(
        title: const Text(
          "Page Selector",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2F3031),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              )
              : !_isManager
              ? _buildAccessDeniedContent()
              : _buildManagementContent(),
    );
  }

  Widget _buildAccessDeniedContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
}
