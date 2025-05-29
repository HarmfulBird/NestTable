import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetches daily statistics including orders, reservations, revenue, and table occupancy for today
  static Future<Map<String, dynamic>> getDailyStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    try {
      final ordersSnapshot =
        await _firestore
          .collection('Orders')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(today),
          )
          .where('createdAt', isLessThan: Timestamp.fromDate(tomorrow))
          .get();

      final reservationsSnapshot =
        await _firestore
          .collection('Reservations')
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(today),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(tomorrow))
          .get();

      double totalRevenue = 0;
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          totalRevenue += (data['totalAmount'] ?? 0.0).toDouble();
        }
      }

      double averageOrderValue =
        ordersSnapshot.docs.isNotEmpty
          ? totalRevenue / ordersSnapshot.docs.length
          : 0;

      final tablesSnapshot = await _firestore.collection('Tables').get();
      int totalTables = tablesSnapshot.docs.length;
      int seatedTables =
        tablesSnapshot.docs
          .where((doc) => doc.data()['status'] == 'Seated')
          .length;
      double occupancyRate =
        totalTables > 0 ? (seatedTables / totalTables) * 100 : 0;

      return {
        'totalOrders': ordersSnapshot.docs.length,
        'totalReservations': reservationsSnapshot.docs.length,
        'totalRevenue': totalRevenue,
        'averageOrderValue': averageOrderValue,
        'tableOccupancy': occupancyRate,
        'seatedTables': seatedTables,
        'totalTables': totalTables,
      };
    } catch (e) {
      return {
        'error': 'Failed to fetch daily stats: $e',
        'totalOrders': 0,
        'totalReservations': 0,
        'totalRevenue': 0.0,
        'averageOrderValue': 0.0,
        'tableOccupancy': 0.0,
        'seatedTables': 0,
        'totalTables': 0,
      };
    }
  }

  // Retrieves weekly statistics with daily revenue breakdown and staff performance data
  static Future<Map<String, dynamic>> getWeeklyStats() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    final weekEndDate = weekStartDate.add(const Duration(days: 7));

    try {
      final ordersSnapshot =
        await _firestore
          .collection('Orders')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartDate),
          )
          .where('createdAt', isLessThan: Timestamp.fromDate(weekEndDate))
          .get();

      final reservationsSnapshot =
        await _firestore
          .collection('Reservations')
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartDate),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(weekEndDate))
          .get();

      double totalRevenue = 0;
      Map<String, double> dailyRevenue = {};
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          final amount = (data['totalAmount'] ?? 0.0).toDouble();
          totalRevenue += amount;

          final orderDate = (data['createdAt'] as Timestamp).toDate();
          final dayKey = '${orderDate.day}/${orderDate.month}';
          dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) + amount;
        }
      }

      Map<String, int> staffOrderCounts = {};
      for (var doc in ordersSnapshot.docs) {
        final tableNumber = doc.data()['tableNumber'];
        if (tableNumber != null) {
          final tableDoc =
            await _firestore
              .collection('Tables')
              .doc('table_$tableNumber')
              .get();
          if (tableDoc.exists) {
            final server = tableDoc.data()?['assignedServer'] ?? 'Unknown';
            staffOrderCounts[server] = (staffOrderCounts[server] ?? 0) + 1;
          }
        }
      }

      return {
        'totalOrders': ordersSnapshot.docs.length,
        'totalReservations': reservationsSnapshot.docs.length,
        'totalRevenue': totalRevenue,
        'dailyRevenue': dailyRevenue,
        'staffPerformance': staffOrderCounts,
        'averageOrdersPerDay': ordersSnapshot.docs.length / 7,
      };
    } catch (e) {
      return {
        'error': 'Failed to fetch weekly stats: $e',
        'totalOrders': 0,
        'totalReservations': 0,
        'totalRevenue': 0.0,
        'dailyRevenue': <String, double>{},
        'staffPerformance': <String, int>{},
        'averageOrdersPerDay': 0.0,
      };
    }
  }

  // Gets monthly statistics including popular items and reservation trends
  static Future<Map<String, dynamic>> getMonthlyStats() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    try {
      final ordersSnapshot =
        await _firestore
          .collection('Orders')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          .where('createdAt', isLessThan: Timestamp.fromDate(monthEnd))
          .get();

      final reservationsSnapshot =
        await _firestore
          .collection('Reservations')
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(monthEnd))
          .get();

      Map<String, int> itemOrderCounts = {};
      double totalRevenue = 0;

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          totalRevenue += (data['totalAmount'] ?? 0.0).toDouble();
        }
        final items = data['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          final itemName = item['name'] ?? 'Unknown';
          final quantity = (item['quantity'] ?? 1) as int;
          itemOrderCounts[itemName] = (itemOrderCounts[itemName] ?? 0) + quantity;
        }
      }

      final popularItems =
        itemOrderCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      Map<String, int> reservationTrends = {};
      for (var doc in reservationsSnapshot.docs) {
        final startTime = (doc.data()['startTime'] as Timestamp).toDate();
        final weekKey = 'Week ${((startTime.day - 1) / 7).floor() + 1}';
        reservationTrends[weekKey] = (reservationTrends[weekKey] ?? 0) + 1;
      }

      return {
        'totalOrders': ordersSnapshot.docs.length,
        'totalReservations': reservationsSnapshot.docs.length,
        'totalRevenue': totalRevenue,
        'popularItems': popularItems.take(10).toList(),
        'reservationTrends': reservationTrends,
        'averageOrdersPerDay': ordersSnapshot.docs.length / DateTime.now().day,
      };
    } catch (e) {
      return {
        'error': 'Failed to fetch monthly stats: $e',
        'totalOrders': 0,
        'totalReservations': 0,
        'totalRevenue': 0.0,
        'popularItems': <MapEntry<String, int>>[],
        'reservationTrends': <String, int>{},
        'averageOrdersPerDay': 0.0,
      };
    }
  }

  // Provides real-time stream of table status counts and occupancy rate
  static Stream<Map<String, dynamic>> getTableStatusStream() {
    return _firestore.collection('Tables').snapshots().map((snapshot) {
      int totalTables = snapshot.docs.length;
      int openTables = 0;
      int seatedTables = 0;
      int reservedTables = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] ?? 'Open';
        switch (status) {
          case 'Open':
            openTables++;
            break;
          case 'Seated':
            seatedTables++;
            break;
          case 'Reserved':
            reservedTables++;
            break;
        }
      }

      return {
        'total': totalTables,
        'open': openTables,
        'seated': seatedTables,
        'reserved': reservedTables,
        'occupancyRate': totalTables > 0 ? (seatedTables / totalTables) * 100 : 0.0,
      };
    });
  }

  // Returns live stream of pending and in-progress order counts
  static Stream<Map<String, dynamic>> getOrdersStatusStream() {
    return _firestore
      .collection('Orders')
      .where('status', whereIn: ['pending', 'in-progress'])
      .snapshots()
      .map((snapshot) {
        int pendingOrders = 0;
        int inProgressOrders = 0;

        for (var doc in snapshot.docs) {
          final status = doc.data()['status'] ?? 'pending';
          switch (status) {
            case 'pending':
              pendingOrders++;
              break;
            case 'in-progress':
              inProgressOrders++;
              break;
          }
        }

        return {
          'pending': pendingOrders,
          'inProgress': inProgressOrders,
          'total': pendingOrders + inProgressOrders,
        };
      });
  }

  // Streams today's total revenue from completed orders in real-time
  static Stream<double> getTodayRevenueStream() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _firestore
      .collection('Orders')
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
      .where('createdAt', isLessThan: Timestamp.fromDate(tomorrow))
      .where('status', isEqualTo: 'completed')
      .snapshots()
      .map((snapshot) {
        double totalRevenue = 0;
        for (var doc in snapshot.docs) {
          totalRevenue += (doc.data()['totalAmount'] ?? 0.0).toDouble();
        }
        return totalRevenue;
      });
  }
}
