import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Components/itemdata.dart';

class ItemDataUploader extends StatefulWidget {
  const ItemDataUploader({Key? key}) : super(key: key);

  @override
  _ItemDataUploaderState createState() => _ItemDataUploaderState();
}

class _ItemDataUploaderState extends State<ItemDataUploader> {
  final _formKey = GlobalKey<FormState>();
  final List<ItemData> _items = [];
  bool _isLoading = false;
  bool _isEditing = false;
  int _editingIndex = -1;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _preparationTimeController = TextEditingController();

  String _selectedType = 'Food';
  String _selectedCategory = 'Main Course';
  bool _isAvailable = true;
  bool _isPopular = false;
  List<String> _selectedAllergens = [];

  final List<String> _typeOptions = ['Food', 'Drink'];
  final List<String> _categoryOptions = [
    'Appetizers',
    'Main Course',
    'Desserts',
    'Hot Drinks',
    'Cold Drinks',
    'Alcoholic Beverages'
  ];
  final List<String> _allergenOptions = [
    'Gluten',
    'Dairy',
    'Nuts',
    'Eggs',
    'Soy',
    'Shellfish',
    'Fish',
    'Celery',
    'Mustard',
    'Sesame',
    'Sulphites',
    'Lupin',
    'Molluscs',
    'Peanuts'
  ];

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
    _preparationTimeController.dispose();
    super.dispose();
  }

  void _fetchExistingItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Items')
          .orderBy('name')
          .get();

      final List<ItemData> fetchedItems = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        fetchedItems.add(
          ItemData(
            id: doc.id,
            type: data['type'] ?? '',
            name: data['name'] ?? '',
            price: (data['price'] ?? 0.0).toDouble(),
            description: data['description'] ?? '',
            allergens: List<String>.from(data['allergens'] ?? []),
            isAvailable: data['isAvailable'] ?? true,
            category: data['category'] ?? '',
            isPopular: data['isPopular'] ?? false,
            preparationTime: data['preparationTime'] ?? 15,
          ),
        );
      }

      setState(() {
        _items.clear();
        _items.addAll(fetchedItems);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error fetching items: $e');
    }
  }

  void _resetForm() {
    _nameController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _preparationTimeController.clear();
    setState(() {
      _selectedType = 'Food';
      _selectedCategory = 'Main Course';
      _isAvailable = true;
      _isPopular = false;
      _selectedAllergens = [];
      _isEditing = false;
      _editingIndex = -1;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final id = _isEditing ? _items[_editingIndex].id : DateTime.now().millisecondsSinceEpoch.toString();
      
      final itemData = {
        'type': _selectedType,
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'allergens': _selectedAllergens,
        'isAvailable': _isAvailable,
        'category': _selectedCategory,
        'isPopular': _isPopular,
        'preparationTime': int.parse(_preparationTimeController.text),
      };

      await FirebaseFirestore.instance
          .collection('Items')
          .doc(id)
          .set(itemData);

      final newItem = ItemData(
        id: id,
        type: _selectedType,
        name: _nameController.text,
        price: double.parse(_priceController.text),
        description: _descriptionController.text,
        allergens: _selectedAllergens,
        isAvailable: _isAvailable,
        category: _selectedCategory,
        isPopular: _isPopular,
        preparationTime: int.parse(_preparationTimeController.text),
      );

      if (_isEditing && _editingIndex >= 0 && _editingIndex < _items.length) {
        setState(() {
          _items[_editingIndex] = newItem;
        });
      } else {
        setState(() {
          _items.add(newItem);
          _items.sort((a, b) => a.name.compareTo(b.name));
        });
      }

      _resetForm();
      _showSnackBar('Item saved successfully!');
    } catch (e) {
      _showSnackBar('Error saving item: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(String id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('Items')
          .doc(id)
          .delete();

      setState(() {
        _items.removeWhere((item) => item.id == id);
      });

      _showSnackBar('Item deleted successfully!');
    } catch (e) {
      _showSnackBar('Error deleting item: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editItem(ItemData item, int index) {
    setState(() {
      _isEditing = true;
      _editingIndex = index;
      _nameController.text = item.name;
      _priceController.text = item.price.toString();
      _descriptionController.text = item.description;
      _preparationTimeController.text = item.preparationTime.toString();
      _selectedType = item.type;
      _selectedCategory = item.category;
      _isAvailable = item.isAvailable;
      _isPopular = item.isPopular;
      _selectedAllergens = List.from(item.allergens);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212224),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Item' : 'Add Menu Item',
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
                              Text(
                                _isEditing ? 'Edit Item' : 'Add New Item',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Type Selection
                              DropdownButtonFormField<String>(
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
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                dropdownColor: const Color(0xFF2F3031),
                                value: _selectedType,
                                items: _typeOptions
                                    .map((type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(
                                            type,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedType = value;
                                      // Update categories based on type
                                      if (value == 'Drink') {
                                        _selectedCategory = 'Cold Drinks';
                                      } else {
                                        _selectedCategory = 'Main Course';
                                      }
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              // Name Field
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Name',
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
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter item name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Price and Preparation Time Row
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _priceController,
                                      decoration: InputDecoration(
                                        labelText: 'Price (£)',
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
                                      style: const TextStyle(color: Colors.white),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter price';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Please enter a valid price';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _preparationTimeController,
                                      decoration: InputDecoration(
                                        labelText: 'Prep Time (mins)',
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
                                      style: const TextStyle(color: Colors.white),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter prep time';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Please enter a valid time';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Category Selection
                              DropdownButtonFormField<String>(
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
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                dropdownColor: const Color(0xFF2F3031),
                                value: _selectedCategory,
                                items: _categoryOptions
                                    .map((category) => DropdownMenuItem(
                                          value: category,
                                          child: Text(
                                            category,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              // Description Field
                              TextFormField(
                                controller: _descriptionController,
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
                                style: const TextStyle(color: Colors.white),
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter item description';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Allergens Section
                              Text(
                                'Allergens',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: _allergenOptions
                                    .map((allergen) => FilterChip(
                                          label: Text(allergen),
                                          selected: _selectedAllergens
                                              .contains(allergen),
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                _selectedAllergens.add(allergen);
                                              } else {
                                                _selectedAllergens
                                                    .remove(allergen);
                                              }
                                            });
                                          },
                                          backgroundColor:
                                              const Color(0xFF3E3F41),
                                          selectedColor: Colors.deepPurple,
                                          checkmarkColor: Colors.white,
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              // Availability and Popular toggles
                              Row(
                                children: [
                                  Expanded(
                                    child: CheckboxListTile(
                                      title: const Text(
                                        'Available',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      value: _isAvailable,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _isAvailable = value ?? true;
                                        });
                                      },
                                      checkColor: Colors.white,
                                      activeColor: Colors.deepPurple,
                                    ),
                                  ),
                                  Expanded(
                                    child: CheckboxListTile(
                                      title: const Text(
                                        'Popular',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      value: _isPopular,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _isPopular = value ?? false;
                                        });
                                      },
                                      checkColor: Colors.white,
                                      activeColor: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _saveItem,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: Text(
                                  _isEditing ? 'Update Item' : 'Add Item',
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
                    Card(
                      color: const Color(0xFF2F3031),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Items',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _items.isEmpty
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
                                    itemCount: _items.length,
                                    itemBuilder: (context, index) {
                                      final item = _items[index];
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
                                            '${item.type} | ${item.category} | £${item.price.toStringAsFixed(2)}${item.allergens.isNotEmpty ? '\nAllergens: ${item.allergens.join(", ")}' : ''}',
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (!item.isAvailable)
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(right: 8.0),
                                                  child: Icon(
                                                    Icons.not_interested,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              if (item.isPopular)
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(right: 8.0),
                                                  child: Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                  ),
                                                ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () =>
                                                    _editItem(item, index),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () =>
                                                    _deleteItem(item.id),
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
