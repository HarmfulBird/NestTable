import 'package:flutter/material.dart';
import '../custom_icons_icons.dart';
import '../Pages/login_page.dart';
import '../Services/role_service.dart';

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

class _NavigationSidebarState extends State<NavigationSidebar> {
  bool _isManager = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    bool isManager = await RoleService.isManager();
    if (mounted) {
      setState(() {
        _isManager = isManager;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: Color(int.parse("0xFFE0ACD5")),
      child: Column(
        children: [
          SizedBox(height: 20),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF2F3031),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(color: Colors.white),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
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
            child: Icon(CustomIcons.logo, color: Colors.black, size: 50),
          ),
          SizedBox(height: 40),
          _buildIconButton(0, CustomIcons.th_large_outline, "Tables", false),
          SizedBox(height: 1),
          _buildIconButton(1, CustomIcons.reservations, "Reservations", true),
          SizedBox(height: 1),
          _buildIconButton(2, CustomIcons.order, "Orders", true),
          SizedBox(height: 1),
          _buildIconButton(3, CustomIcons.group, "Servers", true),
          Spacer(),
          _buildIconButton(4, CustomIcons.management, "Management", true),
          SizedBox(height: 10),
          _buildIconButton(5, CustomIcons.settings, "Settings", true),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    int index,
    IconData icon,
    String label,
    bool addThickness,
  ) {
    final bool isSelected = widget.selectedIndex == index;
    final bool isManagementButton = index == 4;
    final bool isRestricted = isManagementButton && !_isManager;

    return GestureDetector(
      onTap: () => widget.onIconTapped(index),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
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
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? Colors.white
                        : isRestricted
                        ? Colors.grey
                        : Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconLayer(
    IconData icon,
    bool isSelected,
    double size,
    bool isRestricted,
  ) {
    return Icon(
      icon,
      color:
          isSelected
              ? Colors.white
              : isRestricted
              ? Colors.grey
              : Colors.black,
      size: size,
    );
  }
}
