import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Components/reservationdata.dart';

class ReservationDataUploader extends StatefulWidget {
  const ReservationDataUploader({Key? key}) : super(key: key);

  @override
  _ReservationDataUploaderState createState() => _ReservationDataUploaderState();
}

class _ReservationDataUploaderState extends State<ReservationDataUploader> {
  final _formKey = GlobalKey<FormState>();
  final List<ReservationData> _reservations = [];
  bool _isLoading = false;
  bool _isEditing = false;
  int _editingIndex = -1;

  // Remove _idController since we'll auto-generate IDs
  final _customerNameController = TextEditingController();
  final _tableNumberController = TextEditingController();
  final _partySizeController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  
  DateTime? _selectedStartTime;
  DateTime? _selectedEndTime;

  @override
  void initState() {
    super.initState();
    _fetchExistingReservations();
  }

  @override
  void dispose() {
    // Remove _idController.dispose()
    _customerNameController.dispose();
    _tableNumberController.dispose();
    _partySizeController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  void _fetchExistingReservations() async {
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
            color: Colors.purple.shade400,
          ),
        );
      }

      setState(() {
        _reservations.clear();
        _reservations.addAll(fetchedReservations);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error fetching reservations: $e');
    }
  }

  void _resetForm() {
    // Remove _idController.clear()
    _customerNameController.clear();
    _tableNumberController.clear();
    _partySizeController.clear();
    _startTimeController.clear();
    _endTimeController.clear();
    _selectedStartTime = null;
    _selectedEndTime = null;
    _isEditing = false;
    _editingIndex = -1;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _selectStartTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedStartTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedStartTime ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _selectedStartTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          // Auto-calculate end time as 2 hours after start time
          _selectedEndTime = _selectedStartTime!.add(const Duration(hours: 2));
          _startTimeController.text = _formatDateTime(_selectedStartTime!);
          _endTimeController.text = _formatDateTime(_selectedEndTime!);
        });
      }
    }
  }

  Future<void> _selectEndTime() async {
    if (_selectedStartTime == null) {
      _showSnackBar('Please select a start time first');
      return;
    }

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedEndTime ?? _selectedStartTime!.add(const Duration(hours: 2)),
      firstDate: _selectedStartTime!,
      lastDate: _selectedStartTime!.add(const Duration(days: 1)),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedEndTime ?? _selectedStartTime!.add(const Duration(hours: 2))),
      );

      if (time != null) {
        final newEndTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        if (newEndTime.isBefore(_selectedStartTime!)) {
          _showSnackBar('End time cannot be before start time');
          return;
        }

        setState(() {
          _selectedEndTime = newEndTime;
          _endTimeController.text = _formatDateTime(_selectedEndTime!);
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveReservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStartTime == null || _selectedEndTime == null) {
      _showSnackBar('Please select both start and end times');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate a unique ID using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final id = _isEditing ? int.parse(_reservations[_editingIndex].id.toString()) : timestamp;

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
      );

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
      });

      if (_isEditing && _editingIndex >= 0 && _editingIndex < _reservations.length) {
        setState(() {
          _reservations[_editingIndex] = reservationData;
        });
      } else {
        setState(() {
          _reservations.add(reservationData);
          _reservations.sort((a, b) => a.startTime.compareTo(b.startTime));
        });
      }

      _resetForm();
      _showSnackBar('Reservation saved successfully!');
    } catch (e) {
      _showSnackBar('Error saving reservation: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReservation(int id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('Reservations')
          .doc('reservation_$id')
          .delete();

      setState(() {
        _reservations.removeWhere((reservation) => reservation.id == id);
      });

      _showSnackBar('Reservation deleted successfully!');
    } catch (e) {
      _showSnackBar('Error deleting reservation: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editReservation(ReservationData reservation, int index) {
    setState(() {
      _isEditing = true;
      _editingIndex = index;
      _customerNameController.text = reservation.customerName;
      _tableNumberController.text = reservation.tableNumber.toString();
      _partySizeController.text = reservation.partySize.toString();
      _selectedStartTime = reservation.startTime;
      _selectedEndTime = reservation.endTime;
      _startTimeController.text = _formatDateTime(reservation.startTime);
      _endTimeController.text = _formatDateTime(reservation.endTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Reservation' : 'Add Reservation'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _resetForm,
              tooltip: 'Cancel Editing',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchExistingReservations,
            tooltip: 'Refresh Reservations',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEditing ? 'Edit Reservation' : 'Add New Reservation',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _customerNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Customer Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter customer name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _tableNumberController,
                                      decoration: const InputDecoration(
                                        labelText: 'Table Number',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter table number';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Please enter a valid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _partySizeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Party Size',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter party size';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Please enter a valid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _startTimeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Start Time',
                                        border: OutlineInputBorder(),
                                      ),
                                      readOnly: true,
                                      onTap: _selectStartTime,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select start time';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _endTimeController,
                                      decoration: const InputDecoration(
                                        labelText: 'End Time',
                                        border: OutlineInputBorder(),
                                      ),
                                      readOnly: true,
                                      onTap: _selectEndTime,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select end time';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _saveReservation,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: Text(_isEditing ? 'Update Reservation' : 'Add Reservation'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Reservations',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            _reservations.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text('No reservations yet. Add one above.'),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _reservations.length,
                                    itemBuilder: (context, index) {
                                      final reservation = _reservations[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8.0),
                                        child: ListTile(
                                          title: Text(reservation.customerName),
                                          subtitle: Text(
                                              'Table: ${reservation.tableNumber} | Party: ${reservation.partySize} | Start: ${_formatDateTime(reservation.startTime)} | End: ${_formatDateTime(reservation.endTime)}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () => _editReservation(reservation, index),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                onPressed: () => _deleteReservation(reservation.id),
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
