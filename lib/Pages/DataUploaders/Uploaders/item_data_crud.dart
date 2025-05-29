import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Components/itemdata.dart';

// StatefulWidget for managing item data in the restaurant management system
// Provides CRUD (Create, Read, Update, Delete) functionality for menu items
class ItemDataUploader extends StatefulWidget {
  const ItemDataUploader({super.key});

  @override
  ItemDataUploaderState createState() => ItemDataUploaderState();
}

// State class that handles all the business logic for item data management
// Manages form validation, Firestore operations, and UI state updates
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
  // Initialize the widget and load existing items when created
  @override
  void initState() {
    super.initState();
    _fetchExistingItems(); // Load all existing menu items on widget creation
  }

  // Clean up text controllers to prevent memory leaks when widget is destroyed
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _allergensController.dispose();
    _preparationTimeController.dispose();
    super.dispose();
  }

  // Asynchronously retrieves all menu items from Firestore database
  // Updates the local items list and manages loading state during the operation
  void _fetchExistingItems() async {
    // Show loading indicator while fetching data
    setState(() {
      _isLoading = true;
    });

    try {
      // Query Firestore for all items in the 'Items' collection, ordered alphabetically by name
      final itemsSnapshot =
        await FirebaseFirestore.instance
          .collection('Items')
          .orderBy('name')
          .get();

      // Convert Firestore documents to ItemData objects using the model's fromFirestore method
      final List<ItemData> fetchedItems =
        itemsSnapshot.docs.map((doc) {
          return ItemData.fromFirestore(doc);
        }).toList();

      // Update UI with fetched items and hide loading indicator
      setState(() {
        _itemsList
          ..clear() // Remove any existing items from the list
          ..addAll(fetchedItems); // Add all newly fetched items
        _isLoading = false;
      });
    } catch (e) {
      // Handle any errors during the fetch operation
      _showSnackBar('Error fetching items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Displays a brief message to the user using a Material Design SnackBar
  // Used for showing success messages, error alerts, and user feedback
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Resets all form fields and state variables to their initial values
  // Clears text controllers and dropdown selections, exits editing mode
  void _resetForm() {
    _formKey.currentState?.reset(); // Reset form validation state
    // Clear all text input controllers
    _nameController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _allergensController.clear();
    _preparationTimeController.clear();
    setState(() {
      // Reset dropdown selections to null (no selection)
      _selectedType = null;
      _selectedCategory = null;
      // Reset boolean flags to default values
      _isAvailable = true;
      _isPopular = false;
      // Exit editing mode and reset editing index
      _isEditing = false;
      _editingIndex = -1;
    });
  }

  // Validates form data and either creates a new item or updates an existing one in Firestore
  // Handles both add and edit operations based on the current editing state
  Future<void> _submitForm() async {
    // Validate all form fields before proceeding
    if (!_formKey.currentState!.validate()) return;

    // Show loading indicator during the save operation
    setState(() {
      _isLoading = true;
    });

    try {
      // Process allergens input: split comma-separated string, trim whitespace, remove empty entries
      List<String> allergensList =
        _allergensController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Create ItemData object with form values
      final itemData = ItemData(
        id:
          _isEditing
            ? _itemsList[_editingIndex].id
            : '', // Use existing ID for updates, empty for new items
        type: _selectedType ?? '',
        name: _nameController.text,
        price: double.parse(_priceController.text),
        description: _descriptionController.text,
        allergens: allergensList,
        isAvailable: _isAvailable,
        category: _selectedCategory ?? '',
        isPopular: _isPopular,
        preparationTime:
          int.tryParse(_preparationTimeController.text) ??
          15, // Default to 15 minutes if parsing fails
      );

      // Determine whether to update existing item or create new one
      if (_isEditing && _editingIndex >= 0) {
        // Update existing item in Firestore using its document ID
        await FirebaseFirestore.instance
          .collection('Items')
          .doc(_itemsList[_editingIndex].id)
          .update(itemData.toFirestore());
        _showSnackBar('Item updated successfully');
      } else {
        // Add new item to Firestore (auto-generates document ID)
        await FirebaseFirestore.instance
          .collection('Items')
          .add(itemData.toFirestore());
        _showSnackBar('Item added successfully');
      }

      // Clean up form and refresh the items list
      _resetForm();
      _fetchExistingItems();
    } catch (e) {
      // Handle any errors during the save operation
      _showSnackBar('Error saving item: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Populates the form with data from an existing item for editing
  // Sets the editing state and fills all form fields with the selected item's values
  void _editItem(int index) {
    final item = _itemsList[index];
    setState(() {
      // Enable editing mode and store the index of the item being edited
      _isEditing = true;
      _editingIndex = index;

      // Populate form fields with existing item data
      _nameController.text = item.name;
      _priceController.text = item.price.toString();
      _descriptionController.text = item.description;

      // Set dropdown values only if they exist in the available options
      _selectedType = _typeOptions.contains(item.type) ? item.type : null;
      _selectedCategory =
        _categoryOptions.contains(item.category) ? item.category : null;

      // Convert allergens list back to comma-separated string for display
      _allergensController.text = item.allergens.join(', ');
      _preparationTimeController.text = item.preparationTime.toString();

      // Set boolean flags
      _isAvailable = item.isAvailable;
      _isPopular = item.isPopular;
    });
  }

  // Permanently removes an item from Firestore database
  // Shows confirmation feedback and refreshes the items list
  Future<void> _deleteItem(int index) async {
    try {
      // Delete the item document from Firestore using its ID
      await FirebaseFirestore.instance
        .collection('Items')
        .doc(_itemsList[index].id)
        .delete();
      _showSnackBar('Item deleted successfully');
      _fetchExistingItems(); // Refresh the list to reflect the deletion
    } catch (e) {
      _showSnackBar('Error deleting item: $e');
    }
  }

  // Builds the complete user interface for the item management screen
  // Creates a dark-themed layout with form inputs and a list of existing items
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF212224), // Dark background color
      child:
        _isLoading
          ? const Center(
            // Show loading spinner when data is being processed
            child: CircularProgressIndicator(color: Colors.deepPurple),
          )
          : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FORM SECTION: Card containing all input fields for item data
                  Card(
                    color: const Color(
                      0xFF2F3031,
                    ), // Slightly lighter dark color for contrast
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey, // Form key for validation
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Form header
                            const Text(
                              'Item Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ROW 1: Item Name and Type selection
                            Row(
                              children: [
                                // Item name text field
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

                                // Type dropdown (Food/Drink)
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
                                    dropdownColor: const Color(
                                      0xFF2F3031,
                                    ), // Match card background
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

                            // ROW 2: Price and Category selection
                            Row(
                              children: [
                                // Price input field with number keyboard
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

                                // Category dropdown (Appetizer, Main Course, etc.)
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

                            // Multi-line description text field
                            TextFormField(
                              controller: _descriptionController,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 3, // Allow multiple lines for longer descriptions
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

                            // Allergens input field with helpful hint text
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

                            // Preparation time input with number validation
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

                            // Boolean options: Available and Popular item checkboxes
                            Row(
                              children: [
                                // Available checkbox
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
                                          MaterialTapTargetSize.shrinkWrap,
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

                                // Popular item checkbox
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
                                          MaterialTapTargetSize.shrinkWrap,
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

                            // Action buttons: Clear/Cancel and Add/Save
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Cancel/Clear button
                                TextButton(
                                  onPressed: _resetForm,
                                  child: Text(
                                    _isEditing
                                      ? 'Cancel'
                                      : 'Clear', // Dynamic text based on editing state
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Submit button
                                ElevatedButton(
                                  onPressed: _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(
                                    _isEditing
                                      ? 'Save Changes' // Update existing item
                                      : 'Add Item', // Create new item
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

                  // ITEMS LIST SECTION: Card displaying all existing items
                  Card(
                    color: const Color(0xFF2F3031),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section header
                          const Text(
                            'Existing Items',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Conditional rendering: empty state or items list
                          _itemsList.isEmpty
                            ? const Center(
                              // Empty state message when no items exist
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No items yet. Add one above.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap: true, // Take only needed space
                              physics:
                                const NeverScrollableScrollPhysics(), // Disable scrolling (handled by parent ScrollView)
                              itemCount: _itemsList.length,
                              itemBuilder: (context, index) {
                                final item = _itemsList[index];
                                return Card(
                                  margin: const EdgeInsets.only(
                                    bottom: 8.0,
                                  ),
                                  color: const Color(
                                    0xFF212224,
                                  ), // Darker background for individual items
                                  child: ListTile(
                                    // Item name as main title
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    // Item details in subtitle column
                                    subtitle: Column(
                                      crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                      children: [
                                        // Type and category information
                                        Text(
                                          'Type: ${item.type} | Category: ${item.category}',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),

                                        // Price and preparation time
                                        Text(
                                          '\$${item.price.toStringAsFixed(2)} | ${item.preparationTime} min',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),

                                        // Allergens display (only if item has allergens)
                                        if (item.allergens.isNotEmpty)
                                          Text(
                                            'Allergens: ${item.allergens.join(', ')}',
                                            style: TextStyle(
                                              color:Colors.orange.shade300, // Orange color to highlight allergens
                                            ),
                                          ),

                                        // Item description with text overflow handling
                                        Text(
                                          item.description,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                          maxLines: 2, // Limit to 2 lines
                                          overflow:
                                            TextOverflow.ellipsis, // Add ... if text is too long
                                        ),
                                      ],
                                    ),

                                    // Status icons on the left side
                                    leading: Column(
                                      mainAxisAlignment:
                                        MainAxisAlignment.center,
                                      children: [
                                        // Popular item star icon
                                        if (item.isPopular)
                                          Icon(
                                            Icons.star,
                                            color: Colors.yellow.shade600,
                                            size: 16,
                                          ),

                                        // Availability status icon
                                        Icon(
                                          item.isAvailable
                                            ? Icons.check_circle // Green checkmark for available
                                            : Icons.cancel, // Red X for unavailable
                                          color:
                                            item.isAvailable
                                              ? Colors.green
                                              : Colors.red,
                                          size: 16,
                                        ),
                                      ],
                                    ),

                                    // Action buttons on the right side
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
                                            () => _editItem(
                                              index,
                                            ), // Load item data into form for editing
                                        ),

                                        // Delete button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                          onPressed:
                                            () => _deleteItem(
                                              index,
                                            ), // Remove item from database
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
