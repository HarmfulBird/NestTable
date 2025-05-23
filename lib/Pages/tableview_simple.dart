import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../Components/datetime.dart';
import '../Components/tableview_data.dart';

class TableProvider extends ChangeNotifier {
  List<TableData> tables = [];
  bool isLoading = true;
  List<Map<String, dynamic>> reservations = [];

  TableProvider() {
    _listenToTables();
    _listenToReservations();
  }

  void _listenToReservations() {
    FirebaseFirestore.instance.collection('Reservations').snapshots().listen((
      snapshot,
    ) {
      reservations =
        snapshot.docs
          .map(
            (doc) => {
              'tableNumber': doc.data()['tableNumber'],
              'startTime': (doc.data()['startTime'] as Timestamp).toDate(),
              'seated': doc.data()['seated'] ?? false,
            },
          )
          .toList();
      _updateTableStatuses();
    });
  }

  void _updateTableStatuses() {
    final now = DateTime.now();

    for (var table in tables) {
      final tableReservations =
        reservations
          .where(
            (res) =>
              res['tableNumber'] == table.tableNumber &&
              res['startTime'].difference(now).inHours.abs() <= 2,
          )
          .toList();

      if (tableReservations.isEmpty) {
        _updateTableStatus(table.tableNumber, 'Open', Colors.green);
        continue;
      }

      final seatedReservation = tableReservations.any(
        (res) => res['seated'] == true,
      );
      if (seatedReservation) {
        _updateTableStatus(table.tableNumber, 'Seated', Colors.red);
        continue;
      }

      _updateTableStatus(table.tableNumber, 'Reserved', Colors.orange);
    }
  }

  void _updateTableStatus(int tableNumber, String status, Color statusColor) {
    FirebaseFirestore.instance
      .collection('Tables')
      .doc('table_$tableNumber')
      .update({'status': status});
  }

  void _listenToTables() {
    FirebaseFirestore.instance
      .collection('Tables')
      .orderBy('tableNumber')
      .snapshots()
      .listen((snapshot) {
        final List<TableData> updatedTables = [];
        for (var doc in snapshot.docs) {
          final data = doc.data();

          Color statusColor;
          switch (data['status']) {
            case 'Open':
              statusColor = Colors.green;
              break;
            case 'Seated':
              statusColor = Colors.red;
              break;
            case 'Reserved':
              statusColor = Colors.orange;
              break;
            default:
              statusColor = Colors.grey;
          }

          updatedTables.add(
            TableData(
              tableNumber: data['tableNumber'],
              capacity: data['capacity'],
              assignedServer: data['assignedServer'] ?? '',
              status: data['status'],
              statusColor: statusColor,
              currentGuests: data['currentGuests'] ?? 0,
            ),
          );
        }

        tables = updatedTables;
        isLoading = false;
        _updateTableStatuses();
        notifyListeners();
      });
  }
}

class TableOverview extends StatefulWidget {
  const TableOverview({super.key});

  @override
  TableOverviewState createState() => TableOverviewState();
}

class TableOverviewState extends State<TableOverview> {
  int? selectedTableIndex;

  @override
  Widget build(BuildContext context) {
    final tableProvider = Provider.of<TableProvider>(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 900;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body:
        isSmallScreen
          ? _buildMobileLayout(tableProvider)
          : _buildDesktopLayout(tableProvider),
    );
  }

