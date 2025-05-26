import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Components/itemdata.dart';

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
  final _allergensController = TextEditingController();
  final _preparationTimeController = TextEditingController();

  bool _isAvailable = true;
  bool _isPopular = false;
  final List<String> _typeOptions = ['Food', 'Drink'];
  final List<String> _categoryOptions = [
    'Appetizer',
    'Main Course',
    'Dessert',
    'Beverage',
    'Snack',
  ];

  String? _selectedType;
  String? _selectedCategory;

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
    _allergensController.dispose();
    _preparationTimeController.dispose();
    super.dispose();
  }

  void _fetchExistingItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final itemsSnapshot =
        await FirebaseFirestore.instance
          .collection('Items')
          .orderBy('name')
          .get();

      final List<ItemData> fetchedItems =
        itemsSnapshot.docs.map((doc) {
          return ItemData.fromFirestore(doc);
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _allergensController.clear();
    _preparationTimeController.clear();
    setState(() {
      _selectedType = null;
      _selectedCategory = null;
      _isAvailable = true;
      _isPopular = false;
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
      // Parse allergens from comma-separated string
      List<String> allergensList =
        _allergensController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final itemData = ItemData(
        id: _isEditing ? _itemsList[_editingIndex].id : '',
        type: _selectedType ?? '',
        name: _nameController.text,
        price: double.parse(_priceController.text),
        description: _descriptionController.text,
        allergens: allergensList,
        isAvailable: _isAvailable,
        category: _selectedCategory ?? '',
        isPopular: _isPopular,
        preparationTime: int.tryParse(_preparationTimeController.text) ?? 15,
      );

      if (_isEditing && _editingIndex >= 0) {
        await FirebaseFirestore.instance
          .collection('Items')
          .doc(_itemsList[_editingIndex].id)
          .update(itemData.toFirestore());
        _showSnackBar('Item updated successfully');
      } else {
        await FirebaseFirestore.instance
          .collection('Items')
          .add(itemData.toFirestore());
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
      _selectedType = _typeOptions.contains(item.type) ? item.type : null;
      _selectedCategory = _categoryOptions.contains(item.category) ? item.category : null;
      _allergensController.text = item.allergens.join(', ');
      _preparationTimeController.text = item.preparationTime.toString();
      _isAvailable = item.isAvailable;
      _isPopular = item.isPopular;
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
      body:
        _isLoading
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
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _nameController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
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
                                      focusedBorder:
                                        const OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                    ),
                                    validator:
                                      (value) =>
                                        value?.isEmpty ?? true
                                          ? 'Name is required'
                                          : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedType,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Type',
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
                                    items:
                                      _typeOptions.map((String type) {
                                        return DropdownMenuItem<String>(
                                          value: type,
                                          child: Text(
                                            type,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    onChanged: (String? value) {
                                      setState(() {
                                        _selectedType = value;
                                      });
                                    },
                                    validator:
                                      (value) =>
                                        value == null || value.isEmpty
                                          ? 'Type is required'
                                          : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
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
                                      focusedBorder:
                                        const OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true)
                                        return 'Price is required';
                                      if (double.tryParse(value!) == null) {
                                        return 'Please enter a valid price';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Category',
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
                                    items:
                                      _categoryOptions.map((
                                        String category,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: category,
                                          child: Text(
                                            category,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    onChanged: (String? value) {
                                      setState(() {
                                        _selectedCategory = value;
                                      });
                                    },
                                    validator:
                                      (value) =>
                                        value == null || value.isEmpty
                                          ? 'Category is required'
                                          : null,
                                  ),
                                ),
                              ],
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
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _allergensController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Allergens (comma-separated)',
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
                                hintText: 'e.g., nuts, dairy, gluten',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _preparationTimeController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Preparation Time (minutes)',
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
                                if (value?.isNotEmpty == true &&
                                  int.tryParse(value!) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _isAvailable,
                                        onChanged: (value) {
                                          setState(() {
                                            _isAvailable = value ?? true;
                                          });
                                        },
                                        activeColor: Colors.deepPurple,
                                        checkColor: Colors.white,
                                        materialTapTargetSize:
                                          MaterialTapTargetSize
                                            .shrinkWrap,
                                        visualDensity:
                                          VisualDensity.compact,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Available',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _isPopular,
                                        onChanged: (value) {
                                          setState(() {
                                            _isPopular = value ?? false;
                                          });
                                        },
                                        activeColor: Colors.deepPurple,
                                        checkColor: Colors.white,
                                        materialTapTargetSize:
                                          MaterialTapTargetSize
                                            .shrinkWrap,
                                        visualDensity:
                                          VisualDensity.compact,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Popular Item',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _resetForm,
                                  child: Text(
                                    _isEditing ? 'Cancel' : 'Clear',
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(
                                    _isEditing
                                      ? 'Save Changes'
                                      : 'Add Item',
                                  ),
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
                              physics:
                                const NeverScrollableScrollPhysics(),
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
                                    subtitle: Column(
                                      crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Type: ${item.type} | Category: ${item.category}',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        Text(
                                          '\$${item.price.toStringAsFixed(2)} | ${item.preparationTime} min',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        if (item.allergens.isNotEmpty)
                                          Text(
                                            'Allergens: ${item.allergens.join(', ')}',
                                            style: TextStyle(
                                              color:
                                                Colors.orange.shade300,
                                            ),
                                          ),
                                        Text(
                                          item.description,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    leading: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (item.isPopular)
                                          Icon(
                                            Icons.star,
                                            color: Colors.yellow.shade600,
                                            size: 16,
                                          ),
                                        Icon(
                                          item.isAvailable
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                          color:
                                            item.isAvailable
                                              ? Colors.green
                                              : Colors.red,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                          ),
                                          onPressed:
                                              () => _editItem(index),
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
