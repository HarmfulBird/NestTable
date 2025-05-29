import 'package:flutter/material.dart';
import '../main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../custom_icons_icons.dart';

// Login page widget that handles user authentication
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Handles user login with Firebase authentication and navigates to home screen on success
  Future<void> _handleLogin() async {
    try {
      // Construct email from username by appending domain
      String email = "${_usernameController.text.trim()}@nesttable.co.nz";
      String password = _passwordController.text;

      // Attempt to sign in with Firebase Authentication
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Check if widget is still mounted before navigation
      if (!mounted) return;
      // Navigate to home screen on successful login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // Default error message for any authentication failure
      String errorMessage = 'An error occurred. Please try again.';

      // Handle specific authentication error codes
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = 'Invalid username or password';
      }

      // Check if widget is still mounted before showing snackbar
      if (!mounted) return;
      // Display error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  // Cleans up text controllers when widget is destroyed
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Prevent keyboard from resizing the screen layout
      resizeToAvoidBottomInset: false,
      // Dark background color
      backgroundColor: const Color(0xFF212224),
      body: Center(
        child: Container(
          // Add padding and set maximum width for responsive design
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            // Center all elements vertically
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo at the top
              const Icon(CustomIcons.logo, size: 200, color: Colors.white),
              const SizedBox(height: 60),
              // Username input field
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Username / ID',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFF2F3031),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Password input field with visibility toggle
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFF2F3031),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  // Eye icon to toggle password visibility
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                      color: Colors.grey.shade400,
                    ),
                    onPressed: () {
                      // Toggle password visibility state
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
