import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Components/reservation_data.dart';

// A stateful widget that provides a complete CRUD interface for restaurant reservations
// This widget allows users to create, read, update, and delete reservation data
// stored in Firebase Firestore
class ReservationDataUploader extends StatefulWidget {
  const ReservationDataUploader({super.key});

  @override
  ReservationDataUploaderState createState() => ReservationDataUploaderState();
}

// State class that manages the reservation CRUD operations and UI components
class ReservationDataUploaderState extends State<ReservationDataUploader> {
  final _formKey = GlobalKey<FormState>();
  final List<ReservationData> _reservations = [];
  bool _isLoading = false;
  bool _isEditing = false;
  int _editingIndex = -1;

  // Text controllers for form input fields
  final _customerNameController = TextEditingController();
  final _tableNumberController = TextEditingController();
  final _partySizeController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _specialNotesController = TextEditingController();

  // Selected datetime objects for reservation timing
  DateTime? _selectedStartTime;
  DateTime? _selectedEndTime;

  // Initializes the widget and loads existing reservations from Firebase
  @override
  void initState() {
    super.initState();
    _fetchExistingReservations();
  }

  // Cleans up text controllers when the widget is destroyed
  @override
  void dispose() {
    _customerNameController.dispose();
    _tableNumberController.dispose();
    _partySizeController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _specialNotesController.dispose();
    super.dispose();
  }

