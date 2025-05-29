import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Services/analytics_service.dart';
import 'DataUploaders/uploader_selector.dart';

// Main dashboard widget for restaurant management analytics
// Provides daily, weekly, and monthly insights with real-time data
class ManagementDashboard extends StatefulWidget {
  const ManagementDashboard({super.key});

  @override
  ManagementDashboardState createState() => ManagementDashboardState();
}

// State class managing dashboard data, tabs, and UI interactions
class ManagementDashboardState extends State<ManagementDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedPeriod = 'Daily';
  Map<String, dynamic> currentStats = {};
  bool isLoading = true;
  @override
  // Initializes the tab controller and loads initial statistics data
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          selectedPeriod = ['Daily', 'Weekly', 'Monthly'][_tabController.index];
        });
        _loadStats();
      }
    });
    _loadStats();
  }

  @override
  // Cleans up the tab controller when widget is destroyed
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Loads analytics statistics based on the selected time period
  Future<void> _loadStats() async {
    // Set loading state to show progress indicator
    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic> stats;
      // Fetch appropriate statistics based on selected period
      switch (selectedPeriod) {
        case 'Daily':
          stats = await AnalyticsService.getDailyStats();
          break;
        case 'Weekly':
          stats = await AnalyticsService.getWeeklyStats();
          break;
        case 'Monthly':
          stats = await AnalyticsService.getMonthlyStats();
          break;
        default:
          stats = await AnalyticsService.getDailyStats();
      }

      // Update state with fetched data and stop loading
      setState(() {
        currentStats = stats;
        isLoading = false;
      });
    } catch (e) {
      // Handle errors by storing error message and stopping loading
      setState(() {
        currentStats = {'error': 'Failed to load stats: $e'};
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Main scaffold providing the dashboard structure with tabs and content
    return Scaffold(
      backgroundColor: const Color(0xFF212224),
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: const Text(
            'Management Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF2F3031),
        // Action buttons for refreshing data and navigating to data management
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Refresh Data',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {
                // Navigate to data management/upload page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PageSelector()),
                );
              },
              icon: const Icon(Icons.upload, color: Colors.white),
              label: const Text(
                'Data Management',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
        // Tab bar for switching between Daily, Weekly, and Monthly views
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      // Conditional body rendering based on loading state and data availability
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              )
              : currentStats.containsKey('error')
              ? _buildErrorWidget()
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardContent('Daily'),
                  _buildDashboardContent('Weekly'),
                  _buildDashboardContent('Monthly'),
                ],
              ),
    );
  }

  // Builds an error display widget when data loading fails
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 20),
          const Text(
            'Error Loading Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              currentStats['error'] ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _loadStats,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Builds the main dashboard content with refreshable sections and widgets
  Widget _buildDashboardContent(String period) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      color: Colors.deepPurple,
      backgroundColor: const Color(0xFF2F3031),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with period title and revenue information
            _buildHeaderSection(period),
            const SizedBox(height: 20),
            // Grid of key performance metrics
            _buildQuickStatsGrid(),
            const SizedBox(height: 20),
            // Real-time data streams for tables and orders
            _buildRealTimeSection(), const SizedBox(height: 20),
            // Period-specific widgets for additional insights
            if (period == 'Weekly') _buildWeeklySpecificWidgets(),
            if (period == 'Monthly') _buildMonthlySpecificWidgets(),
          ],
        ),
      ),
    );
  }

  // Builds the header section with period title, date range, and revenue summary
  Widget _buildHeaderSection(String period) {
    final now = DateTime.now();
    String dateRange;

    // Calculate appropriate date range based on selected period
    switch (period) {
      case 'Daily':
        dateRange = DateFormat('EEEE, MMMM d, y').format(now);
        break;
      case 'Weekly':
        // Calculate start of current week (Monday) and end (Sunday)
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        dateRange =
            '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, y').format(weekEnd)}';
        break;
      case 'Monthly':
        dateRange = DateFormat('MMMM y').format(now);
        break;
      default:
        dateRange = DateFormat('MMMM d, y').format(now);
    }

    // Return styled header container with gradient background
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period title (Daily/Weekly/Monthly Report)
          Text(
            '$period Report',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Formatted date range for the selected period
          Text(
            dateRange,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          // Revenue display with trending icon
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'Revenue: \$${(currentStats['totalRevenue'] ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Builds a grid of quick statistics cards showing key metrics
  Widget _buildQuickStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        // Total orders statistic card
        _buildStatCard(
          'Orders',
          (currentStats['totalOrders'] ?? 0).toString(),
          Icons.receipt_long,
          Colors.blue,
        ),
        // Total reservations statistic card
        _buildStatCard(
          'Reservations',
          (currentStats['totalReservations'] ?? 0).toString(),
          Icons.event_seat,
          Colors.green,
        ),
        // Average order value statistic card
        _buildStatCard(
          'Avg Order Value',
          '\$${(currentStats['averageOrderValue'] ?? 0.0).toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.orange,
        ),
        // Table occupancy percentage statistic card
        _buildStatCard(
          'Table Occupancy',
          '${(currentStats['tableOccupancy'] ?? 0.0).toStringAsFixed(1)}%',
          Icons.table_restaurant,
          Colors.purple,
        ),
      ],
    );
  }

  // Builds an individual statistic card with title, value, icon, and color
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2F3031),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top row with title and icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 42),
            ],
          ),
          // Large value display with accent color
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 46,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Builds real-time status section with live table and order data streams
  Widget _buildRealTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Real-Time Status',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Table status card with live data stream
            Expanded(
              child: _buildRealTimeCard(
                'Table Status',
                StreamBuilder<Map<String, dynamic>>(
                  stream: AnalyticsService.getTableStatusStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text(
                        'Loading...',
                        style: TextStyle(color: Colors.white70),
                      );
                    }
                    final data = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seated: ${data['seated']}/${data['total']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Open: ${data['open']}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Reserved: ${data['reserved']}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Icons.table_chart,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            // Active orders card with live data stream
            Expanded(
              child: _buildRealTimeCard(
                'Active Orders',
                StreamBuilder<Map<String, dynamic>>(
                  stream: AnalyticsService.getOrdersStatusStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text(
                        'Loading...',
                        style: TextStyle(color: Colors.white70),
                      );
                    }
                    final data = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total: ${data['total']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Pending: ${data['pending']}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'In Progress: ${data['inProgress']}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Icons.restaurant_menu,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Builds a real-time data card with streaming content
  Widget _buildRealTimeCard(
    String title,
    Widget content,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2F3031),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  // Builds weekly-specific widgets including staff performance data
  Widget _buildWeeklySpecificWidgets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Performance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2F3031),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Staff Performance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (currentStats['staffPerformance'] != null)
                ...(currentStats['staffPerformance'] as Map<String, int>)
                  .entries
                  .take(5)
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '${entry.value} orders',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )

              else
                const Text(
                  'No staff performance data available',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Builds monthly-specific widgets including popular menu items data
  Widget _buildMonthlySpecificWidgets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Insights',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2F3031),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Popular Menu Items',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (currentStats['popularItems'] != null)
                ...(currentStats['popularItems'] as List<MapEntry<String, int>>)
                  .take(5)
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(color: Colors.white70),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${entry.value} orders',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )

              else
                const Text(
                  'No menu item data available',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
