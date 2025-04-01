import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:monet/controller/auth.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/utils/helper.dart';

class TransactionItem {
  final IconData icon;
  final String label;
  final String description;
  final String amount;
  final Color amountColor;
  final String time;

  TransactionItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.amount,
    required this.amountColor,
    required this.time,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dynamic data variables
  double accountBalance = 0;
  double income = 0;
  double expenses = 0;
  List<double> spendData = [];
  List<TransactionItem> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    // Simulate fetching data from a backend or local database
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      accountBalance = 9400;
      income = 5000;
      expenses = 1200;
      // Simulated spend data for 7 days (could be percentages or amounts)
      spendData = [10, 20, 30, 40, 50, 60, 70];
      // Simulated recent transactions
      transactions = [
        TransactionItem(
          icon: Icons.shopping_bag,
          label: 'Shopping',
          description: 'Buy some grocery',
          amount: '- \$120',
          amountColor: Colors.red,
          time: '10:00 AM',
        ),
        TransactionItem(
          icon: Icons.subscriptions,
          label: 'Subscription',
          description: 'Disney+ Annual...',
          amount: '- \$80',
          amountColor: Colors.red,
          time: '12:00 PM',
        ),
        TransactionItem(
          icon: Icons.fastfood,
          label: 'Food',
          description: 'Buy a ramen',
          amount: '- \$32',
          amountColor: Colors.red,
          time: '07:30 PM',
        ),
      ];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.backgroundColor,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              // Header section with gradient background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFAE6D3), // Example gradient start
                      Color(0xFFFFF7EC), // Example gradient end
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    // Top row: month and user avatar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'October', // Make this dynamic as needed
                          style: AppStyles.bold(size: 20),
                        ),
                        InkWell(
                          onTap: () {
                            // Navigate to profile or open a menu
                          },
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundImage: AssetImage('assets/images/avatar.png'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Account Balance
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Account Balance',
                        style: AppStyles.regular1(
                          size: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '₱${accountBalance.toStringAsFixed(0)}',
                        style: AppStyles.titleX(size: 36, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Row with Income & Expenses Cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCard(
                          label: 'Income',
                          amount: '₱${income.toStringAsFixed(0)}',
                          backgroundColor: const Color(0xFFE1F6EC),
                          textColor: const Color(0xFF27AE60),
                        ),
                        _buildCard(
                          label: 'Expenses',
                          amount: '₱${expenses.toStringAsFixed(0)}',
                          backgroundColor: const Color(0xFFFFECEB),
                          textColor: const Color(0xFFEB5757),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Spend Frequency Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spend Frequency', style: AppStyles.medium(size: 18)),
                    const SizedBox(height: 16),
                    // Bar chart using fl_chart for dynamic spend data
                    SizedBox(
                      height: 150,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: spendData.isNotEmpty ? spendData.reduce((a, b) => a > b ? a : b) + 10 : 100,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  switch (value.toInt()) {
                                    case 0: return const Text('Mon');
                                    case 1: return const Text('Tue');
                                    case 2: return const Text('Wed');
                                    case 3: return const Text('Thu');
                                    case 4: return const Text('Fri');
                                    case 5: return const Text('Sat');
                                    case 6: return const Text('Sun');
                                    default: return const Text('');
                                  }
                                },
                                reservedSize: 42,
                                // Removed margin parameter
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  return Text(value.toInt().toString());
                                },
                                reservedSize: 32,
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(spendData.length, (index) {
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: spendData[index],
                                  color: AppColours.primaryColour,
                                  width: 16,
                                )
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Segmented Tabs and See All Option
                    Row(
                      children: [
                        _buildSegment(label: 'Today', isActive: true),
                        _buildSegment(label: 'Week'),
                        _buildSegment(label: 'Month'),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            // Navigate or show full spend frequency data
                          },
                          child: Text(
                            'See All',
                            style: AppStyles.regular1(color: AppColours.primaryColour),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Recent Transactions Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Transaction', style: AppStyles.medium(size: 18)),
                    const SizedBox(height: 16),
                    ...transactions.map((transaction) =>
                        _buildTransactionItem(
                          icon: transaction.icon,
                          label: transaction.label,
                          description: transaction.description,
                          amount: transaction.amount,
                          amountColor: transaction.amountColor,
                          time: transaction.time,
                        ),
                    ).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for Income/Expenses cards
  Widget _buildCard({
    required String label,
    required String amount,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: AppStyles.medium(color: textColor, size: 16)),
          const SizedBox(height: 8),
          Text(amount, style: AppStyles.bold(color: textColor, size: 20)),
        ],
      ),
    );
  }

  // Helper widget for segmented labels in the spend frequency section
  Widget _buildSegment({required String label, bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Text(
        label,
        style: isActive
            ? AppStyles.medium(color: Colors.black, size: 16)
            : AppStyles.regular1(color: Colors.grey, size: 16),
      ),
    );
  }

  // Helper widget for displaying a transaction item
  Widget _buildTransactionItem({
    required IconData icon,
    required String label,
    required String description,
    required String amount,
    required Color amountColor,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColours.inputBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          // Label and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppStyles.medium(size: 16)),
                const SizedBox(height: 4),
                Text(description, style: AppStyles.regular1(color: Colors.grey, size: 14)),
              ],
            ),
          ),
          // Amount and time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: AppStyles.bold(color: amountColor, size: 16)),
              const SizedBox(height: 4),
              Text(time, style: AppStyles.regular1(color: Colors.grey, size: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
