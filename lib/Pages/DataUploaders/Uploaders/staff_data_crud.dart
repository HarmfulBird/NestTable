import 'dart:math'; // For random number generation
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Data model class to represent a staff member
class StaffData {
  final String id;
  final String firstName;
  final String lastName;
  final String initials;
  final String role;
  final String defaultView;

  StaffData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.initials,
    required this.role,
    this.defaultView = 'Tables',
  });
}

// Main widget for managing staff data - allows CRUD operations
class StaffDataUploader extends StatefulWidget {
  const StaffDataUploader({super.key});

  @override
  StaffDataUploaderState createState() => StaffDataUploaderState();
}

class StaffDataUploaderState extends State<StaffDataUploader> {
  // Form validation key
  final _formKey = GlobalKey<FormState>();
  // Local list to store staff data for display
  final List<StaffData> _staffList = [];
  // Loading state to show progress indicators
  bool _isLoading = false;
  // Track if we're editing an existing staff member
  bool _isEditing = false;
  // Index of the staff member being edited
  int _editingIndex = -1;

  // Text controllers for form input fields
  final _idController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _initialsController = TextEditingController();

  // Available role options for dropdown
  final List<String> _roleOptions = ['User', 'Manager'];
  // Currently selected role
  String _selectedRole = 'User';

  // Initialize the widget and load existing staff data
  @override
  void initState() {
    super.initState();
    _fetchExistingStaff();
  }

  // Clean up text controllers when widget is destroyed
  @override
  void dispose() {
    _idController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _initialsController.dispose();
    super.dispose();
  }

