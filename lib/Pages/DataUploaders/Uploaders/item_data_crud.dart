import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemData {
  final String id;
  final String name;
  final double price;
  final String description;

  ItemData({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
  });
}

class ItemDataUploader extends StatefulWidget {
  const ItemDataUploader({super.key});

  @override
  ItemDataUploaderState createState() => ItemDataUploaderState();
}

class ItemDataUploaderState extends State<ItemDataUploader> {
  final _formKey = GlobalKey<FormState>();
  final List<ItemData> _itemsList = [];
  bool _isLoading = false;
  bool _isEditing = false;
  int _editingIndex = -1;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExistingItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _fetchExistingItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final itemsSnapshot = await FirebaseFirestore.instance
        .collection('Items')
        .orderBy('name')
        .get();

      final List<ItemData> fetchedItems = itemsSnapshot.docs.map((doc) {
        final data = doc.data();
        return ItemData(
          id: doc.id,
          name: data['name'] ?? '',
          price: (data['price'] ?? 0.0).toDouble(),
          description: data['description'] ?? '',
        );
      }).toList();

      setState(() {
        _itemsList
          ..clear()
          ..addAll(fetchedItems);
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar('Error fetching items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _priceController.clear();
    _descriptionController.clear();
    setState(() {
      _isEditing = false;
      _editingIndex = -1;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final itemData = {
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
      };

      if (_isEditing && _editingIndex >= 0) {
        // Update existing item
        await FirebaseFirestore.instance
          .collection('Items')
          .doc(_itemsList[_editingIndex].id)
          .update(itemData);
        _showSnackBar('Item updated successfully');
      } else {
        // Add new item
        await FirebaseFirestore.instance.collection('Items').add(itemData);
        _showSnackBar('Item added successfully');
      }

      _resetForm();
      _fetchExistingItems();
    } catch (e) {
      _showSnackBar('Error saving item: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editItem(int index) {
    final item = _itemsList[index];
    setState(() {
      _isEditing = true;
      _editingIndex = index;
      _nameController.text = item.name;
      _priceController.text = item.price.toString();
      _descriptionController.text = item.description;
    });
  }

  Future<void> _deleteItem(int index) async {
    try {
      await FirebaseFirestore.instance
        .collection('Items')
        .doc(_itemsList[index].id)
        .delete();
      _showSnackBar('Item deleted successfully');
      _fetchExistingItems();
    } catch (e) {
      _showSnackBar('Error deleting item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212224),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Item' : 'Add Item',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2F3031),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white),
              onPressed: _resetForm,
              tooltip: 'Cancel Editing',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchExistingItems,
            tooltip: 'Refresh Items',
          ),
        ],
      ),
      body: _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
          )
        : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: const Color(0xFF2F3031),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Item Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Item Name',
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
                            validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _priceController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Price',
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
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Price is required';
                              if (double.tryParse(value!) == null) {
                                return 'Please enter a valid price';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Description',
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
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _resetForm,
                                child: Text(
                                  _isEditing ? 'Cancel' : 'Clear',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(_isEditing ? 'Save Changes' : 'Add Item'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: const Color(0xFF2F3031),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Existing Items',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _itemsList.isEmpty
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No items yet. Add one above.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _itemsList.length,
                            itemBuilder: (context, index) {
                              final item = _itemsList[index];
                              return Card(
                                margin: const EdgeInsets.only(
                                  bottom: 8.0,
                                ),
                                color: const Color(0xFF212224),
                                child: ListTile(
                                  title: Text(
                                    item.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '\$${item.price.toStringAsFixed(2)}\n${item.description}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => _editItem(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => _deleteItem(index),
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
