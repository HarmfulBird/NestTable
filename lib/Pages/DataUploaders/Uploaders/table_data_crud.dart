import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Components/tableview_data.dart';

// TableDataUploader provides a complete CRUD interface
// for managing restaurant table data. It allows users to create, read, update,
// and delete table information including table numbers, capacity, assigned servers,
// status, and current guest count. The widget integrates with Firebase Firestore
// for persistent data storage and real-time updates.
class TableDataUploader extends StatefulWidget {
  const TableDataUploader({super.key});

  @override
  TableDataUploaderState createState() => TableDataUploaderState();
}

class TableDataUploaderState extends State<TableDataUploader> {
  final _formKey = GlobalKey<FormState>();
  final List<TableData> _tables = [];
  bool _isLoading = false;
  bool _isEditing = false;
  int _editingIndex = -1;

  // Text controllers for managing form input fields
  final _tableNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  final _currentGuestsController = TextEditingController();

  // Predefined options for table status dropdown
  final List<String> _statusOptions = ['Open', 'Seated', 'Reserved'];
  String _selectedStatus = 'Open';

  // Staff data fetched from Firestore for server assignment dropdown
  List<Map<String, dynamic>> _staffOptions = [];
  String? _selectedStaffInitials;

  @override
  void initState() {
    super.initState();// Initialize data when widget is first created
    _fetchStaffList(); // Load staff members for server dropdown
    _fetchExistingTables(); // Load existing tables from Firestore
  }

  @override
  void dispose() {
    // Clean up text controllers to prevent memory leaks
    _tableNumberController.dispose();
    _capacityController.dispose();
    _currentGuestsController.dispose();
    super.dispose();
  }

