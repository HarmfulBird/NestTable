import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../Components/reservation_data.dart';

// A widget that allows users to select and update the date/time of multiple reservations
// Provides a UI for bulk updating reservation start and end times in Firestore
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
  // Controllers for the date/time input fields
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  // Initialize the widget and load reservations when created
  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  // Clean up resources when widget is disposed
  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  // Fetch all reservations from Firestore and update the list
  void _fetchReservations() async {
    // Show loading indicator while fetching data
    setState(() {
      _isLoading = true;
    });

    try {
      // Query Firestore for all reservations ordered by start time
      final snapshot =
        await FirebaseFirestore.instance
          .collection('Reservations')
          .orderBy('startTime')
          .get();

      // Convert Firestore documents to ReservationData objects
      final List<ReservationData> fetchedReservations = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        fetchedReservations.add(
          ReservationData(
            id: data['id'] ?? 0,
            customerName: data['customerName'] ?? '',
            tableNumber: data['tableNumber'] ?? 0,
            // Convert Firestore Timestamp to DateTime
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

      // Update UI with fetched reservations and hide loading indicator
      setState(() {
        _reservations
          ..clear()
          ..addAll(fetchedReservations);
        _isLoading = false;
      });
    } catch (e) {
      // Show error message if fetch fails
      _showSnackBar('Error fetching reservations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show a snackbar message to the user
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Show date and time picker dialogs for selecting new reservation times
  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    // Only allow selecting start time (end time is automatically calculated)
    if (!isStartTime) return;

    // Show date picker with dark theme
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
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF212224),
            ),
          ),
          child: child!,
        );
      },
    );

    // If date was selected, show time picker
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
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: const Color(0xFF212224),
              ),
            ),
            child: child!,
          );
        },
      );

      // If both date and time were selected, update the controllers and state
      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          // Set new start time and update controller text
          _newStartTime = selectedDateTime;
          _startTimeController.text = DateFormat(
            'MMM dd, yyyy hh:mm a',
          ).format(selectedDateTime);

          // Automatically set end time to 2 hours after start time
          _newEndTime = selectedDateTime.add(const Duration(hours: 2));
          _endTimeController.text = DateFormat(
            'MMM dd, yyyy hh:mm a',
          ).format(_newEndTime!);
        });
      }
    }
  }

  // Update selected reservations with new date and time in Firestore
  Future<void> _updateReservations() async {
    // Validate that at least one reservation is selected
    if (_selectedReservations.isEmpty) {
      _showSnackBar('Please select at least one reservation to update');
      return;
    }

    // Validate that both start and end times are set
    if (_newStartTime == null || _newEndTime == null) {
      _showSnackBar('Please select both start and end times');
      return;
    }

    // Validate that end time is not before start time
    if (_newEndTime!.isBefore(_newStartTime!)) {
      _showSnackBar('End time cannot be before start time');
      return;
    }

    // Show loading indicator during update operation
    setState(() {
      _isLoading = true;
    });

    try {
      // Update each selected reservation in Firestore
      for (var id in _selectedReservations) {
        await FirebaseFirestore.instance
          .collection('Reservations')
          .doc('reservation_$id')
          .update({
            'startTime': Timestamp.fromDate(_newStartTime!),
            'endTime': Timestamp.fromDate(_newEndTime!),
          });
      }

      // Show success message and reset form
      _showSnackBar('Reservations updated successfully');
      _selectedReservations.clear();
      _newStartTime = null;
      _newEndTime = null;
      _startTimeController.clear();
      _endTimeController.clear();
      // Refresh the reservations list to show updated data
      _fetchReservations();
    } catch (e) {
      // Show error message if update fails
      _showSnackBar('Error updating reservations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Build the main UI for the date change uploader
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF212224),
      child:
        _isLoading
          ? const Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
          )
          : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card containing the date/time selection form
                  Card(
                    color: const Color(0xFF2F3031),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title for the date/time selection section
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
                              // Start time input field with calendar icon
                              Expanded(
                                child: TextFormField(
                                  controller: _startTimeController,
                                  readOnly:
                                      true, // Prevent manual text input
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
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
                                    // Calendar icon button to open date/time picker
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.calendar_today,
                                        color: Colors.white70,
                                      ),
                                      onPressed:
                                        () => _selectDateTime(
                                          context,
                                          true,
                                        ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // End time input field (automatically calculated, not directly editable)
                              Expanded(
                                child: TextFormField(
                                  controller: _endTimeController,
                                  readOnly:
                                    true, // Prevent manual text input
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
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
                                    // Calendar icon (disabled for end time)
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.calendar_today,
                                        color: Colors.white70,
                                      ),
                                      onPressed:
                                        () => _selectDateTime(
                                          context,
                                          false,
                                        ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Bottom row with selection counter and action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Display count of selected reservations
                              Text(
                                '${_selectedReservations.length} reservations selected',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const Spacer(),
                              // Button to clear all selections
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
                              // Button to update selected reservations
                              ElevatedButton(
                                onPressed:
                                  _selectedReservations.isEmpty
                                    ? null // Disable if no reservations selected
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
                  // Card containing the list of existing reservations
                  Card(
                    color: const Color(0xFF2F3031),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title for the reservations list section
                          const Text(
                            'Existing Reservations',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Show message if no reservations found, otherwise show list
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
                            // List of reservations with checkboxes for selection
                            : ListView.builder(
                              shrinkWrap:
                                true, // Allow list to size itself
                              physics:
                                const NeverScrollableScrollPhysics(), // Disable scrolling within this list
                              itemCount: _reservations.length,
                              itemBuilder: (context, index) {
                                final reservation = _reservations[index];
                                final isSelected = _selectedReservations
                                  .contains(reservation.id);
                                // Individual reservation item with checkbox
                                return Card(
                                  margin: const EdgeInsets.only(
                                    bottom: 8.0,
                                  ),
                                  color: const Color(0xFF212224),
                                  child: CheckboxListTile(
                                    value: isSelected,
                                    // Toggle selection when checkbox is tapped
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value ?? false) {
                                          _selectedReservations.add(
                                            reservation.id,
                                          );
                                        } else {
                                          _selectedReservations.remove(
                                            reservation.id,
                                          );
                                        }
                                      });
                                    },
                                    // Display customer name as main title
                                    title: Text(
                                      reservation.customerName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // Display table number and current start/end times
                                    subtitle: Text(
                                      'Table ${reservation.tableNumber}\n'
                                      'Start: ${DateFormat('MMM dd, yyyy hh:mm a').format(reservation.startTime)}\n'
                                      'End: ${DateFormat('MMM dd, yyyy hh:mm a').format(reservation.endTime)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
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