  Widget _buildDesktopLayout(TableProvider tableProvider) {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      selectedTable:
                        selectedTableIndex != null
                          ? tableProvider.tables[selectedTableIndex!]
                          : null,
                    ),
                    const SizedBox(height: 20),
                    UpcomingBox(selectedTable: null),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  color: const Color(0xFF212224),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child:
                      tableProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : tableProvider.tables.isEmpty
                        ? const Center(
                          child: Text(
                            'No tables found',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        )
                        : _buildTablesGrid(tableProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(TableProvider tableProvider) {
    return Column(
      children: [
        ExpansionTile(
          title: const Text(
            'Table Information',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          backgroundColor: const Color(0xFF2F3031),
          collapsedBackgroundColor: const Color(0xFF2F3031),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          initiallyExpanded: false,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const DateTimeBox(),
                  const SizedBox(height: 20),
                  TableInfoBox(
                    selectedTable:
                      selectedTableIndex != null
                        ? tableProvider.tables[selectedTableIndex!]
                        : null,
                  ),
                  const SizedBox(height: 20),
                  UpcomingBox(selectedTable: null),
                ],
              ),
            ),
          ],
        ),

        Expanded(
          child: Container(
            color: const Color(0xFF212224),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child:
                tableProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : tableProvider.tables.isEmpty
                  ? const Center(
                    child: Text(
                      'No tables found',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  )
                  : _buildTablesGrid(tableProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTablesGrid(TableProvider tableProvider) {
    final width = MediaQuery.of(context).size.width;

    int crossAxisCount = 1;
    double childAspectRatio = 3 / 2;

    if (width > 1400) {
      crossAxisCount = 3;
      childAspectRatio = 3 / 1.5;
    } else if (width > 900) {
      crossAxisCount = 2;
      childAspectRatio = 3 / 1.5;
    } else if (width > 600) {
      crossAxisCount = 1;
      childAspectRatio = 3 / 1.2;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: GridView.builder(
        key: ValueKey(tableProvider.tables.length),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: tableProvider.tables.length,
        itemBuilder:
          (context, index) => TableCard(
            tableData: tableProvider.tables[index],
            isSelected: selectedTableIndex == index,
            onTableSelected: () {
              setState(() {
                selectedTableIndex = index;
              });
            },
          ),
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
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 600;
    final isMediumScreen = width >= 600 && width < 900;

    final tableFontSize = isSmallScreen ? 24.0 : 40.0;
    final baseFontSize = isSmallScreen ? 16.0 : (isMediumScreen ? 22.0 : 30.0);

    return InkWell(
      onTap: onTableSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: const Color(0xFF2F3031),
          border: Border.all(
            color: isSelected ? const Color(0xFF72D9FF) : Colors.transparent,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopRow(tableFontSize, baseFontSize, isSmallScreen),
            SizedBox(height: isSmallScreen ? 10 : 20),
            _buildBottomRow(baseFontSize, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow(
    double tableFontSize,
    double baseFontSize,
    bool isSmallScreen,
  ) {
    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Table ${tableData.tableNumber}',
            style: TextStyle(
              fontSize: tableFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${tableData.capacity}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: baseFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tableData.assignedServer,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: baseFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Text(
            'Table ${tableData.tableNumber}',
            style: TextStyle(
              fontSize: tableFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '${tableData.capacity}',
              style: TextStyle(
                color: Colors.white,
                fontSize: baseFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              tableData.assignedServer,
              style: TextStyle(
                color: Colors.white,
                fontSize: baseFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildBottomRow(double baseFontSize, bool isSmallScreen) {
    final double statusWidth = isSmallScreen ? 110 : 135;
    final double statusHeight = isSmallScreen ? 40 : 53;
    final double borderRadius = isSmallScreen ? 10 : 15;
    final EdgeInsets padding =
      isSmallScreen
        ? const EdgeInsets.symmetric(vertical: 4, horizontal: 12)
        : const EdgeInsets.symmetric(vertical: 5, horizontal: 20);

    return Row(
      children: [
        Container(
          padding: padding,
          width: statusWidth,
          height: statusHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tableData.statusColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              tableData.status,
              style: TextStyle(
                color: Colors.white,
                fontSize: baseFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 15),
        Stack(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 12 : 15,
                isSmallScreen ? 4 : 5,
                isSmallScreen ? 40 : 64,
                isSmallScreen ? 4 : 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF676767),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Text(
                'Guests',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: baseFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: const Color(0xFF454545),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: Text(
                  '${tableData.currentGuests}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: baseFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
