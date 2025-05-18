import 'dart:math'; // For random number generation
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffData {
  final String id;
  final String firstName;
  final String lastName;
  final String initials;

  StaffData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.initials,
  });
}

class StaffDataUploader extends StatefulWidget {
  const StaffDataUploader({Key? key}) : super(key: key);

  @override
  _StaffDataUploaderState createState() => _StaffDataUploaderState();
}

class _StaffDataUploaderState extends State<StaffDataUploader> {
  final _formKey = GlobalKey<FormState>();
  final List<StaffData> _staffList = [];
  bool _isLoading = false;
  bool _isEditing = false;
  int _editingIndex = -1;

  final _idController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _initialsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExistingStaff();
  }

  @override
  void dispose() {
    _idController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _initialsController.dispose();
    super.dispose();
  }

  void _fetchExistingStaff() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final staffSnapshot = await FirebaseFirestore.instance
          .collection('Staff')
          .orderBy('id')
          .get();

      final List<StaffData> fetchedStaff = staffSnapshot.docs.map((doc) {
        final data = doc.data();
        return StaffData(
          id: data['id'] ?? '',
          firstName: data['firstName'] ?? '',
          lastName: data['lastName'] ?? '',
          initials: data['initials'] ?? '',
        );
      }).toList();

      setState(() {
        _staffList
          ..clear()
          ..addAll(fetchedStaff);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error fetching staff data: $e');
    }
  }

  void _resetForm() {
    _idController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _initialsController.clear();
    _isEditing = false;
    _editingIndex = -1;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _generateInitials() {
    if (_firstNameController.text.isNotEmpty && _lastNameController.text.isNotEmpty) {
      final firstInitial = _firstNameController.text[0].toUpperCase();
      final lastInitial = _lastNameController.text[0].toUpperCase();
      setState(() {
        _initialsController.text = firstInitial + lastInitial;
      });
    }
  }

  void _generateRandomId() {
    final random = Random();
    final id = (random.nextInt(900000) + 100000).toString(); // Generates a 6-digit number
    setState(() {
      _idController.text = id;
    });
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final id = _idController.text;
      final firstName = _firstNameController.text;
      final lastName = _lastNameController.text;
      final initials = _initialsController.text;

      final staffData = StaffData(
        id: id,
        firstName: firstName,
        lastName: lastName,
        initials: initials,
      );

      await FirebaseFirestore.instance
          .collection('Staff')
          .doc(id)
          .set({
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'initials': initials,
      });

      if (_isEditing && _editingIndex >= 0 && _editingIndex < _staffList.length) {
        setState(() {
          _staffList[_editingIndex] = staffData;
        });
      } else {
        setState(() {
          _staffList.add(staffData);
          _staffList.sort((a, b) => a.id.compareTo(b.id));
        });
      }

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

  Future<void> _deleteStaff(String id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('Staff')
          .doc(id)
          .delete();

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

  void _editStaff(StaffData staff, int index) {
    setState(() {
      _isEditing = true;
      _editingIndex = index;
      _idController.text = staff.id;
      _firstNameController.text = staff.firstName;
      _lastNameController.text = staff.lastName;
      _initialsController.text = staff.initials;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Staff Member' : 'Add Staff Member'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _resetForm,
              tooltip: 'Cancel Editing',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchExistingStaff,
            tooltip: 'Refresh Staff List',
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
                          _isEditing ? 'Edit Staff Member' : 'Add New Staff Member',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _idController,
                                decoration: const InputDecoration(
                                  labelText: 'ID',
                                  border: OutlineInputBorder(),
                                ),
                                enabled: !_isEditing,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter staff ID';
                                  }
                                  if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                                    return 'ID must be exactly 6 digits';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isEditing ? null : _generateRandomId,
                              child: const Text('Random'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'First Name',
                                  border: OutlineInputBorder(),
                                ),
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
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Last Name',
                                  border: OutlineInputBorder(),
                                ),
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
                        TextFormField(
                          controller: _initialsController,
                          decoration: const InputDecoration(
                            labelText: 'Initials',
                            border: OutlineInputBorder(),
                            helperText: 'Auto-generated from names but can be edited',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter initials';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _saveStaff,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(_isEditing ? 'Update Staff Member' : 'Add Staff Member'),
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
                        'Current Staff',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _staffList.isEmpty
                          ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No staff members yet. Add one above.'),
                        ),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _staffList.length,
                        itemBuilder: (context, index) {
                          final staff = _staffList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(staff.initials),
                              ),
                              title: Text('${staff.firstName} ${staff.lastName}'),
                              subtitle: Text('ID: ${staff.id}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editStaff(staff, index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
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
