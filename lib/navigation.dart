import 'package:flutter/material.dart';
import 'custom_icons_icons.dart';

class NavigationSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onIconTapped;

  NavigationSidebar({required this.selectedIndex, required this.onIconTapped});

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
          _buildIconButton(1, CustomIcons.th_large_outline, "Tables", false), // No thick effect
          SizedBox(height: 1),
          _buildIconButton(2, CustomIcons.reservations, "Reservations", true), // Thick effect
          SizedBox(height: 1),
          _buildIconButton(3, CustomIcons.order, "Orders", true), // Thick effect
          SizedBox(height: 1),
          _buildIconButton(4, CustomIcons.group, "Servers", true), // Thick effect
          Spacer(flex: 10),
          _buildIconButton(5, CustomIcons.management, "Management", true), // Thick effect
          SizedBox(height: 10),
          _buildIconButton(6, CustomIcons.settings, "Settings", true), // Thick effect
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
              padding: EdgeInsets.all(addThickness ? 4.0 : 0.0), // Adding padding to create a "thicker" effect
              child: _iconLayer(icon, isSelected, 50), // Icon with the adjusted size
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