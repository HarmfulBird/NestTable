import 'package:flutter/material.dart';
import 'package:nesttable/custom_icons_icons.dart';
import 'dart:math';
import '../Components/datetime.dart';
import '../Components/reservationdata.dart';

class Reservations extends StatefulWidget {
  const Reservations({super.key});

  @override
  State<Reservations> createState() => _ReservationsState();
}

class _ReservationsState extends State<Reservations> {
  ReservationData? selectedReservation;
  List<ReservationData> reservations = [];
  final Random _random = Random();
  DateTime currentDate = DateTime(2025, 3, 12);

  @override
  void initState() {
    super.initState();
    // Initialize with sample data
    _generateSampleData();
    // Set initial selected reservation
    if (reservations.isNotEmpty) {
      selectedReservation = reservations.first;
    }
  }

  void _generateSampleData() {
    // Sample colors for reservations
    final colors = [
      Colors.purple.shade400,
      Colors.cyan.shade400,
      Colors.green.shade400,
      Colors.blue.shade400
    ];

    // Add sample reservation data
    reservations = [
      ReservationData(
        id: 1,
        customerName: 'Samantha Nord',
        tableNumber: 1,
        startTime: DateTime(2025, 3, 12, 13, 0),
        endTime: DateTime(2025, 3, 12, 15, 0),
        partySize: 3,
        seated: true,
        isFinished: false,
        color: colors[0],
      ),
      ReservationData(
        id: 2,
        customerName: 'Harlan Guzman',
        tableNumber: 2,
        startTime: DateTime(2025, 3, 12, 14, 0),
        endTime: DateTime(2025, 3, 12, 16, 0),
        partySize: 4,
        seated: false,
        isFinished: false,
        color: colors[1],
      ),
      ReservationData(
        id: 3,
        customerName: 'Alex Norton',
        tableNumber: 3,
        startTime: DateTime(2025, 3, 12, 15, 0),
        endTime: DateTime(2025, 3, 12, 17, 0),
        partySize: 4,
        seated: false,
        isFinished: false,
        color: colors[2],
      ),
      ReservationData(
        id: 4,
        customerName: 'Celia May',
        tableNumber: 4,
        startTime: DateTime(2025, 3, 13, 16, 0),
        endTime: DateTime(2025, 3, 13, 18, 0),
        partySize: 3,
        seated: true,
        isFinished: false,
        color: colors[3],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 400,
                  padding: const EdgeInsets.all(16.0),
                  color: const Color(0xFF2F3031),
                  child: Column(
                    children: [
                      const DateTimeBox(),
                      const SizedBox(height: 20),
                      reservationInfoBox(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF212224),
                    ),
                    child: _buildCalendarView(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  "Wednesday, March 12",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white, size: 24),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        // Time labels row
        Padding(
          padding: const EdgeInsets.only(left: 50, right: 16, top: 10, bottom: 5),
          child: Row(
            children: [
              _buildTimeLabel("1 PM"),
              _buildTimeLabel("2 PM"),
              _buildTimeLabel("3 PM"),
              _buildTimeLabel("4 PM"),
              _buildTimeLabel("5 PM"),
              _buildTimeLabel("6 PM"),
              _buildTimeLabel("7 PM"),
              _buildTimeLabel("8 PM"),
              _buildTimeLabel("9 PM"),
            ],
          ),
        ),

        // Time indication markers
        Padding(
          padding: const EdgeInsets.only(left: 50, right: 16),
          child: Row(
            children: List.generate(9, (index) {
              return Expanded(
                child: Center(
                  child: Container(
                    height: 4,
                    width: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // Table rows and reservations
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16),
            itemCount: 8, // 8 tables
            itemBuilder: (context, index) {
              return _buildTableRow(index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeLabel(String time) {
    return Expanded(
      child: Center(
        child: Text(
          time,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(int tableNumber) {
    // Get table capacity (from the image)
    String tableCapacity;
    switch (tableNumber) {
      case 1:
        tableCapacity = "2-4";
        break;
      case 2:
        tableCapacity = "1-2";
        break;
      case 3:
        tableCapacity = "2-4";
        break;
      case 4:
        tableCapacity = "4-6";
        break;
      case 5:
        tableCapacity = "1-2";
        break;
      case 6:
        tableCapacity = "2-6";
        break;
      case 7:
        tableCapacity = "2-6";
        break;
      case 8:
        tableCapacity = "2-4";
        break;
      default:
        tableCapacity = "2-4";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      "$tableNumber",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tableCapacity,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: _buildReservationsForTable(tableNumber),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReservationsForTable(int tableNumber) {
    List<Widget> reservationWidgets = [];

    final tableReservations = reservations.where((res) =>
    res.tableNumber == tableNumber &&
        res.startTime.year == currentDate.year &&
        res.startTime.month == currentDate.month &&
        res.startTime.day == currentDate.day
    ).toList();

    for (var reservation in tableReservations) {

      final timelineStart = 13.0;

      final startHour = reservation.startTime.hour;
      final endHour = reservation.endTime.hour;

      final startPosition = (startHour - timelineStart) + 15;
      final width = (endHour - startHour) * 86;

      reservationWidgets.add(
        Positioned(
          left: startPosition + (86 * (startHour - timelineStart)),
          width: width * 1,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedReservation = reservation;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: reservation.color,
                borderRadius: BorderRadius.circular(8),
                border: selectedReservation?.id == reservation.id
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (reservation.partySize > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people, size: 16, color: Colors.white),
                              SizedBox(width: 2),
                              Text(
                                "${reservation.partySize}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          reservation.customerName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return reservationWidgets;
  }

  Widget reservationInfoBox() {
    if (selectedReservation == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF242527),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            "No reservation selected",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    String formatTime(DateTime time) {
      final hour = time.hour > 12 ? time.hour - 12 : time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute$period';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242527),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header with customer name, party size icon, and table number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selectedReservation!.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Customer name and party size
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        selectedReservation!.customerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(CustomIcons.group, size: 24, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              "${selectedReservation!.partySize}",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Table number
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.table_restaurant_outlined, color: Colors.white, size: 24,),
                      const SizedBox(width: 4),
                      Text(
                        "${selectedReservation!.tableNumber}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  )
                ),
              ],
            ),
          ),

          // Reservation details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reservation status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Status:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selectedReservation!.seated == true ?
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                          Text(
                            'Seated',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                      ) :
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                          Text(
                            'Waiting',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                      )
                  ],
                ),

                const SizedBox(height: 12),

                // Estimated finish time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Start:",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      formatTime(selectedReservation!.startTime),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Estimated finish time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Estimated Finish:",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      formatTime(selectedReservation!.endTime),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: selectedReservation!.seated == true ?
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF62CB99),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        child:
                          Text(
                            "Finished",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ) :
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                        Text(
                          "Seat",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ),
                    const SizedBox(width: 8),
                    // Edit button
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E3F41),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}