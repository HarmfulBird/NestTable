import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Components/datetime.dart';
import '../Components/order_data.dart';
import '../Components/itemdata.dart';

class OrderView extends StatefulWidget {
  const OrderView({super.key});

  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  String? selectedTableId;
  String? selectedCategory = 'All';
  List<String> categories = ['All'];
  List<OrderItem> currentOrder = [];
  Map<String, dynamic>? selectedTable;
  List<ItemData> menuItems = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchMenuItems();
    _listenToTables();
    _listenToOrders();
  }

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

  void _fetchMenuItems() {
    FirebaseFirestore.instance
        .collection('Items')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
          final items =
              snapshot.docs.map((doc) => ItemData.fromFirestore(doc)).toList();
          setState(() {
            menuItems = items;
          });
        });
  }

  void _listenToTables() {
    FirebaseFirestore.instance
        .collection('Tables')
        .where('status', isEqualTo: 'Seated')
        .snapshots()
        .listen((snapshot) async {
          if (mounted) {
            setState(() {
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

  void _listenToOrders() {
    FirebaseFirestore.instance
        .collection('Orders')
        .where('status', whereIn: ['pending', 'in-progress'])
        .orderBy('status')
        .snapshots()
        .listen((snapshot) {
          if (selectedTableId != null) {
            final tableNumber = int.parse(selectedTableId!.split('_').last);
            List<OrderItem> tableOrders = [];

            for (var doc in snapshot.docs) {
              final data = doc.data();
              if (data['tableNumber'] == tableNumber) {
                final items = data['items'] as List<dynamic>;
                tableOrders =
                    items
                        .map(
                          (item) =>
                              OrderItem.fromMap(item as Map<String, dynamic>),
                        )
                        .toList();
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

  void _addItemToOrder(ItemData item) async {
    if (selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a table first')),
      );
      return;
    }

    final tableNumber = int.parse(selectedTableId!.split('_').last);
    final orderItem = OrderItem(
      name: item.name,
      quantity: 1,
      price: item.price,
      notes: '',
    );

    try {
      final existingOrderSnapshot =
          await FirebaseFirestore.instance
              .collection('Orders')
              .where('tableNumber', isEqualTo: tableNumber)
              .where('status', whereIn: ['pending', 'in-progress'])
              .get();

      if (existingOrderSnapshot.docs.isNotEmpty) {
        final existingOrder = existingOrderSnapshot.docs.first;
        final existingItems = List<Map<String, dynamic>>.from(
          existingOrder.data()['items'] ?? [],
        );
        existingItems.add(orderItem.toMap());
        final totalAmount = existingItems.fold<double>(
          0,
          (sum, item) =>
              sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1)),
        );

        await existingOrder.reference.update({
          'items': existingItems,
          'totalAmount': totalAmount,
        });
      } else {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding item: $e')));
    }
  }

  void _removeOrderItem(int index) async {
    try {
      final tableNumber = int.parse(selectedTableId!.split('_').last);
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
          items.removeAt(index);
          final totalAmount = items.fold<double>(
            0,
            (sum, item) =>
                sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1)),
          );

          await orderDoc.reference.update({
            'items': items,
            'totalAmount': totalAmount,
          });
        } else {
          await orderDoc.reference.update({'status': 'cancelled'});
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing item: $e')));
    }
  }

  void _addNoteToItem(int index) {
    final TextEditingController noteController = TextEditingController();
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

  Widget _buildOrderSummary() {
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
                      IconButton(
                        icon: const Icon(Icons.note_add, color: Colors.white70),
                        onPressed: () => _addNoteToItem(index),
                      ),
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
  Widget build(BuildContext context) {
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
          Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2F3031),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: const DateTimeBox()),
                const SizedBox(height: 20),
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
                          return FutureBuilder(
                            future: Future.wait(
                              tables.map((table) async {
                                final tableData = Map<String, dynamic>.from(
                                  table.data() as Map<String, dynamic>,
                                );
                                final tableNumber = tableData['tableNumber'];

                                final reservationSnapshot =
                                    await FirebaseFirestore.instance
                                        .collection('Reservations')
                                        .where(
                                          'tableNumber',
                                          isEqualTo: tableNumber,
                                        )
                                        .where('seated', isEqualTo: true)
                                        .where('isFinished', isEqualTo: false)
                                        .get();

                                if (reservationSnapshot.docs.isNotEmpty) {
                                  final reservationData =
                                      reservationSnapshot.docs.first.data();
                                  tableData['customerName'] =
                                      reservationData['customerName'] ??
                                      'No name';
                                  tableData['currentGuests'] =
                                      reservationData['partySize'] ?? 0;
                                }
                                return {'id': table.id, 'data': tableData};
                              }).toList(),
                            ),
                            builder: (
                              context,
                              AsyncSnapshot<List<Map<String, dynamic>>>
                              enhancedSnapshot,
                            ) {
                              if (!enhancedSnapshot.hasData) {
                                return const CircularProgressIndicator();
                              }

                              final enhancedTables = enhancedSnapshot.data!;

                              return DropdownButtonFormField<String>(
                                value: selectedTableId,
                                dropdownColor: const Color(0xFF2F3031),
                                style: const TextStyle(color: Colors.white),
                                isExpanded: true,
                                menuMaxHeight: 300,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white70,
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
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
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF2F3031),
                                  labelText: 'Select Table',
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                selectedItemBuilder: (BuildContext context) {
                                  return enhancedTables.map<Widget>((
                                    tableInfo,
                                  ) {
                                    final data =
                                        tableInfo['data']
                                            as Map<String, dynamic>;
                                    return Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Table ${data['tableNumber'] ?? 'Unknown'}   |   ${data['customerName'] ?? 'No name'}  -  ${data['currentGuests'] ?? 0} guests',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList();
                                },
                                items:
                                    enhancedTables.map<
                                      DropdownMenuItem<String>
                                    >((tableInfo) {
                                      final data =
                                          tableInfo['data']
                                              as Map<String, dynamic>;
                                      return DropdownMenuItem<String>(
                                        value: tableInfo['id'] as String,
                                        child: SizedBox(
                                          width: 368,
                                          child: Text(
                                            'Table ${data['tableNumber'] ?? 'Unknown'}   |   ${data['customerName'] ?? 'No name'}  -  ${data['currentGuests'] ?? 0} guests',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (String? value) {
                                  setState(() {
                                    selectedTableId = value;
                                    if (value != null) {
                                      final selectedTableInfo = enhancedTables
                                          .firstWhere(
                                            (table) => table['id'] == value,
                                            orElse: () => enhancedTables.first,
                                          );
                                      selectedTable =
                                          selectedTableInfo['data']
                                              as Map<String, dynamic>;
                                    }
                                  });
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
                // Order Summary
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
          Expanded(
            child: Column(
              children: [
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
                // Menu Items Grid
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
                                // Header with name and indicators
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
                                    if (item.isPopular)
                                      Icon(
                                        Icons.star,
                                        color: Colors.yellow.shade600,
                                        size: 18,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Type and preparation time
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
                                // Price
                                Text(
                                  '\$${item.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Description
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
                                // Allergens warning
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