  // Load all staff members from Firebase and display them
  void _fetchExistingStaff() async {
    // Set loading state to show spinner
    setState(() {
      _isLoading = true;
    });

    try {
      // Query Firebase for all staff documents, ordered by ID
      final staffSnapshot =
          await FirebaseFirestore.instance
              .collection('Staff')
              .orderBy('id')
              .get();

      // Convert Firestore documents to StaffData objects
      final List<StaffData> fetchedStaff =
          staffSnapshot.docs.map((doc) {
            final data = doc.data();
            // Validate and default the role field
            String userRole = (data['role'] as String?) ?? 'User';
            if (userRole.isEmpty || !['User', 'Manager'].contains(userRole)) {
              userRole = 'User';
            }
            return StaffData(
              id: data['id'] ?? '',
              firstName: data['firstName'] ?? '',
              lastName: data['lastName'] ?? '',
              initials: data['initials'] ?? '',
              role: userRole,
              defaultView: data['defaultView'] ?? 'Tables',
            );
          }).toList();

      // Update UI with fetched data
      setState(() {
        _staffList
          ..clear()
          ..addAll(fetchedStaff);
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors during data fetching
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error fetching staff data: $e');
    }
  }

  // Clear all form fields and reset editing state
  void _resetForm() {
    _idController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _initialsController.clear();
    _selectedRole = 'User';
    _isEditing = false;
    _editingIndex = -1;
  }

  // Display a message to the user at the bottom of the screen
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Automatically create initials from first and last name
  void _generateInitials() {
    // Only generate if both names are provided
    if (_firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty) {
      final firstInitial = _firstNameController.text[0].toUpperCase();
      final lastInitial = _lastNameController.text[0].toUpperCase();
      setState(() {
        _initialsController.text = firstInitial + lastInitial;
      });
    }
  }

  // Create a random 6-digit ID number
  void _generateRandomId() {
    final random = Random();
    // Generate number between 100000 and 999999
    final id = (random.nextInt(900000) + 100000).toString();
    setState(() {
      _idController.text = id;
    });
  }

  // Save a new staff member or update an existing one to Firebase
  Future<void> _saveStaff() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get values from form controllers
      final id = _idController.text;
      final firstName = _firstNameController.text;
      final lastName = _lastNameController.text;
      final initials = _initialsController.text;

      // Create StaffData object
      final staffData = StaffData(
        id: id,
        firstName: firstName,
        lastName: lastName,
        initials: initials,
        role: _selectedRole,
        defaultView: 'Tables', // Default view for new users
      );

      // Save to Firebase using document ID as the staff ID
      await FirebaseFirestore.instance.collection('Staff').doc(id).set(
        {
          'id': id,
          'firstName': firstName,
          'lastName': lastName,
          'initials': initials,
          'role': _selectedRole,
          'defaultView':
              _isEditing ? null : 'Tables', // Only set default for new users
        },
        SetOptions(merge: true),
      ); // Use merge to preserve existing defaultView for updates

      // Update local list based on whether we're editing or adding
      if (_isEditing &&
          _editingIndex >= 0 &&
          _editingIndex < _staffList.length) {
        // Update existing staff member
        setState(() {
          _staffList[_editingIndex] = staffData;
        });
      } else {
        // Add new staff member and sort by ID
        setState(() {
          _staffList.add(staffData);
          _staffList.sort((a, b) => a.id.compareTo(b.id));
        });
      }

      // Clear form and show success message
      _resetForm();
      _showSnackBar('Staff member saved successfully!');
    } catch (e) {
      _showSnackBar('Error saving staff member: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Remove a staff member from Firebase and the local list
  Future<void> _deleteStaff(String id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete from Firebase
      await FirebaseFirestore.instance.collection('Staff').doc(id).delete();

      // Remove from local list
      setState(() {
        _staffList.removeWhere((staff) => staff.id == id);
      });

      _showSnackBar('Staff member deleted successfully!');
    } catch (e) {
      _showSnackBar('Error deleting staff member: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load staff data into the form for editing
  void _editStaff(StaffData staff, int index) {
    setState(() {
      _isEditing = true;
      _editingIndex = index;
      // Populate form fields with existing data
      _idController.text = staff.id;
      _firstNameController.text = staff.firstName;
      _lastNameController.text = staff.lastName;
      _initialsController.text = staff.initials;
      _selectedRole = staff.role;
    });
  }

  // Build the user interface for the staff data uploader page
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF212224),
      child:
        _isLoading
          ? // Show loading spinner when data is being processed
          const Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
          )
          : // Main content when not loading
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form card for adding/editing staff
                  Card(
                    color: const Color(0xFF2F3031),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dynamic title based on edit mode
                            Text(
                              _isEditing
                                ? 'Edit Staff Member'
                                : 'Add New Staff Member',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Row for ID field with random generator and role dropdown
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      // ID input field
                                      Expanded(
                                        child: TextFormField(
                                          controller: _idController,
                                          decoration: InputDecoration(
                                            labelText: 'ID',
                                            labelStyle: TextStyle(
                                              color: Colors.grey.shade400,
                                            ),
                                            enabledBorder:
                                                OutlineInputBorder(
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
                                          // Disable editing when updating existing staff
                                          enabled: !_isEditing,
                                          keyboardType:
                                              TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter staff ID';
                                            }
                                            // Validate 6-digit format
                                            if (!RegExp(
                                              r'^\d{6}$',
                                            ).hasMatch(value)) {
                                              return 'ID must be exactly 6 digits';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Random ID generator button
                                      ElevatedButton(
                                        onPressed:
                                          _isEditing
                                            ? null
                                            : _generateRandomId,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                          disabledBackgroundColor: Colors.grey,
                                        ),
                                        child: const Text(
                                          'Random',
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Role dropdown
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Role',
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
                                    value: _selectedRole,
                                    items:
                                      _roleOptions
                                        .map(
                                          (role,) => DropdownMenuItem<String>(
                                            value: role,
                                            child: Text(
                                              role,
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedRole = value;
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select a role';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Row for first and last name fields
                            Row(
                              children: [
                                // First name field
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: InputDecoration(
                                      labelText: 'First Name',
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
                                    // Auto-generate initials when typing
                                    onChanged: (_) => _generateInitials(),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter first name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Last name field
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Last Name',
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
                                    // Auto-generate initials when typing
                                    onChanged: (_) => _generateInitials(),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter last name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Initials field with auto-generation info
                            TextFormField(
                              controller: _initialsController,
                              decoration: InputDecoration(
                                labelText: 'Initials',
                                labelStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                helperText: 'Auto-generated from names but can be edited',
                                helperStyle: TextStyle(
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
                                  return 'Please enter initials';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            // Submit button with dynamic text
                            ElevatedButton(
                              onPressed: _saveStaff,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                minimumSize: const Size(
                                  double.infinity,
                                  50,
                                ),
                              ),
                              child: Text(
                                _isEditing
                                  ? 'Update Staff Member'
                                  : 'Add Staff Member',
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
                  // Card displaying list of current staff members
                  Card(
                    color: const Color(0xFF2F3031),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Staff',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _staffList.isEmpty ? // Show message when no staff members exist
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No staff members yet. Add one above.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                            : // Build list of staff member cards
                            ListView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: _staffList.length,
                              itemBuilder: (context, index) {
                                final staff = _staffList[index];
                                return Card(
                                  margin: const EdgeInsets.only(
                                    bottom: 8.0,
                                  ),
                                  color: const Color(0xFF212224),
                                  child: ListTile(
                                    // Avatar showing staff initials
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.deepPurple,
                                      child: Text(
                                        staff.initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    // Staff member name
                                    title: Text(
                                      '${staff.firstName} ${staff.lastName}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // Staff ID and role information
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ID: ${staff.id}',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        Text(
                                          'Role: ${staff.role}',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Edit and delete action buttons
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
                                            () => _editStaff(
                                              staff,
                                              index,
                                            ),
                                        ),
                                        // Delete button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                          onPressed: () => _deleteStaff(staff.id),
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
