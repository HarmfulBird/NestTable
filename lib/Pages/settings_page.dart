import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Services/role_service.dart';
import '../Components/datetime.dart';
import 'DataUploaders/Uploaders/staff_data_crud.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isManager = false;
  String _currentRole = 'User';
  String _username = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final isManager = await RoleService.isManager();
      final role = await RoleService.getCurrentUserRole();
      final username = RoleService.getCurrentUsername() ?? 'Unknown';
      
      if (mounted) {
        setState(() {
          _isManager = isManager;
          _currentRole = role;
          _username = username;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF212224),
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF212224),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const DateTimeBox(),
            const SizedBox(height: 24),
            
            // User Profile Section
            _buildUserProfileCard(),
            const SizedBox(height: 20),
            
            // App Settings Section
            _buildAppSettingsCard(),
            const SizedBox(height: 20),
            
            // System Settings (Manager Only)
            if (_isManager) ...[
              _buildSystemSettingsCard(),
              const SizedBox(height: 20),
            ],
            
            // About Section
            _buildAboutCard(),
            const SizedBox(height: 20),
            
            // Logout Button
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileCard() {
    return Card(
      color: const Color(0xFF2F3031),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Username', _username),
            _buildInfoRow('Role', _currentRole),
            _buildInfoRow('Email', '$_username@nesttable.co.nz'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettingsCard() {
    return Card(
      color: const Color(0xFF2F3031),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Dark Mode',
              'Use dark theme throughout the app',
              true,
              (value) {
                // Toggle dark mode
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownSetting(
              'Default View',
              'Choose your default page on app start',
              ['Tables', 'Reservations', 'Orders', 'Servers'],
              'Tables',
              (value) {
                // Save default view preference
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSettingsCard() {
    return Card(
      color: const Color(0xFF2F3031),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'System Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.admin_panel_settings,
                  color: Colors.orange.shade400,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              'System Status',
              'Check system health and performance',
              Icons.health_and_safety,
              _checkSystemStatus,
            ),
            _buildActionTile(
              'User Management',
              'Manage staff accounts and permissions',
              Icons.people_alt,
              _manageUsers,
            ),
            _buildActionTile(
              'Data Export',
              'Export reports and analytics data',
              Icons.file_download,
              _exportData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      color: const Color(0xFF2F3031),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About NestTable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Version', '1.0.0'),
            _buildInfoRow('Build', '2025.05.29'),
            _buildInfoRow('Developer', 'FluffyTech'),
            const SizedBox(height: 16),
            _buildActionTile(
              'Check for Updates',
              'Look for app updates',
              Icons.system_update,
              _checkForUpdates,
            ),
            _buildActionTile(
              'Privacy Policy',
              'View our privacy policy',
              Icons.privacy_tip,
              _showPrivacyPolicy,
            ),
            _buildActionTile(
              'Support',
              'Get help and support',
              Icons.help,
              _showSupport,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showLogoutConfirmation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade400),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String subtitle,
    List<String> options,
    String currentValue,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currentValue,
          dropdownColor: const Color(0xFF2F3031),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade400),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white70,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  // Action methods
  void _changePassword() {
    // Implement password change dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2F3031),
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        content: const Text('Password change functionality would be implemented here.', 
                           style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  void _performBackup() {
    // Implement backup functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup initiated...')),
    );
  }

  void _checkSystemStatus() {
    // Implement system status check
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2F3031),
        title: const Text('System Status', style: TextStyle(color: Colors.white)),
        content: const Text('All systems operational ✓', style: TextStyle(color: Colors.green)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  void _manageUsers() {
    // Navigate to user management (could reuse your staff data CRUD)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StaffDataUploader(),
      ),
    );
  }

  void _exportData() {
    // Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export started...')),
    );
  }

  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You are running the latest version')),
    );
  }

  void _showPrivacyPolicy() {
    // Show privacy policy dialog or navigate to web view
  }

  void _showSupport() {
    // Show support information
  }

  void _showLogoutConfirmation() {
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
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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
  }
}