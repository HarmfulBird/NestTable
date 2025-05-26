import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeBox extends StatefulWidget {
  const DateTimeBox({super.key});

  @override
  State<DateTimeBox> createState() => _DateTimeBoxState();
}

class _DateTimeBoxState extends State<DateTimeBox> {
  late Timer _timer;
  String _formattedDateTime = '';

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateDateTime() {
    setState(() {
      _formattedDateTime = DateFormat(
        'dd/MM/yyyy   hh:mm a',
      ).format(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(37.0, 16.0, 37.0, 16.0),
      decoration: BoxDecoration(
        color: Color(0xFF212224),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        children: [
          Text(
            _formattedDateTime,
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