  // Fetches all existing reservations from Firebase and displays them
  void _fetchExistingReservations() async {
    // Set loading state to show progress indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Query Firebase Firestore for all reservations, ordered by start time
      final snapshot =
        await FirebaseFirestore.instance
          .collection('Reservations')
          .orderBy('startTime')
          .get();

      final List<ReservationData> fetchedReservations = [];

      // Convert Firestore documents to ReservationData objects
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
            color: Colors.purple.shade400,
            specialNotes: data['specialNotes'] ?? '',
          ),
        );
      }

      // Update the UI with fetched reservations
      setState(() {
        _reservations.clear();
        _reservations.addAll(fetchedReservations);
        _isLoading = false;
      });
    } catch (e) {
      // Handle any errors during the fetch operation
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error fetching reservations: $e');
    }
  }

  // Clears all form fields and resets editing state
  void _resetForm() {
    // Clear all text input controllers
    _customerNameController.clear();
    _tableNumberController.clear();
    _partySizeController.clear();
    _startTimeController.clear();
    _endTimeController.clear();
    _specialNotesController.clear();
    // Reset datetime selections
    _selectedStartTime = null;
    _selectedEndTime = null;
    // Reset editing state flags
    _isEditing = false;
    _editingIndex = -1;
  }

  // Shows a snackbar message to the user
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Opens date and time pickers for selecting reservation start time
  Future<void> _selectStartTime() async {
    // Show date picker first
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedStartTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      // If date is selected, show time picker
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedStartTime ?? DateTime.now(),
        ),
      );

      if (time != null) {
        // Combine date and time, auto-set end time to 2 hours later
        setState(() {
          _selectedStartTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _selectedEndTime = _selectedStartTime!.add(const Duration(hours: 2));
          _startTimeController.text = _formatDateTime(_selectedStartTime!);
          _endTimeController.text = _formatDateTime(_selectedEndTime!);
        });
      }
    }
  }

  // Opens date and time pickers for selecting reservation end time
  Future<void> _selectEndTime() async {
    // Ensure start time is selected first
    if (_selectedStartTime == null) {
      _showSnackBar('Please select a start time first');
      return;
    }

    // Show date picker with start time as minimum date
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate:
          _selectedEndTime ?? _selectedStartTime!.add(const Duration(hours: 2)),
      firstDate: _selectedStartTime!,
      lastDate: _selectedStartTime!.add(const Duration(days: 1)),
    );

    if (date != null) {
      // Show time picker for the selected date
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedEndTime ?? _selectedStartTime!.add(const Duration(hours: 2)),
        ),
      );

      if (time != null) {
        // Combine date and time
        final newEndTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        // Validate that end time is after start time
        if (newEndTime.isBefore(_selectedStartTime!)) {
          _showSnackBar('End time cannot be before start time');
          return;
        }

        // Update the end time
        setState(() {
          _selectedEndTime = newEndTime;
          _endTimeController.text = _formatDateTime(_selectedEndTime!);
        });
      }
    }
  }

  // Formats a DateTime object to a readable string format
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Validates form data and saves reservation to Firebase
  Future<void> _saveReservation() async {
    // Validate all form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Ensure both start and end times are selected
    if (_selectedStartTime == null || _selectedEndTime == null) {
      _showSnackBar('Please select both start and end times');
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Generate unique ID based on timestamp or use existing ID for editing
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final id =
        _isEditing
          ? int.parse(_reservations[_editingIndex].id.toString())
          : timestamp;

      // Create reservation data object
      final reservationData = ReservationData(
        id: id,
        customerName: _customerNameController.text,
        tableNumber: int.parse(_tableNumberController.text),
        startTime: _selectedStartTime!,
        endTime: _selectedEndTime!,
        partySize: int.parse(_partySizeController.text),
        seated: false,
        isFinished: false,
        color: Colors.purple.shade400,
        specialNotes: _specialNotesController.text,
      );

      // Save to Firebase Firestore
      await FirebaseFirestore.instance
          .collection('Reservations')
          .doc('reservation_$id')
          .set({
            'id': id,
            'customerName': _customerNameController.text,
            'tableNumber': int.parse(_tableNumberController.text),
            'startTime': Timestamp.fromDate(_selectedStartTime!),
            'endTime': Timestamp.fromDate(_selectedEndTime!),
            'partySize': int.parse(_partySizeController.text),
            'seated': false,
            'isFinished': false,
            'specialNotes': _specialNotesController.text,
          });

      // Update local list based on edit or add mode
      if (_isEditing &&
          _editingIndex >= 0 &&
          _editingIndex < _reservations.length) {
        setState(() {
          _reservations[_editingIndex] = reservationData;
        });
      } else {
        // Add new reservation and sort by start time
        setState(() {
          _reservations.add(reservationData);
          _reservations.sort((a, b) => a.startTime.compareTo(b.startTime));
        });
      }

      // Reset form and show success message
      _resetForm();
      _showSnackBar('Reservation saved successfully!');
    } catch (e) {
      // Handle save errors
      _showSnackBar('Error saving reservation: $e');
    } finally {
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Deletes a reservation from Firebase and removes it from the list
  Future<void> _deleteReservation(int id) async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete from Firebase Firestore
      await FirebaseFirestore.instance
        .collection('Reservations')
        .doc('reservation_$id')
        .delete();

      // Remove from local list
      setState(() {
        _reservations.removeWhere((reservation) => reservation.id == id);
      });

      _showSnackBar('Reservation deleted successfully!');
    } catch (e) {
      // Handle delete errors
      _showSnackBar('Error deleting reservation: $e');
    } finally {
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fills the form with existing reservation data for editing
  void _editReservation(ReservationData reservation, int index) {
    setState(() {
      // Set editing mode flags
      _isEditing = true;
      _editingIndex = index;
      // Populate form fields with existing data
      _customerNameController.text = reservation.customerName;
      _tableNumberController.text = reservation.tableNumber.toString();
      _partySizeController.text = reservation.partySize.toString();
      _selectedStartTime = reservation.startTime;
      _selectedEndTime = reservation.endTime;
      _startTimeController.text = _formatDateTime(reservation.startTime);
      _endTimeController.text = _formatDateTime(reservation.endTime);
      _specialNotesController.text = reservation.specialNotes;
    });
  }

  // Builds the user interface with form for adding/editing reservations and list of existing ones
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF212224),
      // Show loading indicator or main content
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
                  // Form card for adding/editing reservations
                  Card(
                    color: const Color(0xFF2F3031),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dynamic title based on edit/add mode
                            Text(
                              _isEditing
                                ? 'Edit Reservation'
                                : 'Add New Reservation',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Customer name input field
                            TextFormField(
                              controller: _customerNameController,
                              decoration: InputDecoration(
                                labelText: 'Customer Name',
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
                              ),
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter customer name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Row containing start and end time pickers
                            Row(
                              children: [
                                // Start time picker field
                                Expanded(
                                  child: TextFormField(
                                    controller: _startTimeController,
                                    decoration: InputDecoration(
                                      labelText: 'Start Time',
                                      labelStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      focusedBorder:
                                        const OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                      suffixIcon: IconButton(
                                        icon: const Icon(
                                          Icons.calendar_today,
                                          color: Colors.white,
                                        ),
                                        onPressed: _selectStartTime,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    readOnly: true,
                                    onTap: _selectStartTime,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // End time picker field
                                Expanded(
                                  child: TextFormField(
                                    controller: _endTimeController,
                                    decoration: InputDecoration(
                                      labelText: 'End Time',
                                      labelStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      focusedBorder:
                                        const OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                      suffixIcon: IconButton(
                                        icon: const Icon(
                                          Icons.calendar_today,
                                          color: Colors.white,
                                        ),
                                        onPressed: _selectEndTime,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    readOnly: true,
                                    onTap: _selectEndTime,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Row containing table number and party size inputs
                            Row(
                              children: [
                                // Table number input field
                                Expanded(
                                  child: TextFormField(
                                    controller: _tableNumberController,
                                    decoration: InputDecoration(
                                      labelText: 'Table Number',
                                      labelStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      focusedBorder:
                                        const OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter table number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Party size input field
                                Expanded(
                                  child: TextFormField(
                                    controller: _partySizeController,
                                    decoration: InputDecoration(
                                      labelText: 'Party Size',
                                      labelStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      focusedBorder:
                                        const OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter party size';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Special notes multiline input field
                            TextFormField(
                              controller: _specialNotesController,
                              decoration: InputDecoration(
                                labelText: 'Special Notes',
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
                              ),
                              style: const TextStyle(color: Colors.white),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),
                            // Submit button with dynamic text
                            ElevatedButton(
                              onPressed: _saveReservation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                minimumSize: const Size(
                                  double.infinity,
                                  50,
                                ),
                              ),
                              child: Text(
                                _isEditing
                                  ? 'Update Reservation'
                                  : 'Add Reservation',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Card displaying list of current reservations
                  Card(
                    color: const Color(0xFF2F3031),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // List title
                          const Text(
                            'Current Reservations',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Show empty state or reservation list
                          _reservations.isEmpty
                            ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No reservations yet. Add one above.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              physics:
                                const NeverScrollableScrollPhysics(),
                              itemCount: _reservations.length,
                              itemBuilder: (context, index) {
                                final reservation = _reservations[index];
                                // Individual reservation list item
                                return Card(
                                  margin: const EdgeInsets.only(
                                    bottom: 8.0,
                                  ),
                                  color: const Color(0xFF212224),
                                  child: ListTile(
                                    title: Text(
                                      reservation.customerName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Table: ${reservation.tableNumber} | Party: ${reservation.partySize} | ${_formatDateTime(reservation.startTime)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    // Action buttons for edit and delete
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Edit button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                          ),
                                          onPressed:
                                            () => _editReservation(
                                              reservation,
                                              index,
                                            ),
                                        ),
                                        // Delete button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                          onPressed:
                                            () => _deleteReservation(
                                              reservation.id,
                                            ),
                                        ),
                                      ],
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
