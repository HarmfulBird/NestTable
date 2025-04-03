import 'package:flutter/material.dart';
import 'datetime.dart';
import 'tabledata.dart';
import 'dart:math';



class TableOverview extends StatefulWidget {
  const TableOverview({super.key});

  @override
  _TableOverviewState createState() => _TableOverviewState();
}

class _TableOverviewState extends State<TableOverview> {
  int? selectedTableIndex;
  List<TableData> tables = [];
  final Random _random = Random();


  // ------ FAKE DATA START ------

  final List<String> serverInitialsList = ['AR', 'CR', 'JD', 'LS', 'MB', 'TK'];

  @override
  void initState() {
    super.initState();
    // Initialize table data - in a real app, you would fetch this from a database or API
    _initializeTableData();
  }


  String _getRandomServerInitials() {
    return serverInitialsList[_random.nextInt(serverInitialsList.length)];
  }

  void _initializeTableData() {
    for (int i = 1; i <= 8; i++) {
      String status = i % 3 == 0 ? 'Open' : (i % 2 == 0 ? 'Seated' : 'Reserved');

      tables.add(
        TableData(
          tableNumber: i,
          capacity: 4,
          serverInitials: _getRandomServerInitials(),
          status: status,
          statusColor:
          status == 'Open' ? Colors.green :
          (status == 'Seated' ? Colors.red : Colors.orange),
          currentGuests: status == 'Open' ? 0 : (i % 4 + 1),
        ),
      );
    }
  }
  // ------ FAKE DATA END ------

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
                  padding: const EdgeInsets.all(16.0),
                  color: const Color(0xFF2F3031),
                  child: Column(
                    children: [
                      const DateTimeBox(),
                      const SizedBox(height: 20),
                      TableInfoBox(
                        selectedTable: selectedTableIndex != null ? tables[selectedTableIndex!] : null,
                      ),
                      const SizedBox(height: 20),
                      UpcomingBox(selectedTable: null)
                    ],
                  ),
                ),

                // ---- Right Hand Area ----
                Expanded(
                  child: Container(
                    color: const Color(0xFF212224),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 3 / 1.5, // Adjust this ratio for height control
                        ),
                        itemCount: tables.length, // Number of tables
                        itemBuilder: (context, index) => TableCard(
                          tableData: tables[index],
                          isSelected: selectedTableIndex == index,
                          onTableSelected: () {
                            setState(() {
                              selectedTableIndex = index;
                            });
                          },
                        ),
                      ),
                    ),
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

class TableCard extends StatelessWidget {
  final TableData tableData;
  final bool isSelected;
  final VoidCallback onTableSelected;

  const TableCard({
    required this.tableData,
    required this.isSelected,
    required this.onTableSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTableSelected,
      child: Stack(
        children: [
          // Main card content
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2F3031),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Table ${tableData.tableNumber}',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        '${tableData.capacity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        tableData.serverInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                      width: 135,
                      height: 53,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tableData.statusColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tableData.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 5, 65, 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF676767),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Text(
                            'Guests',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF454545),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              '${tableData.currentGuests}',
                              style: const TextStyle(
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
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF72D9FF), width: 3),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}