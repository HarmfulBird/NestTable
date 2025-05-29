import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a complete order in the restaurant system
// Contains all order details including items, status, and table information
class OrderData {
  final String id;
  final int tableNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String notes;
  final Color statusColor;

  // Constructor for creating a new OrderData instance
  // Requires all essential order information
  OrderData({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.notes = '',
    required this.statusColor,
  });

  // Creates an OrderData object from a Firestore document
  factory OrderData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Determine status color based on order status
    // Each status has a corresponding color for UI display
    Color statusColor;
    switch (data['status']) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'in-progress':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    // Extract and convert Firestore data to OrderData object
    // Uses null coalescing operators (??) to provide default values
    return OrderData(
      id: doc.id,
      tableNumber: data['tableNumber'] ?? 0,
      items:
        (data['items'] as List? ?? [])
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      notes: data['notes'] ?? '',
      statusColor: statusColor,
    );
  }

  // Converts the OrderData object to a Map for storing in Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'tableNumber': tableNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
    };
  }
}

// Represents an individual item within an order
// Contains item details like name, quantity, price, and customizations
class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final String notes;
  final List<String> modifiers;

  // Constructor for creating a new OrderItem instance
  // Name, quantity, and price are required fields
  // Notes and modifiers have default values
  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.notes = '',
    this.modifiers = const [],
  });

  // Creates an OrderItem object from a Map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    // Convert map data to OrderItem object
    // Uses null coalescing to handle missing or null values
    return OrderItem(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
      notes: map['notes'] ?? '',
      modifiers: List<String>.from(map['modifiers'] ?? []),
    );
  }

  // Converts the OrderItem object to a Map for storage
  Map<String, dynamic> toMap() {
    // Create a map representation suitable for database storage
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'notes': notes,
      'modifiers': modifiers,
    };
  }

  // Calculates the total price for this item (price × quantity)
  double get totalPrice => price * quantity;
}
