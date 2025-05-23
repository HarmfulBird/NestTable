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
      .listen((snapshot) {
        if (mounted) {
          setState(() {
            if (selectedTableId == null && snapshot.docs.isNotEmpty) {
              selectedTableId = snapshot.docs.first.id;
              selectedTable = snapshot.docs.first.data();
            } else if (snapshot.docs.isEmpty) {
              selectedTableId = null;
              selectedTable = null;
            } else {
              selectedTable =
                snapshot.docs
                  .firstWhere(
                    (doc) => doc.id == selectedTableId,
                    orElse: () => snapshot.docs.first,
                  )
                  .data();
            }
          });
        }
      });
  }  void _listenToOrders() {
    FirebaseFirestore.instance
      .collection('Orders')
      .where('status', whereIn: ['pending', 'in-progress'])
      .orderBy('status')
      .snapshots()
      .listen((snapshot) {
        if (selectedTableId != null) {
          final tableNumber = int.parse(selectedTableId!.split('_').last);
          final tableOrders =
            snapshot.docs
              .where((doc) => doc.data()['tableNumber'] == tableNumber)
              .map((doc) {
                final data = doc.data();
                return OrderItem.fromMap(
                  (data['items'] as List<dynamic>).first as Map<String, dynamic>,
                );
              })
              .toList();

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

    final orderItem = OrderItem(
      name: item.name,
      quantity: 1,
      price: item.price,
      notes: '',
    );
    final orderData = {
      'tableNumber': int.parse(selectedTableId!.split('_').last),
      'items': [orderItem.toMap()],
      'totalAmount': orderItem.totalPrice,
      'status': 'pending',
      'createdAt': Timestamp.now(),
      'notes': '',
    };

    try {
      await FirebaseFirestore.instance
        .collection('Orders')
        .add(orderData);
      setState(() {
        currentOrder.add(orderItem);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding item: $e')));
    }
  }

  void _removeOrderItem(int index) async {
    // Remove from database and update state
    try {
      final querySnapshot =
        await FirebaseFirestore.instance
          .collection('Orders')
          .where('status', whereIn: ['pending', 'in-progress'])
          .where(
            'tableNumber',
            isEqualTo: int.parse(selectedTableId!.split('_').last),
          )
          .get();

      if (querySnapshot.docs.length > index) {
        await querySnapshot.docs[index].reference.update({'status': 'cancelled'});
      }

      setState(() {
        currentOrder.removeAt(index);
      });
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
                  final querySnapshot =
                    await FirebaseFirestore.instance
                      .collection('Orders')
                      .where('status', whereIn: ['pending', 'in-progress'])
                      .where(
                        'tableNumber',
                        isEqualTo: int.parse(
                          selectedTableId!.split('_').last,
                        ),
                      )
                      .get();

                  if (querySnapshot.docs.length > index) {
                    await querySnapshot.docs[index].reference.update({
                      'items.0.notes': noteController.text,
                      'notes': noteController.text,
                    });
                  }

                  setState(() {
                    currentOrder[index] = OrderItem(
                      name: currentOrder[index].name,
                      quantity: currentOrder[index].quantity,
                      price: currentOrder[index].price,
                      notes: noteController.text,
                    );
                  });

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
                const DateTimeBox(),
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

                          return DropdownButtonFormField<String>(
                            value: selectedTableId,
                            dropdownColor: const Color(0xFF2F3031),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Select Table',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                            items:
                              tables.map((table) {
                                final data =
                                    table.data() as Map<String, dynamic>;
                                return DropdownMenuItem(
                                  value: table.id,
                                  child: Text(
                                    'Table ${data['tableNumber']} - ${data['currentGuests']} guests',
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList(),
                            onChanged: (String? value) {
                              setState(() {
                                selectedTableId = value;
                                selectedTable =
                                  tables
                                    .firstWhere((t) => t.id == value)
                                    .data()
                                    as Map<String, dynamic>;
                              });
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
                        childAspectRatio: 1.5,
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
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${item.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                if (item.description.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    item.description,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
