import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Model class to represent table data
class TableData {
  final int tableNumber;
  final int capacity;
  final String assignedServer;
  final String status;
  final Color statusColor;
  final int currentGuests;

  TableData({
    required this.tableNumber,
    required this.capacity,
    required this.assignedServer,
    required this.status,
    required this.statusColor,
    required this.currentGuests,
  });
}

// Model class for reservations
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

  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reservation(
      id: doc.id,
      startTime: (data['startTime'] as Timestamp).toDate(),
      name: data['name'] ?? 'Unknown',
      partySize: data['partySize'] ?? 0,
      phoneNumber: data['phoneNumber'] ?? '',
      notes: data['notes'] ?? '',
      tableNumber: data['tableNumber'],
    );
  }
}

class TableInfoBox extends StatelessWidget {
  final TableData? selectedTable;

  const TableInfoBox({
    required this.selectedTable,
    super.key,
  });

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
      child: selectedTable != null
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Table ${selectedTable!.tableNumber}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
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

          Row(
            children: [
              Text(
                'Capacity: ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 15),
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

              const SizedBox(width: 20,),

              const Text(
                'Server: ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 15),
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

          Row(
              children: [
                Text(
                  'Guests Seated: ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 15),
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
              ]
          ),
          const SizedBox(height: 10),
        ],
      )
          : const Text(
        'No Table Selected',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 26,
        ),
      ),
    );
  }
}

class ReservationItem extends StatelessWidget {
  final Reservation reservation;

  const ReservationItem({
    required this.reservation,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.indigo,
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
          if (reservation.phoneNumber.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: reservation.phoneNumber,
                child: const Icon(
                  Icons.phone,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ),
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

class UpcomingBox extends StatelessWidget {
  // Making selectedTable optional since we'll now show all reservations
  final TableData? selectedTable;

  const UpcomingBox({
    this.selectedTable,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxHeight: 385,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF212224),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUpcomingReservationsStream(null),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurple,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading reservations',
                      style: TextStyle(color: Colors.red[300], fontSize: 16),
                    ),
                  );
                }

                final reservations = _processReservationsData(snapshot.data);

                if (reservations.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Upcoming Reservations',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    return ReservationItem(
                      reservation: reservations[index],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Get stream of upcoming reservations regardless of table
  Stream<QuerySnapshot> _getUpcomingReservationsStream(int? tableNumber) {
    final now = DateTime.now();
    final fourHoursLater = now.add(const Duration(hours: 4));

    return FirebaseFirestore.instance
        .collection('Reservations')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(fourHoursLater))
        .orderBy('startTime', descending: false)
        .limit(15) // Increased limit for all reservations
        .snapshots();
  }

  // Process the snapshot data into a list of Reservation objects
  List<Reservation> _processReservationsData(QuerySnapshot? snapshot) {
    if (snapshot == null || snapshot.docs.isEmpty) {
      return [];
    }

    return snapshot.docs
        .map((doc) => Reservation.fromFirestore(doc))
        .toList();
  }
}