  // Fetches the list of staff members from Firestore to populate the server dropdown
  Future<void> _fetchStaffList() async {
    try {
      // Query the Staff collection in Firestore
      final snapshot =
        await FirebaseFirestore.instance.collection('Staff').get();
      // Convert documents to list of maps for easier processing
      final staffList = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        _staffOptions = staffList;
      });
    } catch (e) {
      // Show error message if staff data fetch fails
      _showSnackBar('Error fetching staff: $e');
    }
  }

  // Loads all existing tables from Firestore and displays them in the UI
  void _fetchExistingTables() async {
    // Show loading indicator while fetching data
    setState(() {
      _isLoading = true;
    });

    try {
      // Query Tables collection, ordered by table number for consistent display
      final tablesnapshot =
        await FirebaseFirestore.instance
          .collection('Tables')
          .orderBy('tableNumber')
          .get();
      // Temporary list to build table data before updating UI
      final List<TableData> fetchedTables = [];

      // Process each table document from Firestore
      for (var doc in tablesnapshot.docs) {
        final data = doc.data();

        // Determine status color based on table status for visual indication
        Color statusColor;
        switch (data['status']) {
          case 'Open':
            statusColor = Colors.green; // Green for available tables
            break;
          case 'Seated':
            statusColor = Colors.red; // Red for occupied tables
            break;
          case 'Reserved':
            statusColor = Colors.orange; // Orange for reserved tables
            break;
          default:
            statusColor = Colors.grey; // Default color for unknown status
        }

        // Create TableData object with data from Firestore, using default values if null
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

      // Update UI with fetched data and hide loading indicator
      setState(() {
        _tables.clear();
        _tables.addAll(fetchedTables);
        _isLoading = false;
      });
    } catch (e) {
      // Hide loading indicator and show error if fetch fails
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error fetching Tables: $e');
    }
  }

  // Clears all form fields and resets the form to its initial state
  void _resetForm() {
    // Clear all text input controllers
    _tableNumberController.clear();
    _capacityController.clear();
    _currentGuestsController.clear();

    // Reset dropdown selections to default values
    _selectedStaffInitials = null;
    _selectedStatus = 'Open';

    // Exit editing mode and reset editing index
    _isEditing = false;
    _editingIndex = -1;
  }

  // Displays a snackbar message to the user
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Saves a new table or updates an existing table in Firestore
  Future<void> _saveTable() async {
    // Validate all form fields before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show loading indicator during save operation
    setState(() {
      _isLoading = true;
    });

    try {
      // Parse form data from text controllers
      final tableNumber = int.parse(_tableNumberController.text);
      final capacity = int.parse(_capacityController.text);
      final assignedServer = _selectedStaffInitials ?? '';
      final status = _selectedStatus;
      final currentGuests = int.parse(_currentGuestsController.text);

      // Determine appropriate status color based on selected status
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

      // Create TableData object with form inputs
      final tableData = TableData(
        tableNumber: tableNumber,
        capacity: capacity,
        assignedServer: assignedServer,
        status: status,
        statusColor: statusColor,
        currentGuests: currentGuests,
      );

      // Save data to Firestore using table number as document ID
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

      // Update local table list based on whether we're editing or adding
      if (_isEditing && _editingIndex >= 0 && _editingIndex < _tables.length) {
        // Update existing table in the list
        setState(() {
          _tables[_editingIndex] = tableData;
        });
      } else {
        // Add new table and sort by table number for consistent ordering
        setState(() {
          _tables.add(tableData);
          _tables.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
        });
      }

      // Reset form and show success message
      _resetForm();
      _showSnackBar('Table saved successfully!');
    } catch (e) {
      // Show error message if save operation fails
      _showSnackBar('Error saving table: $e');
    } finally {
      // Always hide loading indicator when operation completes
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Deletes a table from Firestore and removes it from the local list
  Future<void> _deleteTable(int tableNumber) async {
    // Show loading indicator during delete operation
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete table document from Firestore using table number
      await FirebaseFirestore.instance
        .collection('Tables')
        .doc('table_$tableNumber')
        .delete();

      // Remove table from local list to update UI immediately
      setState(() {
        _tables.removeWhere((table) => table.tableNumber == tableNumber);
      });

      // Show success message to user
      _showSnackBar('Table deleted successfully!');
    } catch (e) {
      // Show error message if deletion fails
      _showSnackBar('Error deleting table: $e');
    } finally {
      // Always hide loading indicator when operation completes
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Populates the form fields with table data for editing
  void _editTable(TableData table, int index) {
    setState(() {
      // Enter editing mode
      _isEditing = true;
      _editingIndex = index;

      // Populate form fields with existing table data
      _tableNumberController.text = table.tableNumber.toString();
      _capacityController.text = table.capacity.toString();
      _selectedStaffInitials = table.assignedServer;
      _selectedStatus = table.status;
      _currentGuestsController.text = table.currentGuests.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Dark theme background color for the entire page
      color: const Color(0xFF212224),
      child:
        _isLoading
          // Show loading spinner while data operations are in progress
          ? const Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
          )
          // Main content when not loading
          : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FORM CARD: Contains the add/edit table form
                  Card(
                    color: const Color(0xFF2F3031),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dynamic title based on editing state
                            Text(
                              _isEditing ? 'Edit Table' : 'Add New Table',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // ROW 1: Table Number and Capacity input fields
                            Row(
                              children: [
                                // Table Number input field
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
                                // Table Capacity input field
                                Expanded(
                                  child: TextFormField(
                                    controller: _capacityController,
                                    decoration: InputDecoration(
                                      labelText: 'Capacity',
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
                                        return 'Please enter capacity';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Server Assignment dropdown, populated with staff data from Firestore
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Assigned Server',
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
                              dropdownColor: const Color(0xFF2F3031),
                              style: const TextStyle(color: Colors.white),
                              value: _selectedStaffInitials,
                              items:
                                // Build dropdown items from staff data
                                _staffOptions.map((staff) {
                                  final fullName =
                                    '${staff['firstName']} ${staff['lastName']} (${staff['initials']})';
                                  return DropdownMenuItem<String>(
                                    value: staff['initials'],
                                    child: Text(
                                      fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
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
                            // ROW 2: Status and Current Guests fields
                            Row(
                              children: [
                                // Table Status dropdown
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Status',
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
                                    dropdownColor: const Color(0xFF2F3031),
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    value: _selectedStatus,
                                    items:
                                      // Build dropdown from predefined status options
                                      _statusOptions
                                        .map(
                                          (status) => DropdownMenuItem(
                                            value: status,
                                            child: Text(
                                              status,
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        )
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
                                // Current Guests input field
                                Expanded(
                                  child: TextFormField(
                                    controller: _currentGuestsController,
                                    decoration: InputDecoration(
                                      labelText: 'Current Guests',
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
                                        return 'Please enter current guests';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Primary action button (Add/Update based on editing state)
                            ElevatedButton(
                              onPressed: _saveTable,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                minimumSize: const Size(
                                  double.infinity,
                                  50,
                                ),
                              ),
                              child: Text(
                                _isEditing ? 'Update Table' : 'Add Table',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            // Cancel button only shown when editing
                            if (_isEditing) ...[
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _resetForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  minimumSize: const Size(
                                    double.infinity,
                                    50,
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // TABLES LIST CARD: Displays all existing tables
                  Card(
                    color: const Color(0xFF2F3031),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Tables',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Conditional rendering: empty state or list of tables
                          _tables.isEmpty
                            // Empty state message when no tables exist
                            ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No tables yet. Add one above.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                            // List view of existing tables
                            : ListView.builder(
                              shrinkWrap:
                                true, // Allows ListView to size itself based on content
                              physics:
                                const NeverScrollableScrollPhysics(), // Prevents inner scrolling
                              itemCount: _tables.length,
                              itemBuilder: (context, index) {
                                final table = _tables[index];
                                return Card(
                                  margin: const EdgeInsets.only(
                                    bottom: 8.0,
                                  ),
                                  color: const Color(0xFF212224),
                                  child: ListTile(
                                    // Table display with number as title
                                    title: Text(
                                      'Table ${table.tableNumber}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // Table details as subtitle
                                    subtitle: Text(
                                      'Capacity: ${table.capacity} | Status: ${table.status} | Server: ${table.assignedServer} | Guests: ${table.currentGuests}',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    // Action buttons: Edit and Delete
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Edit button - populates form with table data
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                          ),
                                          onPressed:
                                            () => _editTable(
                                              table,
                                              index,
                                            ),
                                        ),
                                        // Delete button - removes table from Firestore and UI
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                          onPressed:
                                            () => _deleteTable(
                                              table.tableNumber,
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
