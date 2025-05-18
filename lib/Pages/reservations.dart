import 'package:flutter/material.dart';
import 'package:nesttable/custom_icons_icons.dart';
import 'dart:math';
import '../Components/datetime.dart';
import '../Components/reservationdata.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Reservations extends StatefulWidget {
  const Reservations({super.key});

  @override
  State<Reservations> createState() => _ReservationsState();
}

class _ReservationsState extends State<Reservations> {
  ReservationData? selectedReservation;
  List<ReservationData> reservations = [];
  DateTime currentDate = DateTime.now();
  bool showOverlay = false;
  TextEditingController firstNameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController guestsController = TextEditingController();
  TextEditingController specialNotesController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedTable;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToReservations();
  }

  void _listenToReservations() {
    FirebaseFirestore.instance
        .collection('Reservations')
        .orderBy('startTime')
        .snapshots()
        .listen((snapshot) {
      final List<ReservationData> updatedReservations = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        updatedReservations.add(
          ReservationData(
            id: data['id'],
            customerName: data['customerName'] ?? '',
            tableNumber: data['tableNumber'] ?? 0,
            startTime: (data['startTime'] as Timestamp).toDate(),
            endTime: (data['endTime'] as Timestamp).toDate(),
            partySize: data['partySize'] ?? 0,
            seated: data['seated'] ?? false,
            isFinished: data['isFinished'] ?? false,
            color: _getReservationColor(),
          ),
        );
      }

      setState(() {
        reservations = updatedReservations;
        _isLoading = false;
        _updateSelectedReservation();
      });
    });
  }

  Color _getReservationColor() {
    final colors = [
      Colors.purple.shade400,
      Colors.cyan.shade400,
      Colors.green.shade400,
      Colors.blue.shade400,
    ];
    return colors[DateTime.now().microsecond % colors.length];
  }

  void _previousDay() {
    setState(() {
      currentDate = currentDate.subtract(const Duration(days: 1));
      _updateSelectedReservation();
    });
  }

  void _nextDay() {
    setState(() {
      currentDate = currentDate.add(const Duration(days: 1));
      _updateSelectedReservation();
    });
  }

  void _updateSelectedReservation() {
    final currentDayReservations =
    reservations
        .where(
          (res) =>
      res.startTime.year == currentDate.year &&
          res.startTime.month == currentDate.month &&
          res.startTime.day == currentDate.day,
    )
        .toList();

    if (currentDayReservations.isNotEmpty) {
      selectedReservation = currentDayReservations.first;
    } else {
      selectedReservation = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
            onPressed: () {
              setState(() {
                showOverlay = true;
              });
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.add, color: Colors.black),
          ),
        ),
        if (showOverlay)
          Container(
            color: Colors.black54,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: 400,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F3031),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'New Reservation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                showOverlay = false;
                                firstNameController.clear();
                                surnameController.clear();
                                guestsController.clear();
                                specialNotesController.clear();
                                selectedDate = null;
                                selectedTime = null;
                                selectedTable = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: firstNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: surnameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Surname',
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (date != null) {
                                  setState(() {
                                    selectedDate = date;
                                  });
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                backgroundColor: const Color(0xFF212224),
                              ),
                              child: Text(
                                selectedDate != null
                                    ? DateFormat(
                                  'dd/MM/yyyy',
                                ).format(selectedDate!)
                                    : 'Select Date',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setState(() {
                                    selectedTime = time;
                                  });
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                backgroundColor: const Color(0xFF212224),
                              ),
                              child: Text(
                                selectedTime != null
                                    ? selectedTime!.format(context)
                                    : 'Select Time',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: guestsController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Number of Guests',
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: specialNotesController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Special Notes',
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedTable,
                        dropdownColor: const Color(0xFF212224),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Assign Table',
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        items: List.generate(8, (index) {
                          return DropdownMenuItem(
                            value: (index + 1).toString(),
                            child: Text(
                              'Table ${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }),
                        onChanged: (String? value) {
                          setState(() {
                            selectedTable = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                showOverlay = false;
                                firstNameController.clear();
                                surnameController.clear();
                                guestsController.clear();
                                specialNotesController.clear();
                                selectedDate = null;
                                selectedTime = null;
                                selectedTable = null;
                              });
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Add reservation logic here
                              setState(() {
                                showOverlay = false;
                                firstNameController.clear();
                                surnameController.clear();
                                guestsController.clear();
                                specialNotesController.clear();
                                selectedDate = null;
                                selectedTime = null;
                                selectedTable = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarView() {
    final DateTime previousDate = currentDate.subtract(const Duration(days: 1));
    final DateTime nextDate = currentDate.add(const Duration(days: 1));

    final DateFormat fullFormatter = DateFormat('EEEE, MMMM d');
    final DateFormat dayFormatter = DateFormat('EEE, MMM d');

    final String formattedCurrentDate = fullFormatter.format(currentDate);
    final String formattedPreviousDate = dayFormatter.format(previousDate);
    final String formattedNextDate = dayFormatter.format(nextDate);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF2F3031),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: _previousDay,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: _previousDay,
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      formattedPreviousDate,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: currentDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Colors.white,
                              onPrimary: Colors.black,
                              surface: Color(0xFF2F3031),
                              onSurface: Colors.white,
                            ),
                            dialogBackgroundColor: const Color(0xFF2F3031),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      setState(() {
                        currentDate = pickedDate;
                        _updateSelectedReservation();
                      });
                    }
                  },
                  child: Center(
                    child: Text(
                      formattedCurrentDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: _nextDay,
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      formattedNextDate,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF2F3031),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: _nextDay,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 45,
              right: 12,
              top: 10,
              bottom: 5,
            ),
            child: Row(
              children: List.generate(9, (index) {
                final hour = 1 + index;
                final label = "$hour PM";
                return SizedBox(
                  width: 85,
                  child: Align(
                    alignment:
                    Alignment.center, // Use Align to center the content
                    child: _buildTimeLabel(label),
                  ),
                );
              }),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.only(left: 45, right: 12),
            child: Row(
              children: List.generate(9, (_) {
                return SizedBox(
                  width: 85,
                  child: Align(
                    alignment: Alignment.center, // Align instead of Center
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
        ),
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
    return Text(
      time,
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTableRow(int tableNumber) {
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
              child: Stack(children: _buildReservationsForTable(tableNumber)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReservationsForTable(int tableNumber) {
    List<Widget> reservationWidgets = [];

    final tableReservations =
    reservations
        .where(
          (res) =>
      res.tableNumber == tableNumber &&
          res.startTime.year == currentDate.year &&
          res.startTime.month == currentDate.month &&
          res.startTime.day == currentDate.day,
    )
        .toList();

    final double timelineStart = 12.75;
    final double pixelsPerHour = 85.0;

    for (double hour = 13; hour <= 21; hour++) {
      final double gridLeft = ((hour - timelineStart) * pixelsPerHour);
      reservationWidgets.add(
        Positioned(
          left: gridLeft,
          top: 0,
          bottom: 0,
          child: Container(width: 1, color: Color(int.parse("0x806A6A6A"))),
        ),
      );
    }

    for (var reservation in tableReservations) {
      final double startHour =
          reservation.startTime.hour + reservation.startTime.minute / 60.0;
      final double endHour =
          reservation.endTime.hour + reservation.endTime.minute / 60.0;

      final double left = double.parse(
        ((startHour - timelineStart) * pixelsPerHour).toStringAsFixed(2),
      );
      final double width = double.parse(
        ((endHour - startHour) * pixelsPerHour).toStringAsFixed(2),
      );

      reservationWidgets.add(
        Positioned(
          left: left,
          width: width,
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
                border:
                selectedReservation?.id == reservation.id
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
            style: TextStyle(color: Colors.white, fontSize: 16),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CustomIcons.group,
                              size: 24,
                              color: Colors.white,
                            ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.table_restaurant_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
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
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    selectedReservation!.seated == true
                        ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Seated',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Waiting',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                      child:
                      selectedReservation!.seated == true
                          ? ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF62CB99),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Finished",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                          : ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Seat",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                        ),
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
