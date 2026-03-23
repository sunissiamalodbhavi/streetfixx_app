import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';
import 'admin_issue_list_screen.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = _apiService.getAdminAnalytics();
  }

  Future<void> _refresh() async {
    setState(() {
      _analyticsFuture = _apiService.getAdminAnalytics();
    });
  }

  // Helper for generating standard text sizes
  TextStyle _titleStyle() => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
        letterSpacing: 0.5,
      );

  Widget _buildStatusSummaryCard({
    required String title,
    required String count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String roleTitle,
    required String roleType,
    required Map<String, dynamic> stats,
    required Color color,
    required IconData icon,
  }) {
    final t = stats['total'] ?? 0;
    final r = stats['resolved'] ?? 0;
    final a = stats['assigned'] ?? 0;
    final p = stats['pending'] ?? 0;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminIssueListScreen(
                role: roleType,
                title: roleTitle,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      roleTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textLight),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _roleStatItem('Total', t.toString(), Colors.blueGrey),
                  _roleStatItem('Resolved', r.toString(), const Color(0xFF81C784)),
                  _roleStatItem('Assigned', a.toString(), const Color(0xFFFFB74D)),
                  _roleStatItem('Pending', p.toString(), const Color(0xFFE57373)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationChart(List<dynamic> locations) {
    if (locations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No location data available.", style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    // Limit to top 5 for better chart visibility
    final topLocations = locations.take(5).toList();
    double maxCount = 0;
    
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < topLocations.length; i++) {
      final loc = topLocations[i];
      final count = (loc['count'] ?? 0).toDouble();
      if (count > maxCount) maxCount = count;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count,
              color: const Color(0xFF64B5F6),
              width: 22,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: (maxCount * 1.2) == 0 ? 5 : (maxCount * 1.2), // slightly higher background
                color: Colors.grey.withOpacity(0.1),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 20, right: 16, left: 0, bottom: 0),
      child: BarChart(
        BarChartData(
          barGroups: barGroups, // Properly bind the chart data here 
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxCount * 1.2) == 0 ? 5 : (maxCount * 1.2),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${topLocations[group.x.toInt()]['location']}\n${rod.toY.toInt()} issues',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= topLocations.length) return const SizedBox();
                  String locName = topLocations[value.toInt()]['location'].toString();
                  if (locName.length > 10) {
                     locName = '${locName.substring(0, 8)}...';
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      locName,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const SizedBox(); // Only show ints
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  );
                },
                reservedSize: 28,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxCount > 5 ? (maxCount / 5).ceilToDouble() : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildTrendsChart(List<dynamic> monthlyTrends) {
    if (monthlyTrends.isEmpty || monthlyTrends.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Not enough data for trend analysis.", style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    List<FlSpot> spots = [];
    double maxCount = 0;
    
    for (int i = 0; i < monthlyTrends.length; i++) {
      final count = (monthlyTrends[i]['count'] ?? 0).toDouble();
      if (count > maxCount) maxCount = count;
      spots.add(FlSpot(i.toDouble(), count));
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 0, bottom: 0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxCount > 5 ? (maxCount / 5).ceilToDouble() : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < monthlyTrends.length) {
                    final monthStr = monthlyTrends[index]['month'].toString();
                    // Split YYYY-MM and map to abbreviated month if possible
                    String displayLabel = monthStr;
                    if (monthStr.length == 7) {
                      final m = int.tryParse(monthStr.split('-')[1]);
                      if (m != null) {
                        const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                        if (m >= 1 && m <= 12) {
                          displayLabel = monthNames[m - 1];
                        }
                      }
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        displayLabel,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxCount > 5 ? (maxCount / 5).ceilToDouble() : 1,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const SizedBox();
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  );
                },
                reservedSize: 32,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (monthlyTrends.length - 1).toDouble(),
          minY: 0,
          maxY: (maxCount * 1.2) == 0 ? 5 : (maxCount * 1.2),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFCE93D8), // Pastel Purple
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xFFCE93D8),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFCE93D8).withOpacity(0.15),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toInt()} issues',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? {};
          final summary = data['summary'] ?? {};
          final roles = data['roles'] ?? {};
          final locations = (data['locations'] as List<dynamic>?) ?? [];
          final monthlyTrends = (data['monthly_trends'] as List<dynamic>?) ?? [];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Summary Cards
                  Text('Issue Status Summary', style: _titleStyle()),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatusSummaryCard(
                        title: 'Assigned',
                        count: (summary['assigned_issues'] ?? 0).toString(),
                        color: const Color(0xFFFFB74D), // Orange
                        icon: Icons.assignment_ind_outlined,
                      ),
                      _buildStatusSummaryCard(
                        title: 'Pending',
                        count: (summary['pending_issues'] ?? 0).toString(),
                        color: const Color(0xFFE57373), // Red
                        icon: Icons.pending_actions_outlined,
                      ),
                      _buildStatusSummaryCard(
                        title: 'Resolved',
                        count: (summary['resolved_issues'] ?? 0).toString(),
                        color: const Color(0xFF81C784), // Green
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 2. Role-based Issue Stats
                  Text('Role-based Statistics', style: _titleStyle()),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    roleTitle: 'Student Issues',
                    roleType: 'student',
                    stats: roles['student'] ?? {},
                    color: const Color(0xFF64B5F6),
                    icon: Icons.school_outlined,
                  ),
                  _buildRoleCard(
                    roleTitle: 'Hall Student Issues',
                    roleType: 'hall_student',
                    stats: roles['hall_student'] ?? {},
                    color: const Color(0xFF81C784),
                    icon: Icons.domain_outlined,
                  ),
                  _buildRoleCard(
                    roleTitle: 'Staff Issues',
                    roleType: 'staff',
                    stats: roles['staff'] ?? {},
                    color: const Color(0xFFFFB74D),
                    icon: Icons.work_outline,
                  ),
                  const SizedBox(height: 32),

                  // 3. Location Analysis (Bar Chart)
                  Text('Location Analysis', style: _titleStyle()),
                  const SizedBox(height: 8),
                  const Text(
                    'Top 5 locations with most reported issues',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: _buildLocationChart(locations),
                  ),
                  const SizedBox(height: 32),

                  // 4. Monthly Issue Trends (Line Chart)
                  Text('Monthly Trends', style: _titleStyle()),
                  const SizedBox(height: 8),
                  const Text(
                    'Issues reported over the last 6 months',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: _buildTrendsChart(monthlyTrends),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
