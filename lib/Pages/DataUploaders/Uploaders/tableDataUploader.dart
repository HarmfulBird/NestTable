import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Components/tableviewdata.dart';

class TableDataUploader extends StatefulWidget {
  const TableDataUploader({Key? key}) : super(key: key);

  @override
  _TableDataUploaderState createState() => _TableDataUploaderState();
}

class _TableDataUploaderState extends State<TableDataUploader> {
  final _formKey = GlobalKey<FormState>();
  final List<TableData> _Tables = [];
  bool _isLoading = false;
  bool _isEditing = false;
  int _editingIndex = -1;

  final _tableNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  final _currentGuestsController = TextEditingController();

  final List<String> _statusOptions = ['Open', 'Seated', 'Reserved'];
  String _selectedStatus = 'Open';

  List<Map<String, dynamic>> _staffOptions = [];
  String? _selectedStaffInitials;

  @override
  void initState() {
    super.initState();
    _fetchStaffList();
    _fetchExistingTables();
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _capacityController.dispose();
    _currentGuestsController.dispose();
    super.dispose();
  }

  Future<void> _fetchStaffList() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('Staff').get();
      final staffList = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        _staffOptions = staffList;
      });
    } catch (e) {
      _showSnackBar('Error fetching staff: $e');
    }
  }

  void _fetchExistingTables() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Tablesnapshot = await FirebaseFirestore.instance
          .collection('Tables')
          .orderBy('tableNumber')
          .get();

      final List<TableData> fetchedTables = [];

      for (var doc in Tablesnapshot.docs) {
        final data = doc.data();

        Color statusColor;
        switch (data['status']) {
          case 'Open':
            statusColor = Colors.green;
            break;
          case 'Seated':
            statusColor = Colors.red;
            break;
          case 'Reserved':
            statusColor = Colors.orange;
            break;
          default:
            statusColor = Colors.grey;
        }

        fetchedTables.add(
          TableData(
            tableNumber: data['tableNumber'] ?? 0,
            capacity: data['capacity'] ?? 4,
            assignedServer: data['assignedServer'] ?? '',
            status: data['status'] ?? 'Open',
            statusColor: statusColor,
            currentGuests: data['currentGuests'] ?? 0,
          ),
        );
      }

      setState(() {
        _Tables.clear();
        _Tables.addAll(fetchedTables);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error fetching Tables: $e');
    }
  }

  void _resetForm() {
    _tableNumberController.clear();
    _capacityController.clear();
    _currentGuestsController.clear();
    _selectedStaffInitials = null;
    _selectedStatus = 'Open';
    _isEditing = false;
    _editingIndex = -1;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveTable() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tableNumber = int.parse(_tableNumberController.text);
      final capacity = int.parse(_capacityController.text);
      final assignedServer = _selectedStaffInitials ?? '';
      final status = _selectedStatus;
      final currentGuests = int.parse(_currentGuestsController.text);

      Color statusColor;
      switch (status) {
        case 'Open':
          statusColor = Colors.green;
          break;
        case 'Seated':
          statusColor = Colors.red;
          break;
        case 'Reserved':
          statusColor = Colors.orange;
          break;
        default:
          statusColor = Colors.grey;
      }

      final tableData = TableData(
        tableNumber: tableNumber,
        capacity: capacity,
        assignedServer: assignedServer,
        status: status,
        statusColor: statusColor,
        currentGuests: currentGuests,
      );

      await FirebaseFirestore.instance
          .collection('Tables')
          .doc('table_$tableNumber')
          .set({
        'tableNumber': tableNumber,
        'capacity': capacity,
        'assignedServer': assignedServer,
        'status': status,
        'currentGuests': currentGuests,
      });

      if (_isEditing && _editingIndex >= 0 && _editingIndex < _Tables.length) {
        setState(() {
          _Tables[_editingIndex] = tableData;
        });
      } else {
        setState(() {
          _Tables.add(tableData);
          _Tables.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
        });
      }

      _resetForm();
      _showSnackBar('Table saved successfully!');
    } catch (e) {
      _showSnackBar('Error saving table: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTable(int tableNumber) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('Tables')
          .doc('table_$tableNumber')
          .delete();

      setState(() {
        _Tables.removeWhere((table) => table.tableNumber == tableNumber);
      });

      _showSnackBar('Table deleted successfully!');
    } catch (e) {
      _showSnackBar('Error deleting table: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editTable(TableData table, int index) {
    setState(() {
      _isEditing = true;
      _editingIndex = index;
      _tableNumberController.text = table.tableNumber.toString();
      _capacityController.text = table.capacity.toString();
      _selectedStaffInitials = table.assignedServer;
      _selectedStatus = table.status;
      _currentGuestsController.text = table.currentGuests.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Table' : 'Add Table Data'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _resetForm,
              tooltip: 'Cancel Editing',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchExistingTables,
            tooltip: 'Refresh Tables',
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
                          _isEditing ? 'Edit Table' : 'Add New Table',
                          style: Theme.of(context).textTheme.headlineSmall,
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
                                enabled: !_isEditing,
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
                                controller: _capacityController,
                                decoration: const InputDecoration(
                                  labelText: 'Capacity',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter capacity';
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
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Assigned Server',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedStaffInitials,
                          items: _staffOptions.map((staff) {
                            final fullName = '${staff['firstName']} ${staff['lastName']} (${staff['initials']})';
                            return DropdownMenuItem<String>(
                              value: staff['initials'],
                              child: Text(fullName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStaffInitials = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a server';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedStatus,
                                items: _statusOptions
                                    .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedStatus = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _currentGuestsController,
                                decoration: const InputDecoration(
                                  labelText: 'Current Guests',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter current guests';
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
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _saveTable,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(_isEditing ? 'Update Table' : 'Add Table'),
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
                        'Current Tables',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _Tables.isEmpty
                          ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No Tables yet. Add one above.'),
                        ),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _Tables.length,
                        itemBuilder: (context, index) {
                          final table = _Tables[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              title: Text('Table ${table.tableNumber}'),
                              subtitle: Text(
                                  'Capacity: ${table.capacity} | Status: ${table.status} | Server: ${table.assignedServer} | Guests: ${table.currentGuests}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editTable(table, index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteTable(table.tableNumber),
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
