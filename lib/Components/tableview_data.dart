import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Data model representing a restaurant table with its properties
class TableData {
  final int tableNumber; // Table number identifier
  final int capacity; // Maximum capacity of the table
  final String assignedServer; // Name of the server assigned to the table
  final String
  status; // Current status of the table (e.g., Available, Reserved)
  final Color statusColor; // Color representation of the status
  final int currentGuests; // Current number of guests seated at the table

  TableData({
    required this.tableNumber,
    required this.capacity,
    required this.assignedServer,
    required this.status,
    required this.statusColor,
    required this.currentGuests,
  });
}

// Data model representing a customer reservation
class Reservation {
  final String id; 
  final DateTime startTime; 
  final String name; 
  final int partySize; 
  final String phoneNumber; 
  final String notes; 
  final int? tableNumber; 

  Reservation({
    required this.id,
    required this.startTime,
    required this.name,
    required this.partySize,
    this.phoneNumber = '',
    this.notes = '',
    this.tableNumber,
  });

  // Creates a Reservation object from a Firestore document
  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reservation(
      id: doc.id,
      startTime: (data['startTime'] as Timestamp).toDate(),
      name: data['customerName'] ?? 'Unknown',
      partySize: data['partySize'] ?? 0,
      phoneNumber: data['phoneNumber'] ?? '',
      notes: data['notes'] ?? '',
      tableNumber: data['tableNumber'],
    );
  }
}

// Widget that displays detailed information about a selected table
class TableInfoBox extends StatelessWidget {
  final TableData? selectedTable; // Currently selected table data

  const TableInfoBox({required this.selectedTable, super.key});

  // Builds the table information display widget
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF212224),
        borderRadius: BorderRadius.circular(12),
      ),
      child:
        selectedTable != null
          ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table number and status display row
              Row(
                children: [
                  // Table number title
                  Text(
                    'Table ${selectedTable!.tableNumber}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Status indicator badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 20,
                    ),
                    width: 135,
                    height: 53,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selectedTable!.statusColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        selectedTable!.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Capacity and server information row
              Row(
                children: [
                  // Capacity label
                  Text(
                    'Capacity: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  // Capacity value badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 3,
                      horizontal: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF454545')),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      selectedTable!.capacity.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Server label
                  const Text(
                    'Server: ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  // Server name badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 3,
                      horizontal: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      selectedTable!.assignedServer,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Current guests count display
              Row(
                children: [
                  // Guests label
                  Text(
                    'Guests Seated: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  // Guest count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF454545')),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      selectedTable!.currentGuests.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          )
          // Display message when no table is selected
          : const Text(
            'No Table Selected',
            style: TextStyle(color: Colors.white70, fontSize: 26),
          ),
    );
  }
}

// Widget that displays a single reservation item in a list
class ReservationItem extends StatelessWidget {
  final Reservation reservation; // Reservation data to display

  const ReservationItem({required this.reservation, super.key});

  // Builds a single reservation item widget
  @override
  Widget build(BuildContext context) {
    // Format time for display (e.g., "7:30 PM")
    final timeFormat = DateFormat('h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2C2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Time display badge
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF454545),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              timeFormat.format(reservation.startTime),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Reservation details (name, table, party size)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer name
                Text(
                  reservation.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // Table number badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF454545),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Table ${reservation.tableNumber ?? "TBD"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Party size information
                    Text(
                      'Party of ${reservation.partySize}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Phone icon with tooltip (shown if phone number exists)
          if (reservation.phoneNumber.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: reservation.phoneNumber,
                child: const Icon(Icons.phone, color: Colors.white70, size: 18),
              ),
            ),
          // Notes icon with tooltip (shown if notes exist)
          if (reservation.notes.isNotEmpty)
            Tooltip(
              message: reservation.notes,
              child: const Icon(
                Icons.info_outline,
                color: Colors.white70,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

// Widget that displays upcoming reservations in a scrollable list
class UpcomingBox extends StatelessWidget {
  final TableData? selectedTable; // Currently selected table data

  const UpcomingBox({this.selectedTable, super.key});

  // Builds the upcoming reservations display widget
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 385),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF212224),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Reservations',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Scrollable list of reservations
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUpcomingReservationsStream(null),
              builder: (context, snapshot) {
                // Show loading indicator while fetching data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.deepPurple),
                  );
                }

                // Show error message if data fetch fails
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading reservations',
                      style: TextStyle(color: Colors.red[300], fontSize: 16),
                    ),
                  );
                }

                // Process the fetched data into reservation objects
                final reservations = _processReservationsData(snapshot.data);

                // Show message when no reservations are found
                if (reservations.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Upcoming Reservations',
                      style: TextStyle(color: Colors.white70, fontSize: 20),
                    ),
                  );
                }

                // Build the list of reservation items
                return ListView.builder(
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    return ReservationItem(reservation: reservations[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Gets a stream of upcoming reservations from Firestore
  // Fetches reservations starting from now up to 4 hours in the future
  Stream<QuerySnapshot> _getUpcomingReservationsStream(int? tableNumber) {
    final now = DateTime.now();
    final fourHoursLater = now.add(const Duration(hours: 4));

    return FirebaseFirestore.instance
      .collection('Reservations')
      .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where(
        'startTime',
        isLessThanOrEqualTo: Timestamp.fromDate(fourHoursLater),
      )
      .orderBy('startTime', descending: false)
      .limit(15)
      .snapshots();
  }

  // Converts Firestore snapshot data into a list of Reservation objects
  List<Reservation> _processReservationsData(QuerySnapshot? snapshot) {
    if (snapshot == null || snapshot.docs.isEmpty) {
      return [];
    }

    return snapshot.docs.map((doc) => Reservation.fromFirestore(doc)).toList();
  }
}
