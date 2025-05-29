import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Components/datetime.dart';
import '../Components/order_data.dart';
import '../Components/itemdata.dart';

// Main order view widget for restaurant staff to manage table orders
// Displays seated tables, menu items by category, and current orders
class OrderView extends StatefulWidget {
  const OrderView({super.key});

  @override
  State<OrderView> createState() => _OrderViewState();
}

// State class managing order view functionality and real-time data updates
class _OrderViewState extends State<OrderView> {
  String? selectedTableId;
  String? selectedCategory = 'All';
  List<String> categories = ['All'];
  List<OrderItem> currentOrder = [];
  Map<String, dynamic>? selectedTable;
  List<ItemData> menuItems = [];

  @override
  // Initialize page data and set up real-time listeners for database changes
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchMenuItems();
    _listenToTables();
    _listenToOrders();
  }

  // Fetch all unique menu categories from Firestore to populate filter buttons
  void _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('Items').get();
    final Set<String> uniqueCategories = {'All'};
    for (var doc in snapshot.docs) {
      uniqueCategories.add(doc['category'] ?? 'Uncategorized');
    }
    setState(() {
      categories = uniqueCategories.toList();
    });
  }

  // Set up real-time listener for available menu items from Firestore
  void _fetchMenuItems() {
    FirebaseFirestore.instance
      .collection('Items')
      .where('isAvailable', isEqualTo: true)
      .snapshots()
      .listen((snapshot) {
        final items = snapshot.docs.map((doc) => ItemData.fromFirestore(doc)).toList();
        setState(() {
          menuItems = items;
        });
      });
  }

  // Listen for changes to seated tables and automatically select the first available table
  void _listenToTables() {
    FirebaseFirestore.instance
      .collection('Tables')
      .where('status', isEqualTo: 'Seated')
      .snapshots()
      .listen((snapshot) async {
        if (mounted) {
          setState(() {
            // Auto-select first table if none selected
            if (selectedTableId == null && snapshot.docs.isNotEmpty) {
              selectedTableId = snapshot.docs.first.id;
            } else if (snapshot.docs.isEmpty) {
              selectedTableId = null;
              selectedTable = null;
            }
          });
        }
      });
  }

  // Listen for real-time order updates and sync with currently selected table
  void _listenToOrders() {
    FirebaseFirestore.instance
      .collection('Orders')
      .where('status', whereIn: ['pending', 'in-progress'])
      .snapshots()
      .listen((snapshot) {
        if (selectedTableId != null) {
          final tableNumber = int.parse(selectedTableId!.split('_').last);
          List<OrderItem> tableOrders = [];

          // Find orders for the selected table
          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (data['tableNumber'] == tableNumber) {
              final items = data['items'] as List<dynamic>;
              tableOrders =
                items.map(
                  (item) =>
                    OrderItem.fromMap(item as Map<String, dynamic>),
                ).toList();
              break;
            }
          }

          if (mounted) {
            setState(() {
              currentOrder = tableOrders;
            });
          }
        }
      });
  }

  // Add a menu item to the current order for the selected table
  // Creates new order if none exists, or updates existing order
  void _addItemToOrder(ItemData item) async {
    // Validate table selection
    if (selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a table first')),
      );
      return;
    }

    final tableNumber = int.parse(selectedTableId!.split('_').last);
    // Create new order item with default quantity and empty notes
    final orderItem = OrderItem(
      name: item.name,
      quantity: 1,
      price: item.price,
      notes: '',
    );

    try {
      // Check if there's already an existing order for this table
      final existingOrderSnapshot =
        await FirebaseFirestore.instance
          .collection('Orders')
          .where('tableNumber', isEqualTo: tableNumber)
          .where('status', whereIn: ['pending', 'in-progress'])
          .get();

      if (existingOrderSnapshot.docs.isNotEmpty) {
        // Update existing order with new item
        final existingOrder = existingOrderSnapshot.docs.first;
        final existingItems = List<Map<String, dynamic>>.from(
          existingOrder.data()['items'] ?? [],
        );
        existingItems.add(orderItem.toMap());
        // Recalculate total amount
        final totalAmount = existingItems.fold<double>(
          0, (sum, item) => sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1)),
        );

        await existingOrder.reference.update({
          'items': existingItems,
          'totalAmount': totalAmount,
        });
      } else {
        // Create new order document
        final orderData = {
          'tableNumber': tableNumber,
          'items': [orderItem.toMap()],
          'totalAmount': orderItem.totalPrice,
          'status': 'pending',
          'createdAt': Timestamp.now(),
          'notes': '',
        };

        await FirebaseFirestore.instance.collection('Orders').add(orderData);
      }
    } catch (e) {
      // Show error message if operation fails
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding item: $e')));
    }
  }

  // Remove an item from the current order or cancel the entire order if it becomes empty
  void _removeOrderItem(int index) async {
    try {
      final tableNumber = int.parse(selectedTableId!.split('_').last);
      // Find the current order for the table
      final orderSnapshot =
        await FirebaseFirestore.instance
          .collection('Orders')
          .where('status', whereIn: ['pending', 'in-progress'])
          .where('tableNumber', isEqualTo: tableNumber)
          .get();

      if (orderSnapshot.docs.isNotEmpty) {
        final orderDoc = orderSnapshot.docs.first;
        final items = List<Map<String, dynamic>>.from(
          orderDoc.data()['items'] ?? [],
        );

        if (items.length > 1) {
          // Remove specific item and update total
          items.removeAt(index);
          final totalAmount = items.fold<double>(
            0, (sum, item) => sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1)),
          );

          await orderDoc.reference.update({
            'items': items,
            'totalAmount': totalAmount,
          });
        } else {
          // Cancel order if removing the last item
          await orderDoc.reference.update({'status': 'cancelled'});
        }
      }
    } catch (e) {
      // Show error message if removal fails
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing item: $e')));
    }
  }

  // Display a dialog for adding or editing notes for a specific order item
  void _addNoteToItem(int index) {
    final TextEditingController noteController = TextEditingController();
    // Pre-populate with existing note
    noteController.text = currentOrder[index].notes;

    showDialog(
      context: context,
      builder:
        (context) => AlertDialog(
          backgroundColor: const Color(0xFF2F3031),
          title: const Text(
            'Add Note',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: noteController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Note',
              labelStyle: TextStyle(color: Colors.white70),
            ),
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
              onPressed: () async {
                try {
                  final tableNumber = int.parse(
                    selectedTableId!.split('_').last,
                  );
                  // Find the order document to update
                  final querySnapshot =
                    await FirebaseFirestore.instance
                      .collection('Orders')
                      .where(
                        'status',
                        whereIn: ['pending', 'in-progress'],
                      )
                      .where('tableNumber', isEqualTo: tableNumber)
                      .get();
                  if (querySnapshot.docs.isNotEmpty) {
                    final orderDoc = querySnapshot.docs.first;
                    final items = List<Map<String, dynamic>>.from(
                      orderDoc.data()['items'] ?? [],
                    );

                    // Update the specific item's note
                    if (items.length > index) {
                      items[index]['notes'] = noteController.text;

                      await orderDoc.reference.update({
                        'items': items,
                        'notes': noteController.text,
                      });
                    }
                  }

                  Navigator.pop(context);
                } catch (e) {
                  // Show error if note update fails
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating note: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
    );
  }

  // Build the order summary widget displaying total price and list of ordered items
  Widget _buildOrderSummary() {
    // Calculate total price from all items in current order
    double total = currentOrder.fold(0, (sum, item) => sum + item.totalPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Total: \$${total.toStringAsFixed(2)}',
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: currentOrder.length,
            itemBuilder: (context, index) {
              final item = currentOrder[index];
              return Card(
                color: const Color(0xFF2F3031),
                child: ListTile(
                  title: Text(
                    item.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${item.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      // Show note if it exists
                      if (item.notes.isNotEmpty)
                        Text(
                          'Note: ${item.notes}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Add note button
                      IconButton(
                        icon: const Icon(Icons.note_add, color: Colors.white70),
                        onPressed: () => _addNoteToItem(index),
                      ),
                      // Remove item button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeOrderItem(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  // Build the main UI layout with two-panel design: left panel for orders, right panel for menu
  Widget build(BuildContext context) {
    // Filter menu items based on selected category
    List<ItemData> filteredItems =
      selectedCategory == 'All'
        ? menuItems
        : menuItems
          .where((item) => item.category == selectedCategory)
          .toList();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF212224),
      body: Row(
        children: [
          // Left panel: Date/time, table selection, and order summary
          Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2F3031),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and time display
                Center(child: const DateTimeBox()),
                const SizedBox(height: 20),
                // Active tables section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF212224),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Tables',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stream builder for real-time table updates
                      StreamBuilder<QuerySnapshot>(
                        stream:
                          FirebaseFirestore.instance
                            .collection('Tables')
                            .where('status', isEqualTo: 'Seated')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          final tables = snapshot.data!.docs;
                          if (tables.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: const Text(
                                'No Seated Tables',
                                style: TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          // Enhance table data with reservation information
                          return FutureBuilder<List<Map<String, dynamic>?>>(
                            future: Future.wait(
                              tables.map((table) async {
                                final tableData = Map<String, dynamic>.from(
                                  table.data() as Map<String, dynamic>,
                                );
                                final tableNumber = tableData['tableNumber'];

                                // Get reservation details for the table
                                final reservationSnapshot =
                                  await FirebaseFirestore.instance
                                    .collection('Reservations')
                                    .where(
                                      'tableNumber',
                                      isEqualTo: tableNumber,
                                    )
                                    .where('seated', isEqualTo: true)
                                    .orderBy('startTime', descending: true)
                                    .limit(1)
                                    .get();

                                if (reservationSnapshot.docs.isNotEmpty) {
                                  final reservationData = reservationSnapshot.docs.first.data();

                                  // Skip finished reservations
                                  if (reservationData['isFinished'] == true) {
                                    return null;
                                  }

                                  // Add customer information to table data
                                  tableData['customerName'] =
                                    reservationData['customerName'] ??
                                    'No name';
                                  tableData['partySize'] =
                                    reservationData['partySize'] ?? 0;
                                }
                                return {'id': table.id, 'data': tableData};
                              }),
                            ),
                            builder: (
                              context,
                              AsyncSnapshot<List<Map<String, dynamic>?>>
                              enhancedSnapshot,
                            ) {
                              if (!enhancedSnapshot.hasData) {
                                return const CircularProgressIndicator();
                              }

                              // Filter out null entries (finished reservations)
                              final enhancedTables =
                                enhancedSnapshot.data!
                                  .where((item) => item != null)
                                  .cast<Map<String, dynamic>>()
                                  .toList();

                              if (enhancedTables.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: const Text(
                                    'No Active Tables',
                                    style: TextStyle(color: Colors.white70),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              // Dropdown for table selection
                              return DropdownButtonFormField<String>(
                                value: selectedTableId,
                                dropdownColor: const Color(0xFF2F3031),
                                style: const TextStyle(color: Colors.white),
                                isExpanded: true,
                                menuMaxHeight: 300,
                                decoration: InputDecoration(
                                  labelText: 'Select Table',
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF2F3031),
                                ),
                                items:
                                  enhancedTables.map((tableInfo) {
                                    final data = tableInfo['data'] as Map<String, dynamic>;
                                    return DropdownMenuItem<String>(
                                      value: tableInfo['id'] as String,
                                      child: Text(
                                        'Table ${data['tableNumber'] ?? 'Unknown'}   |   ${data['customerName'] ?? 'No name'}  -  ${data['partySize'] ?? 0} guests',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedTableId = value;
                                      // Clear current order when switching tables
                                      currentOrder.clear();
                                    });
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Order Summary section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF212224),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                      selectedTableId == null
                        ? const Center(
                          child: Text(
                            'Select a table to start an order',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                        : _buildOrderSummary(),
                  ),
                ),
              ],
            ),
          ),
          // Right panel: Category filters and menu items grid
          Expanded(
            child: Column(
              children: [
                // Category filter buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          categories.map((category) {
                            final isSelected = selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                    isSelected
                                      ? Colors.deepPurple
                                      : const Color(0xFF2F3031),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedCategory = category;
                                  });
                                },
                                child: Text(category),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
                // Menu items grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return Card(
                        color: const Color(0xFF2F3031),
                        child: InkWell(
                          onTap: () => _addItemToOrder(item),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item name and popular indicator
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Show star icon for popular items
                                    if (item.isPopular)
                                      Icon(
                                        Icons.star,
                                        color: Colors.yellow.shade600,
                                        size: 18,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Item type and preparation time
                                Row(
                                  children: [
                                    Text(
                                      item.type.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.blue.shade300,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.schedule,
                                      color: Colors.grey.shade400,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${item.preparationTime}m',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Item price
                                Text(
                                  '\$${item.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Item description (if available)
                                if (item.description.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      item.description,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                // Allergen warnings (if any)
                                if (item.allergens.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber,
                                        color: Colors.orange.shade400,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.allergens.join(', '),
                                          style: TextStyle(
                                            color: Colors.orange.shade300,
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
