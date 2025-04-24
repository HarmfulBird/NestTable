import 'package:flutter/material.dart';

class ReservationData {
  final int id;
  final String customerName;
  final int tableNumber;
  final DateTime startTime;
  final DateTime endTime;
  final int partySize;
  final bool seated;
  final bool isFinished;
  final Color color;

  ReservationData({
    required this.id,
    required this.customerName,
    required this.tableNumber,
    required this.startTime,
    required this.endTime,
    required this.partySize,
    required this.seated,
    this.isFinished = false,
    required this.color,
  });
}

