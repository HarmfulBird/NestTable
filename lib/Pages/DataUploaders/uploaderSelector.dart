import 'package:flutter/material.dart';
import 'Uploaders/tableDataUploader.dart';
import 'Uploaders/staffDataUploader.dart';
import 'Uploaders/reservationDataUploader.dart';

class PageSelector extends StatefulWidget {
  @override
  _PageSelectorState createState() => _PageSelectorState();
}

class _PageSelectorState extends State<PageSelector> {
  String? selectedPage;

  final Map<String, Widget Function()> pageConstructors = {
    'Table Data': () => TableDataUploader(),
    'Staff Data': () => StaffDataUploader(),
    'Reservation Data': () => ReservationDataUploader(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Page Selector")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: pageConstructors.keys.map((String name) {
                  final isSelected = selectedPage == name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedPage = name;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
                        foregroundColor: isSelected ? Colors.white : null,
                      ),
                      child: Text(name),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: selectedPage != null
                ? pageConstructors[selectedPage]!()
                : Center(child: Text("No page selected")),
          ),
        ],
      ),
    );
  }
}
