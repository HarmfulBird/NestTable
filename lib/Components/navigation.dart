import 'package:flutter/material.dart';
import '../custom_icons_icons.dart';

class NavigationSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIconTapped;

  const NavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onIconTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: Color(int.parse("0xFFE0ACD5")),
      child: Column(
        children: [
          SizedBox(height: 20),
          Icon(CustomIcons.logo, color: Colors.black, size: 50),
          Spacer(flex: 6),
          // Ensure indices align properly here
          _buildIconButton(0, CustomIcons.th_large_outline, "Tables", false),
          SizedBox(height: 1),
          _buildIconButton(1, CustomIcons.reservations, "Reservations", true),
          SizedBox(height: 1),
          _buildIconButton(2, CustomIcons.order, "Orders", true),
          SizedBox(height: 1),
          _buildIconButton(3, CustomIcons.group, "Servers", true),
          Spacer(flex: 10),
          _buildIconButton(4, CustomIcons.management, "Management", true),
          SizedBox(height: 10),
          _buildIconButton(5, CustomIcons.settings, "Settings", true),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildIconButton(int index, IconData icon, String label, bool addThickness) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onIconTapped(index),
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
            Padding(
              padding: EdgeInsets.all(addThickness ? 4.0 : 0.0),
              child: _iconLayer(icon, isSelected, 50),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconLayer(IconData icon, bool isSelected, double size) {
    return Icon(
      icon,
      color: isSelected ? Colors.white : Colors.black,
      size: size,
    );
  }
}