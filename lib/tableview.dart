import 'package:flutter/material.dart';
import 'custom_icons_icons.dart';

class TableOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: List.generate(8, (index) => TableCard(index + 1)),
      ),
    );
  }
}

class TableCard extends StatelessWidget {
  final int tableNumber;
  TableCard(this.tableNumber);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Table $tableNumber',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text('Seated', style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 10),
          Text('Guests: ${tableNumber % 6 + 1}',
              style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}