import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeBox extends StatelessWidget {
  const DateTimeBox({super.key});

  @override
  Widget build(BuildContext context) {
    String formattedDateTime = DateFormat('dd/MM/yyy   hh:mm a').format(DateTime.now());

    return Container(
      padding: EdgeInsets.fromLTRB(37.0, 16.0, 37.0, 16.0),
      decoration: BoxDecoration(
        color: Color(0xFF212224),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        children: [
          Text(
            formattedDateTime,
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

