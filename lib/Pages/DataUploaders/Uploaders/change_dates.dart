import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../Components/reservation_data.dart';

class ChangeDatesUploader extends StatefulWidget {
  const ChangeDatesUploader({super.key});

  @override
  ChangeDatesUploaderState createState() => ChangeDatesUploaderState();
}

class ChangeDatesUploaderState extends State<ChangeDatesUploader> {
  final List<ReservationData> _reservations = [];
  final Set<int> _selectedReservations = {};
  bool _isLoading = false;
  DateTime? _newStartTime;
  DateTime? _newEndTime;
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  void _fetchReservations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
        .collection('Reservations')
        .orderBy('startTime')
        .get();

      final List<ReservationData> fetchedReservations = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        fetchedReservations.add(
          ReservationData(
            id: data['id'] ?? 0,
            customerName: data['customerName'] ?? '',
            tableNumber: data['tableNumber'] ?? 0,
            startTime: (data['startTime'] as Timestamp).toDate(),
            endTime: (data['endTime'] as Timestamp).toDate(),
            partySize: data['partySize'] ?? 0,
            seated: data['seated'] ?? false,
            isFinished: data['isFinished'] ?? false,
            specialNotes: data['specialNotes'] ?? '',
            color: Colors.grey,
          ),
        );
      }

      setState(() {
        _reservations
          ..clear()
          ..addAll(fetchedReservations);
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar('Error fetching reservations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    if (!isStartTime) return;
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _newStartTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepPurple,
              surface: Color(0xFF2F3031),
            ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF212224)),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.deepPurple,
                surface: Color(0xFF2F3031),
              ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF212224)),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _newStartTime = selectedDateTime;
          _startTimeController.text = DateFormat('MMM dd, yyyy hh:mm a').format(selectedDateTime);

          _newEndTime = selectedDateTime.add(const Duration(hours: 2));
          _endTimeController.text = DateFormat('MMM dd, yyyy hh:mm a').format(_newEndTime!);
        });
      }
    }
  }

  Future<void> _updateReservations() async {
    if (_selectedReservations.isEmpty) {
      _showSnackBar('Please select at least one reservation to update');
      return;
    }

    if (_newStartTime == null || _newEndTime == null) {
      _showSnackBar('Please select both start and end times');
      return;
    }

    if (_newEndTime!.isBefore(_newStartTime!)) {
      _showSnackBar('End time cannot be before start time');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      for (var id in _selectedReservations) {
        await FirebaseFirestore.instance
          .collection('Reservations')
          .doc('reservation_$id')
          .update({
          'startTime': Timestamp.fromDate(_newStartTime!),
          'endTime': Timestamp.fromDate(_newEndTime!),
        });
      }

      _showSnackBar('Reservations updated successfully');
      _selectedReservations.clear();
      _newStartTime = null;
      _newEndTime = null;
      _startTimeController.clear();
      _endTimeController.clear();
      _fetchReservations();
    } catch (e) {
      _showSnackBar('Error updating reservations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212224),
      appBar: AppBar(
        title: const Text(
          'Change Reservation Dates',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2F3031),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchReservations,
            tooltip: 'Refresh Reservations',
          ),
        ],
      ),
      body: _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
          )
        : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: const Color(0xFF2F3031),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New Date and Time',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _startTimeController,
                                readOnly: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'New Start Time',
                                  labelStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_today,
                                        color: Colors.white70),
                                    onPressed: () =>
                                        _selectDateTime(context, true),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _endTimeController,
                                readOnly: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'New End Time',
                                  labelStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_today,
                                      color: Colors.white70),
                                    onPressed: () =>
                                      _selectDateTime(context, false),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${_selectedReservations.length} reservations selected',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedReservations.clear();
                                });
                              },
                              child: const Text(
                                'Clear Selection',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _selectedReservations.isEmpty
                                ? null
                                : _updateReservations,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Update Selected'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: const Color(0xFF2F3031),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Existing Reservations',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _reservations.isEmpty
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No reservations found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _reservations.length,
                            itemBuilder: (context, index) {
                              final reservation = _reservations[index];
                              final isSelected =
                                _selectedReservations.contains(reservation.id);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                color: const Color(0xFF212224),
                                child: CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value ?? false) {
                                        _selectedReservations.add(reservation.id);
                                      } else {
                                        _selectedReservations.remove(reservation.id);
                                      }
                                    });
                                  },
                                  title: Text(
                                    reservation.customerName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Table ${reservation.tableNumber}\n'
                                    'Start: ${DateFormat('MMM dd, yyyy hh:mm a').format(reservation.startTime)}\n'
                                    'End: ${DateFormat('MMM dd, yyyy hh:mm a').format(reservation.endTime)}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  activeColor: Colors.deepPurple,
                                  checkColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
