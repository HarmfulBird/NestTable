import 'package:flutter/material.dart';

// Model class to represent table data
class TableData {
  final int tableNumber;
  final int capacity;
  final String serverInitials;
  final String status;
  final Color statusColor;
  final int currentGuests;

  TableData({
    required this.tableNumber,
    required this.capacity,
    required this.serverInitials,
    required this.status,
    required this.statusColor,
    required this.currentGuests,
  });
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
                  selectedTable!.serverInitials,
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

class UpcomingBox extends StatelessWidget {
  final TableData? selectedTable;

  const UpcomingBox({
    required this.selectedTable,
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
          Text(
            'Upcoming Reservations:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                selectedTable != null
                    ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Upcoming Reservations',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                        ),
                      )
                    ]
                )
                    : const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Upcoming Reservations',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}