import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Services/role_service.dart';
import '../Components/datetime.dart';
import 'dart:math';

// Main page for managing server assignments and table allocations
// Shows tables assigned to current user and allows managers to reassign tables and create new users
class ServersPage extends StatefulWidget {
  const ServersPage({super.key});

  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {
  bool isManager = false;
  bool isLoading = true;
  String currentUserInitials = '';
  List<Map<String, dynamic>> allStaff = [];
  List<Map<String, dynamic>> allTables = [];

  bool showCreateUserOverlay = false;
  int selectedTabIndex = 0;
  final _createUserFormKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _initialsController = TextEditingController();
  String _selectedRole = 'User';
  final List<String> _roleOptions = ['User', 'Manager'];

  late Stream<QuerySnapshot> _staffStream;
  late Stream<QuerySnapshot> _tablesStream;
  @override
  void initState() {
    super.initState();
    // Initialize Firebase streams and load user data
    _initializeStreams();
    _initializeData();
  }

  @override
  void dispose() {
    // Clean up text controllers to prevent memory leaks
    _idController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _initialsController.dispose();
    super.dispose();
  }

  // Initialize Firebase Firestore streams for real-time data updates
  void _initializeStreams() {
    // Stream for staff data ordered by first name
    _staffStream =
        FirebaseFirestore.instance
            .collection('Staff')
            .orderBy('firstName')
            .snapshots();

    // Stream for table data ordered by table number
    _tablesStream =
        FirebaseFirestore.instance
            .collection('Tables')
            .orderBy('tableNumber')
            .snapshots();

    // Stream for reservation data (used for table status checking)
  }

  // Initialize user data and check manager permissions
  Future<void> _initializeData() async {
    try {
      // Check if current user has manager privileges
      bool managerStatus = await RoleService.isManager();

      // Get current user's initials from their staff record
      String? username = RoleService.getCurrentUsername();
      String userInitials = '';
      if (username != null) {
        var staffQuery =
            await FirebaseFirestore.instance
                .collection('Staff')
                .where('id', isEqualTo: username)
                .get();
        if (staffQuery.docs.isNotEmpty) {
          userInitials = staffQuery.docs.first.data()['initials'] ?? '';
        }
      }
      setState(() {
        isManager = managerStatus;
        currentUserInitials = userInitials;
        isLoading = false;
      });

      // Start listening to real-time data streams
      _listenToDataStreams();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error initializing: $e');
    }
  }

  // Set up listeners for real-time Firebase data streams
  void _listenToDataStreams() {
    // Listen to staff collection changes and update local staff list
    _staffStream.listen((staffSnapshot) {
      final staffList =
          staffSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': data['id'] ?? '',
              'firstName': data['firstName'] ?? '',
              'lastName': data['lastName'] ?? '',
              'initials': data['initials'] ?? '',
              'role': data['role'] ?? 'User',
            };
          }).toList();

      if (mounted) {
        setState(() {
          allStaff = staffList;
        });
      }
    });

    // Listen to table collection changes and process with reservation data
    _tablesStream.listen((tablesSnapshot) async {
      await _processTablesWithReservations(tablesSnapshot);
    });
  }

  // Process table data and merge with current reservation information
  // This method calculates current guest count based on reservation status
  Future<void> _processTablesWithReservations(
    QuerySnapshot tablesSnapshot,
  ) async {
    try {
      final tablesList = <Map<String, dynamic>>[];
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      for (var doc in tablesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final tableNumber = data['tableNumber'] ?? 0;
        final status = data['status'] ?? 'Open';
        int currentGuests = 0;

        // For reserved/seated tables, get guest count from active reservations
        if (status == 'Reserved' || status == 'Seated') {
          final reservationSnapshot =
              await FirebaseFirestore.instance
                  .collection('Reservations')
                  .where('tableNumber', isEqualTo: tableNumber)
                  .where(
                    'startTime',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
                  )
                  .where(
                    'startTime',
                    isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
                  )
                  .orderBy('startTime', descending: true)
                  .limit(1)
                  .get();

          if (reservationSnapshot.docs.isNotEmpty) {
            final reservationData = reservationSnapshot.docs.first.data();
            final isSeated = reservationData['seated'] ?? false;
            final isFinished = reservationData['isFinished'] ?? false;
            final partySize = reservationData['partySize'] ?? 0;

            // Only count guests if reservation is active and not finished
            if ((status == 'Seated' && isSeated && !isFinished) ||
                (status == 'Reserved' && !isSeated && !isFinished)) {
              currentGuests = partySize;
            }
          }
        } else {
          // For open tables, use the stored guest count
          currentGuests = data['currentGuests'] ?? 0;
        }

        // Build table data object with all necessary information
        tablesList.add({
          'id': doc.id,
          'tableNumber': tableNumber,
          'capacity': data['capacity'] ?? 4,
          'assignedServer': data['assignedServer'] ?? '',
          'status': status,
          'currentGuests': currentGuests,
        });
      }

      // Update state with processed table data
      if (mounted) {
        setState(() {
          allTables = tablesList;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error processing table data: $e');
      }
    }
  }

  // Display a snackbar message to the user
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.deepPurple),
    );
  }

  // Update table assignment in Firestore database
  Future<void> _reassignTable(String tableId, String newServerInitials) async {
    try {
      await FirebaseFirestore.instance.collection('Tables').doc(tableId).update(
        {'assignedServer': newServerInitials},
      );

      _showSnackBar('Table reassigned successfully!');
    } catch (e) {
      _showSnackBar('Error reassigning table: $e');
    }
  }

  // Auto-generate initials from first and last name inputs
  void _generateInitials() {
    if (_firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty) {
      final firstInitial = _firstNameController.text[0].toUpperCase();
      final lastInitial = _lastNameController.text[0].toUpperCase();
      setState(() {
        _initialsController.text = firstInitial + lastInitial;
      });
    }
  }

  // Generate a random 6-digit ID for new users
  void _generateRandomId() {
    final random = Random();
    final id =
        (random.nextInt(900000) + 100000).toString(); // Generates 100000-999999
    setState(() {
      _idController.text = id;
    });
  }

  // Create a new user/staff member in Firestore
  Future<void> _createUser() async {
    // Validate form before proceeding
    if (!_createUserFormKey.currentState!.validate()) {
      return;
    }

    try {
      // Extract form data
      final id = _idController.text;
      final firstName = _firstNameController.text;
      final lastName = _lastNameController.text;
      final initials =
          _initialsController.text; // Create new staff document in Firestore
      await FirebaseFirestore.instance.collection('Staff').doc(id).set({
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'initials': initials,
        'role': _selectedRole,
        'defaultView': 'Tables',
      });

      // Reset form and close overlay
      setState(() {
        showCreateUserOverlay = false;
        _idController.clear();
        _firstNameController.clear();
        _lastNameController.clear();
        _initialsController.clear();
        _selectedRole = 'User';
      });
      _showSnackBar('User created successfully!');
    } catch (e) {
      _showSnackBar('Error creating user: $e');
    }
  }

  // Build the section showing tables assigned to the current user (desktop layout)
  Widget _buildMyTablesSection() {
    // Filter tables to show only those assigned to current user
    final myTables =
        allTables
            .where((table) => table['assignedServer'] == currentUserInitials)
            .toList();

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF212224),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 8),
                Text(
                  'My Assigned Tables',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  myTables.isEmpty
                      ? // Empty state when user has no assigned tables
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F3031),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade700.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.table_restaurant,
                              color: Colors.grey.shade600,
                              size: 64,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No tables assigned to you',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                      :
                      // List of assigned tables
                      SingleChildScrollView(
                        child: Column(
                          children:
                              myTables
                                  .map((table) => _buildMyTableCard(table))
                                  .toList(),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the section showing tables assigned to the current user (mobile layout)
  Widget _buildMyTablesSectionMobile() {
    // Filter tables to show only those assigned to current user
    final myTables =
        allTables
            .where((table) => table['assignedServer'] == currentUserInitials)
            .toList();

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 300,
      ), // Limit height for mobile
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF212224),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.deepPurple, size: 24),
              const SizedBox(width: 8),
              Text(
                'My Assigned Tables',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child:
                myTables.isEmpty
                    ? // Empty state when user has no assigned tables
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F3031),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade700.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_restaurant,
                            color: Colors.grey.shade600,
                            size: 64,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No tables assigned to you',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    :
                    // List of assigned tables
                    SingleChildScrollView(
                      child: Column(
                        children:
                            myTables
                                .map((table) => _buildMyTableCard(table))
                                .toList(),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  // Build the section showing all server assignments grouped by server
  Widget _buildAllAssignmentsSection() {
    // Group tables by assigned server initials
    Map<String, List<Map<String, dynamic>>> tablesByServer = {};
    for (var table in allTables) {
      final server = table['assignedServer'] as String;
      if (!tablesByServer.containsKey(server)) {
        tablesByServer[server] = [];
      }
      tablesByServer[server]!.add(table);
    }
    return Card(
      color: const Color(0xFF2F3031),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create a section for each server with their assigned tables
            ...tablesByServer.entries.map((entry) {
              final serverInitials = entry.key;
              final tables = entry.value;
              // Find server details from staff list
              final server = allStaff.firstWhere(
                (staff) => staff['initials'] == serverInitials,
                orElse: () => {'firstName': 'Unknown', 'lastName': 'Server'},
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF212224),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            serverInitials.isEmpty
                                ? 'Unassigned'
                                : serverInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${server['firstName']} ${server['lastName']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${tables.length} table${tables.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Display table cards in a responsive wrap layout
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          tables
                              .map((table) => _buildTableCard(table, false))
                              .toList(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Build a detailed table card for the current user's assigned tables
  Widget _buildMyTableCard(Map<String, dynamic> table) {
    // Determine status color based on table status
    Color statusColor;
    switch (table['status']) {
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3E3F41),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple, width: 2),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Table ${table['tableNumber']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      table['status'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Capacity: ${table['capacity']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    'Guests: ${table['currentGuests']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          // Manager edit button (only visible to managers)
          if (isManager)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showReassignDialog(table),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Build a compact table card for display in grid layouts
  Widget _buildTableCard(Map<String, dynamic> table, bool isMyTable) {
    // Determine status color based on table status
    Color statusColor;
    switch (table['status']) {
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
    return Container(
      width: 160,
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF3E3F41),
        borderRadius: BorderRadius.circular(8),
        border:
            isMyTable ? Border.all(color: Colors.deepPurple, width: 2) : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Table ${table['tableNumber']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    table['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Cap: ${table['capacity']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                Text(
                  'Guests: ${table['currentGuests']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          ),
          // Manager edit button (only visible to managers)
          if (isManager)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showReassignDialog(table),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Show dialog for reassigning a table to a different server (manager only)
  void _showReassignDialog(Map<String, dynamic> table) {
    String? selectedServer = table['assignedServer'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2F3031),
              title: Text(
                'Reassign Table ${table['tableNumber']}',
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Currently assigned to: ${table['assignedServer'].isEmpty ? 'Unassigned' : table['assignedServer']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  // Dropdown to select new server assignment
                  DropdownButtonFormField<String>(
                    value:
                        selectedServer?.isEmpty == true ? null : selectedServer,
                    dropdownColor: const Color(0xFF2F3031),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Assign to Server',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'Unassigned',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      // List all available staff members
                      ...allStaff.map((staff) {
                        return DropdownMenuItem<String>(
                          value: staff['initials'],
                          child: Text(
                            '${staff['firstName']} ${staff['lastName']} (${staff['initials']})',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedServer = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Execute the table reassignment
                    _reassignTable(table['id'], selectedServer ?? '');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    'Reassign',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Build the overlay form for creating new users (manager only)
  Widget _buildCreateUserOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive sizing for mobile vs desktop
              final isMobile = constraints.maxWidth <= 600;
              final overlayWidth =
                  isMobile ? constraints.maxWidth * 0.9 : 400.0;

              return Container(
                width: overlayWidth,
                margin: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 32,
                  vertical: 24,
                ),
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F3031),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Form(
                  key: _createUserFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Create New User',
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
                                showCreateUserOverlay = false;
                                _idController.clear();
                                _firstNameController.clear();
                                _lastNameController.clear();
                                _initialsController.clear();
                                _selectedRole = 'User';
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // ID field with random generation button
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _idController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'ID',
                                labelStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter ID';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _generateRandomId,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Generate',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Role selection dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        dropdownColor: const Color(0xFF2F3031),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Role',
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        items:
                            _roleOptions
                                .map(
                                  (role) => DropdownMenuItem<String>(
                                    value: role,
                                    child: Text(
                                      role,
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
                              _selectedRole = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // First and last name fields (auto-generate initials)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              style: const TextStyle(color: Colors.white),
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
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
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
                              style: const TextStyle(color: Colors.white),
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
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
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
                      // Initials field (auto-generated but editable)
                      TextFormField(
                        controller: _initialsController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Initials',
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          helperText:
                              'Auto-generated from names but can be edited',
                          helperStyle: TextStyle(color: Colors.grey.shade400),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter initials';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                showCreateUserOverlay = false;
                                _idController.clear();
                                _firstNameController.clear();
                                _lastNameController.clear();
                                _initialsController.clear();
                                _selectedRole = 'User';
                              });
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _createUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Create User',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Build the section showing all tables in a responsive grid layout
  Widget _buildAllTablesSection() {
    // Sort tables by table number for consistent display
    final sortedTables = List<Map<String, dynamic>>.from(allTables);
    sortedTables.sort(
      (a, b) => (a['tableNumber'] ?? 0).compareTo(b['tableNumber'] ?? 0),
    );

    return Card(
      color: const Color(0xFF2F3031),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive grid layout
                final screenWidth = constraints.maxWidth;
                final cardWidth = 280.0;
                final spacing = 16.0;
                final cardsPerRow = ((screenWidth + spacing) /
                        (cardWidth + spacing))
                    .floor()
                    .clamp(1, 10);

                // Create rows of table cards
                final List<Widget> rows = [];
                for (int i = 0; i < sortedTables.length; i += cardsPerRow) {
                  final endIndex = (i + cardsPerRow).clamp(
                    0,
                    sortedTables.length,
                  );
                  final rowTables = sortedTables.sublist(i, endIndex);

                  rows.add(
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i + cardsPerRow < sortedTables.length ? 16 : 0,
                      ),
                      child: Row(
                        children: [
                          // Add table cards for this row
                          for (int j = 0; j < rowTables.length; j++) ...[
                            Expanded(
                              child: _buildIndividualTableCard(rowTables[j]),
                            ),
                            if (j < rowTables.length - 1)
                              const SizedBox(width: 16),
                          ],
                          // Fill remaining spaces in row
                          for (
                            int k = rowTables.length;
                            k < cardsPerRow;
                            k++
                          ) ...[
                            if (k > 0) const SizedBox(width: 16),
                            const Expanded(child: SizedBox()),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return Column(children: rows);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Build a detailed individual table card showing complete table information
  Widget _buildIndividualTableCard(Map<String, dynamic> table) {
    // Determine status color based on table status
    Color statusColor;
    switch (table['status']) {
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

    // Find assigned server details from staff list
    final assignedServer = allStaff.firstWhere(
      (staff) => staff['initials'] == table['assignedServer'],
      orElse: () => {'firstName': '', 'lastName': '', 'initials': ''},
    );
    return Container(
      constraints: const BoxConstraints(minWidth: 250, maxWidth: 320),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3E3F41),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Table ${table['tableNumber']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ), // Manager edit button (only visible to managers)
              if (isManager) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showReassignDialog(table),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              table['status'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                'Capacity: ${table['capacity']}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                'Current Guests: ${table['currentGuests']}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF212224),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assigned Server:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                // Show assigned server or unassigned status
                if (table['assignedServer'].isEmpty)
                  const Text(
                    'Unassigned',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          table['assignedServer'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${assignedServer['firstName']} ${assignedServer['lastName']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
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

  // Main build method - determines layout based on screen size
  @override
  Widget build(BuildContext context) {
    // Show loading spinner while initializing data
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF212224),
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    // Responsive layout based on screen width
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 1200;
        final isMediumScreen = constraints.maxWidth > 800;
        final isSmallScreen = constraints.maxWidth <= 800;

        if (isSmallScreen) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout(isLargeScreen, isMediumScreen);
        }
      },
    );
  }

  // Build mobile-optimized layout with collapsible sections
  Widget _buildMobileLayout() {
    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              // Collapsible section for user's assigned tables
              ExpansionTile(
                title: const Text(
                  'My Tables',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: const Color(0xFF2F3031),
                collapsedBackgroundColor: const Color(0xFF2F3031),
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                initiallyExpanded: false,
                children: [
                  Container(
                    color: const Color(0xFF2F3031),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const DateTimeBox(),
                        const SizedBox(height: 20),
                        _buildMyTablesSectionMobile(),
                      ],
                    ),
                  ),
                ],
              ),
              // Main content area with tab switching
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(color: Color(0xFF212224)),
                  child: Column(
                    children: [
                      _buildResponsiveHeader(true),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child:
                              selectedTabIndex == 0
                                  ? _buildAllTablesSection()
                                  : _buildAllAssignmentsSection(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Overlay for create user form
        if (showCreateUserOverlay) _buildCreateUserOverlay(),
      ],
    );
  }

  // Build desktop/tablet layout with sidebar and main content area
  Widget _buildDesktopLayout(bool isLargeScreen, bool isMediumScreen) {
    final sidebarWidth = 400.0;

    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: Row(
            children: [
              // Sidebar with user's assigned tables and datetime
              Container(
                width: sidebarWidth,
                padding: EdgeInsets.all(isLargeScreen ? 16.0 : 12.0),
                color: const Color(0xFF2F3031),
                child: Column(
                  children: [
                    const DateTimeBox(),
                    const SizedBox(height: 20),
                    _buildMyTablesSection(),
                  ],
                ),
              ),
              // Main content area with tabs and table displays
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(color: Color(0xFF212224)),
                  child: Column(
                    children: [
                      _buildResponsiveHeader(false),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
                          child:
                              selectedTabIndex == 0
                                  ? _buildAllTablesSection()
                                  : _buildAllAssignmentsSection(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Overlay for create user form
        if (showCreateUserOverlay) _buildCreateUserOverlay(),
      ],
    );
  }

  // Build responsive header with tab buttons and create user button
  Widget _buildResponsiveHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child:
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab switching buttons for mobile layout
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E3F41),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedTabIndex = 0;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    selectedTabIndex == 0
                                        ? Colors.deepPurple
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'All Tables',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedTabIndex = 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    selectedTabIndex == 1
                                        ? Colors.deepPurple
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Server Assignments',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Create user button for managers (mobile)
                  if (isManager) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          showCreateUserOverlay = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Create User',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ],
              )
              : Row(
                children: [
                  // Tab buttons for desktop layout
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E3F41),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedTabIndex = 0;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  selectedTabIndex == 0
                                      ? Colors.deepPurple
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'All Tables',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedTabIndex = 1;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  selectedTabIndex == 1
                                      ? Colors.deepPurple
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Server Assignments',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Create user button for managers (desktop)
                  if (isManager) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          showCreateUserOverlay = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      label: const Text(
                        'Create User',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
    );
  }
}
