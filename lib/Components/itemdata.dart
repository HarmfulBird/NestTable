import 'package:cloud_firestore/cloud_firestore.dart';

// Data model class representing a menu item in the restaurant app
// Contains all necessary information about food/drink items including pricing, availability, and metadata
class ItemData {
  final String id;
  final String type;
  final String name;
  final double price;
  final String description;
  final List<String> allergens;
  final bool isAvailable;
  final String category;
  final bool isPopular;
  final int preparationTime;

  // Constructor to create a new ItemData instance with required and optional parameters
  ItemData({
    required this.id,
    required this.type,
    required this.name,
    required this.price,
    required this.description,
    required this.allergens,
    this.isAvailable = true,
    required this.category,
    this.isPopular = false,
    this.preparationTime = 15,
  });

  // Factory constructor that creates an ItemData object from a Firestore document
  // Handles data type conversion and provides default values for missing fields
  factory ItemData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemData(
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
    );
  }

  // Converts the ItemData object to a Map for storing in Firestore
  // Used when saving data to the database
  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'name': name,
      'price': price,
      'description': description,
      'allergens': allergens,
      'isAvailable': isAvailable,
      'category': category,
      'isPopular': isPopular,
      'preparationTime': preparationTime,
    };
  }

  // Creates a copy of the ItemData object with modified values
  // Useful for updating specific fields while keeping others unchanged
  ItemData copyWith({
    String? type,
    String? name,
    double? price,
    String? description,
    List<String>? allergens,
    bool? isAvailable,
    String? category,
    bool? isPopular,
    int? preparationTime,
  }) {
    return ItemData(
      id: this.id, // ID remains the same as it's immutable
      type: type ?? this.type,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      allergens: allergens ?? this.allergens,
      isAvailable: isAvailable ?? this.isAvailable,
      category: category ?? this.category,
      isPopular: isPopular ?? this.isPopular,
      preparationTime: preparationTime ?? this.preparationTime,
    );
  }
}
