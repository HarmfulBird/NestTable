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
      backgroundColor: const Color(0xFF212224),
      appBar: AppBar(
        title: const Text(
          "Page Selector",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2F3031),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF212224),
            padding: const EdgeInsets.symmetric(
              vertical: 26.0,
              horizontal: 16.0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    pageConstructors.keys.map((String name) {
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
                            backgroundColor:
                                isSelected
                                    ? Colors.deepPurple
                                    : const Color(0xFF3E3F41),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: Text(name),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          Expanded(
            child:
                selectedPage != null
                    ? pageConstructors[selectedPage]!()
                    : const Center(
                      child: Text(
                        "No page selected",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
