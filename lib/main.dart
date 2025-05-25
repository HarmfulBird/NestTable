import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'Pages/tableview_simple.dart';
import 'Pages/reservations.dart';
import 'Pages/order_view.dart';
import 'Components/navigation.dart';
import 'Pages/DataUploaders/uploader_selector.dart';
import 'Pages/login_page.dart';
import 'Services/role_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TableProvider())],
      child: const NestTableApp(),
    ),
  );
}

class NestTableApp extends StatelessWidget {
  const NestTableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Kanit'),
      home: const LoginPage(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    TableOverview(),
    Reservations(),
    OrderView(),
    Page4(),
    PageSelector(),
    Page6(),
  ];

  void _onIconTapped(int index) async {
    // Check if user is trying to access Management page (index 4)
    if (index == 4) {
      bool isManager = await RoleService.isManager();
      if (!isManager) {
        // Show access denied dialog
        if (!mounted) return;
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
        return; // Don't change the selected index
      }
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Row(children: [Expanded(child: TopBar())]),
          Expanded(
            child: Row(
              children: [
                NavigationSidebar(
                  selectedIndex: _selectedIndex,
                  onIconTapped: _onIconTapped,
                ),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Row(children: [SizedBox(height: 25)]),
    );
  }
}

class Page4 extends StatelessWidget {
  const Page4({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text("Page 4")));
  }
}

class Page6 extends StatelessWidget {
  const Page6({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text("Page 6")));
  }
}
