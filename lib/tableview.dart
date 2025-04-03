import 'package:flutter/material.dart';
import 'datetime.dart'; // Your custom DateTimeBox class

class TableOverview extends StatefulWidget {
  const TableOverview({super.key});

  @override
  _TableOverviewState createState() => _TableOverviewState();
}

class _TableOverviewState extends State<TableOverview> {
  int? selectedTable; // Keeps track of the selected table

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 400,
                  padding: EdgeInsets.all(16.0),
                  color: Color(int.parse("0xFF2F3031")),
                  child: Column(
                    children: [
                      DateTimeBox(),
                      SizedBox(height: 20),
                      DisplayBox(selectedTable: selectedTable),
                    ],
                  ),
                ),

                // ---- Right Hand Area ----
                Expanded(
                  child:
                  Container(
                    color: Color(int.parse("0xFF212224")),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Number of columns
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 3 / 1.5, // Adjust this ratio for height control
                        ),
                        itemCount: 8, // Number of tables
                        itemBuilder: (context, index) => TableCard(
                          index + 1,
                          isSelected: selectedTable == (index + 1),
                          onTableSelected: (tableNumber) {
                            setState(() {
                              selectedTable = tableNumber; // Update the selected table
                            });
                          },
                        ),
                      ),
                    ),
                  )

                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DisplayBox extends StatelessWidget {
  final int? selectedTable;

  const DisplayBox({required this.selectedTable, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(int.parse("0xFF212224")),
        borderRadius: BorderRadius.circular(12),
      ),
      child: selectedTable != null
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Table $selectedTable',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Guests: Number Here',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
        ],
      )
          : Text(
        'No Table Selected',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 18,
        ),
      ),
    );
  }
}

class TableCard extends StatelessWidget {
  final int tableNumber;
  final bool isSelected;
  final Function(int) onTableSelected;

  const TableCard(this.tableNumber, {
    required this.isSelected,
    required this.onTableSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTableSelected(tableNumber),
      child: Stack(
        children: [
          // Main card content
          Container(
            decoration: BoxDecoration(
              color: Color(int.parse("0xFF2F3031")), // Background color
              borderRadius: BorderRadius.circular(15), // Rounded corners
            ),
            padding: EdgeInsets.all(20), // Inner padding for content
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Table $tableNumber',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White text color
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey, // Grey background for the box
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        '4', // Number inside the grey box
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.purple, // Purple box
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        'AR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                      width: 135,
                      height: 53,
                      alignment: Alignment.center, // Centers the child (text)
                      decoration: BoxDecoration(
                        color: Colors.red, // Red box for seating status
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown, // Scales down text to fit within the container
                        child: Text(
                          'Seated',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30, // Starting font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    // Stack for Guests Box with Overlay
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.fromLTRB(20, 5, 65, 5),
                          decoration: BoxDecoration(
                            color: Color(int.parse("0xFF676767")), // Grey box for guests
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'Guests', // Text inside the main box
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0, // Position the number in the top-right corner
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Color(int.parse("0xFF454545")), // Blue box for the overlay
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              '4', // Overlayed number
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Selection border overlay
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(int.parse("0xFF72D9FF")), width: 3), // Blue border
                  borderRadius: BorderRadius.circular(15), // Same rounded corners
                ),
              ),
            ),
        ],
      ),
    );
  }
}