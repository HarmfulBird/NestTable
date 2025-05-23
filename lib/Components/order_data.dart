import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderData {
  final String id;
  final int tableNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String notes;
  final Color statusColor;

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

  factory OrderData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

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

class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final String notes;
  final List<String> modifiers;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.notes = '',
    this.modifiers = const [],
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
      notes: map['notes'] ?? '',
      modifiers: List<String>.from(map['modifiers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'notes': notes,
      'modifiers': modifiers,
    };
  }

  double get totalPrice => price * quantity;
}
