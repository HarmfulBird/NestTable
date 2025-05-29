import 'package:flutter/material.dart';

// Represents a restaurant table reservation with all necessary details
// This class serves as a data model for managing restaurant reservations
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
  final String specialNotes;

  // Constructor for creating a new ReservationData instance
  // Requires all essential reservation information
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
    this.specialNotes = '',
  });
}
