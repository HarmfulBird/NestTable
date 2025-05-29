import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// A reusable widget that displays the current date and time in a styled container
// Updates automatically every second to show real-time information
class DateTimeBox extends StatefulWidget {
  const DateTimeBox({super.key});

  @override
  // Creates the mutable state for this widget
  State<DateTimeBox> createState() => _DateTimeBoxState();
}

// The state class that manages the widget's data and lifecycle
class _DateTimeBoxState extends State<DateTimeBox> {
  late Timer _timer;
  String _formattedDateTime = '';

  @override
  // Sets up the widget when it first loads and starts a timer to update time every second
  void initState() {
    super.initState();
    // Initialize with current time immediately
    _updateDateTime();
    // Create a repeating timer that calls _updateDateTime every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
  }

  @override
  // Cleans up the timer when the widget is destroyed to prevent memory leaks
  void dispose() {
    // Cancel the timer to stop it from running after widget disposal
    _timer.cancel();
    super.dispose();
  }

  // Updates the displayed date and time to current time in dd/MM/yyyy hh:mm a format
  void _updateDateTime() {
    // Triggers a rebuild of the widget with new time data
    setState(() {
      // Formats current time using DateFormat with specific pattern and extra spaces for alignment
      _formattedDateTime = DateFormat(
        'dd/MM/yyyy   hh:mm a',
      ).format(DateTime.now());
    });
  }

  @override
  // Builds the UI widget that displays the current date and time in a styled container
  Widget build(BuildContext context) {
    return Container(
      // Sets internal spacing around the content
      padding: EdgeInsets.fromLTRB(37.0, 16.0, 37.0, 16.0),
      // Applies visual styling with dark background and rounded corners
      decoration: BoxDecoration(
        color: Color(0xFF212224),
        borderRadius: BorderRadius.circular(15.0),
      ),
      // Contains the text content in a vertical layout
      child: Column(
        children: [
          // Displays the formatted date and time string
          Text(
            _formattedDateTime,
            // Applies white text with large bold font for visibility
            style: TextStyle(
              color: Colors.white,
              fontSize: 26.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
