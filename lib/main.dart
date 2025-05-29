import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'Pages/tableview_simple.dart';
import 'Pages/reservations.dart';
import 'Pages/order_view.dart';
import 'Components/navigation.dart';
import 'Pages/management_dashboard.dart';
import 'Pages/login_page.dart';
import 'Pages/servers_page.dart';
import 'Services/role_service.dart';
import 'Services/user_preference_service.dart';
import 'Pages/settings_page.dart';

// Entry point of the app - initializes Firebase and starts the app
Future<void> main() async {
  // Ensures Flutter widget binding is properly initialized before running async operations
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase with platform-specific configuration
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Start the app with state management provider for table data
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TableProvider())],
      child: const NestTableApp(),
    ),
  );
}

// Root widget of the NestTable application
class NestTableApp extends StatelessWidget {
  const NestTableApp({super.key});

  // Builds the main app structure with theme and starting page
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove debug banner for cleaner appearance
      debugShowCheckedModeBanner: false,
      // Apply custom Kanit font family throughout the app
      theme: ThemeData(fontFamily: 'Kanit'),
      // Set LoginPage as the initial screen
      home: const LoginPage(),
    );
  }
}

// Main home screen widget that manages navigation between different pages
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

/// State class that handles navigation logic and page display
class HomeScreenState extends State<HomeScreen> {
  // Tracks which navigation item is currently selected
  int _selectedIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultView();
  }

  // Load user's default view preference and set initial page
  Future<void> _loadDefaultView() async {
    try {
      final defaultView = await UserPreferenceService.getDefaultView();
      final defaultIndex = UserPreferenceService.getDefaultViewIndex(
        defaultView,
      );
      if (mounted) {
        setState(() {
          _selectedIndex = defaultIndex;
          _isInitialized = true;
        });
      }
    } catch (e) {
      // If loading fails, default to Tables (index 0)
      if (mounted) {
        setState(() {
          _selectedIndex = 0;
          _isInitialized = true;
        });
      }
    }
  }

  // List of all available pages in the app navigation
  final List<Widget> _pages = [
    TableOverview(),
    Reservations(),
    OrderView(),
    ServersPage(),
    ManagementDashboard(),
    SettingsPage(),
  ];

  // Handles navigation when sidebar icons are tapped
  void _onIconTapped(int index) async {
    // Special handling for Management Dashboard (index 4) - requires manager role
    if (index == 4) {
      // Check if current user has manager privileges
      bool isManager = await RoleService.isManager();
      if (!isManager) {
        // Ensure widget is still mounted before showing dialog
        if (!mounted) return;
        // Show access denied dialog for non-manager users
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2F3031),
              title: const Text(
                'Access Denied',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'You do not have permission to access the Management page. Only users with Manager role can access this area.',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ],
            );
          },
        );
        // Exit early without changing page
        return;
      }
    }

    // Update selected index to display the chosen page
    setState(() {
      _selectedIndex = index;
    });
  }

  // Builds the main screen layout with top bar and sidebar navigation
  @override
  Widget build(BuildContext context) {
    // Show loading indicator while default view is being loaded
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF212224),
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }
    return Scaffold(
      // Prevent keyboard from pushing content up
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // Top bar section at the top of the screen
          Row(children: [Expanded(child: TopBar())]),
          Expanded(
            child: Row(
              children: [
                // Left sidebar navigation with current selection and tap handler
                NavigationSidebar(
                  selectedIndex: _selectedIndex,
                  onIconTapped: _onIconTapped,
                ),
                // Main content area displaying the selected page
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Simple top bar widget that provides a black header section
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  // Creates a black top bar with minimal height
  @override
  Widget build(BuildContext context) {
    return Container(
      // Black background color for the top bar
      color: Colors.black,
      // Empty row with fixed height to create space
      child: Row(children: [SizedBox(height: 25)]),
    );
  }
}
