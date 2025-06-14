import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:monet/controller/account.dart';
import 'package:monet/controller/transaction.dart';
import 'package:monet/controller/notification.dart';
import 'package:monet/models/account.dart';
import 'package:monet/models/transaction.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/resources/app_spacing.dart';
import 'package:monet/views/dashboard/budget.dart';
import 'package:monet/views/dashboard/expense.dart';
import 'package:monet/views/dashboard/income.dart';
import 'package:monet/views/dashboard/profile.dart';
import 'package:monet/views/dashboard/transaction.dart';
import 'package:monet/views/dashboard/transfer.dart';
import 'package:monet/controller/account_type.dart';
import 'package:monet/views/profile/notification.dart';
import 'package:monet/services/auth_service.dart';
import 'package:monet/models/user.dart';
import 'dart:io';

enum TransactionFilter { today, week, month }

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
  List<double> spendData = [0, 0, 0, 0, 0, 0, 0]; // Weekly spend data (7 days)
  List<TransactionModel> allTransactions = []; // Store ALL transactions
  List<TransactionModel> monthlyTransactions = []; // Transactions for selected month
  List<TransactionModel> filteredTransactions = [];
  List<AccountModel> accounts = [];
  List<dynamic> categories = [];
  bool isLoading = true;
  int _currentIndex = 0;
  bool _isAddMenuOpen = false;
  String defaultCurrencySymbol = '\₱';
  int unreadCount = 0;

  UserModel? _user;
  File? _avatarFile;

  // Selected date for filtering
  DateTime selectedDate = DateTime.now();

  // Transaction filter state
  TransactionFilter currentFilter = TransactionFilter.today;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
    _loadUnreadCount();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.get();
    setState(() {
      _user = user;
      if (_user?.avatar != null && _user!.avatar!.isNotEmpty) {
        _avatarFile = File(_user!.avatar!);
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    final result = await NotificationController.getUnreadCount();
    if (mounted && result.isSuccess) {
      setState(() {
        unreadCount = result.results ?? 0;
      });
    }
  }

  Future<void> loadDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load accounts first to get currency information
      final accountResult = await AccountController.load();
      if (accountResult.isSuccess && accountResult.results != null) {
        accounts = accountResult.results!;
        // Set default currency from first account (if exists)
        if (accounts.isNotEmpty) {
          defaultCurrencySymbol = accounts[0].currency.symbol;

          // Calculate total account balance from all accounts
          accountBalance = accounts.fold(0.0, (sum, account) => sum + account.currentBalance);
        }
      }

      // Load account types explicitly to solve the issue with different users
      await AccountTypeController.load();

      // Load ALL transactions (no filtering at this stage)
      final transactionResult = await TransactionController.loadTransactions();
      if (transactionResult.isSuccess && transactionResult.results != null) {
        allTransactions = transactionResult.results!;

        // Sort ALL transactions by date (newest first)
        allTransactions.sort((a, b) =>
            DateTime.parse(b.transactionDate).compareTo(
                DateTime.parse(a.transactionDate))
        );

        // Filter transactions for the selected month for display and calculations
        _filterTransactionsForSelectedMonth();

        // Apply transaction filter and update spending data
        _applyTransactionFilter();
        _updateSpendingData();
      }
    } catch (e) {
      print("Error loading dashboard data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterTransactionsForSelectedMonth() {
    // Filter transactions based on selected date (month and year) for monthly calculations
    monthlyTransactions = allTransactions.where((transaction) {
      final transDate = DateTime.parse(transaction.transactionDate);
      return transDate.month == selectedDate.month &&
          transDate.year == selectedDate.year;
    }).toList();

    // Calculate income and expenses for the selected month
    income = 0;
    expenses = 0;

    for (var transaction in monthlyTransactions) {
      if (transaction.type.toLowerCase() == 'income') {
        income += transaction.amount;
      } else if (transaction.type.toLowerCase() == 'expense') {
        expenses += transaction.amount;
      }
    }
  }

  void _applyTransactionFilter() {
    final now = DateTime.now();

    switch (currentFilter) {
      case TransactionFilter.today:
        // Filter for today - transactions matching selected date
        filteredTransactions = allTransactions.where((transaction) {
          final transDate = DateTime.parse(transaction.transactionDate);
          return transDate.year == selectedDate.year &&
              transDate.month == selectedDate.month &&
              transDate.day == selectedDate.day;
        }).toList();
        break;

      case TransactionFilter.week:
        // Calculate start of selected week (Monday)
        final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final endOfWeekDate = startOfWeekDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
        filteredTransactions = allTransactions.where((transaction) {
          try {
            final transDate = DateTime.parse(transaction.transactionDate);
            // Include transactions on or after the start date and on or before the end date
            return (transDate.isAtSameMomentAs(startOfWeekDate) || transDate.isAfter(startOfWeekDate)) &&
                   (transDate.isAtSameMomentAs(endOfWeekDate) || transDate.isBefore(endOfWeekDate));
          } catch (e) {
            // Handle invalid dates
            print("Invalid date format: ${transaction.transactionDate}, Error: $e");
            return false;
          }
        }).toList();
        break;

      case TransactionFilter.month:
        // Use transactions from the selected month
        filteredTransactions = monthlyTransactions;
        break;
    }

    // Sort filtered transactions by date (newest first)
    filteredTransactions.sort((a, b) {
      try {
        return DateTime.parse(b.transactionDate).compareTo(
            DateTime.parse(a.transactionDate));
      } catch (e) {
        // Handle invalid dates
        return 0;
      }
    });
  }

  void _updateSpendingData() {
    // Initialize spend data for 7 days (Monday to Sunday)
    spendData = [0, 0, 0, 0, 0, 0, 0];

    final now = DateTime.now();

    switch (currentFilter) {
      case TransactionFilter.today:
      // For today, show hourly data (simplified to single day value)
        final todayExpenses = filteredTransactions.where((transaction) =>
        transaction.type.toLowerCase() == 'expense'
        ).fold(0.0, (sum, transaction) => sum + transaction.amount);

        // Set today's expenses at the current weekday position
        final todayWeekday = selectedDate.weekday - 1; // Convert to 0-6 (Mon-Sun)
        if (todayWeekday >= 0 && todayWeekday < 7) {
          spendData[todayWeekday] = todayExpenses;
        }
        break;

      case TransactionFilter.week:
      // For week, show daily data for the current week using ALL transactions
        final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

        for (int i = 0; i < 7; i++) {
          final day = startOfWeek.add(Duration(days: i));
          final dayExpenses = allTransactions.where((transaction) {
            final transDate = DateTime.parse(transaction.transactionDate);
            return transDate.year == day.year &&
                transDate.month == day.month &&
                transDate.day == day.day &&
                transaction.type.toLowerCase() == 'expense';
          }).fold(0.0, (sum, transaction) => sum + transaction.amount);

          spendData[i] = dayExpenses;
        }
        break;

      case TransactionFilter.month:
      // For month, show weekly data (average daily spending for each day of week) using monthly transactions
        final Map<int, List<double>> weeklyData = {0: [], 1: [], 2: [], 3: [], 4: [], 5: [], 6: []};

        for (var transaction in monthlyTransactions) {
          if (transaction.type.toLowerCase() == 'expense') {
            final transDate = DateTime.parse(transaction.transactionDate);
            final weekday = transDate.weekday - 1; // Convert to 0-6
            if (weekday >= 0 && weekday < 7) {
              weeklyData[weekday]!.add(transaction.amount);
            }
          }
        }

        // Calculate average for each day of the week
        for (int i = 0; i < 7; i++) {
          if (weeklyData[i]!.isNotEmpty) {
            spendData[i] = weeklyData[i]!.reduce((a, b) => a + b) / weeklyData[i]!.length;
          }
        }
        break;
    }
  }

  void _onFilterChanged(TransactionFilter filter) {
    setState(() {
      currentFilter = filter;
      _applyTransactionFilter();
      _updateSpendingData();
    });
  }

  // Helper method to get icon based on transaction category or type
  IconData _getTransactionIcon(TransactionModel transaction) {
    // Special icon for transfers
    if (transaction.type.toLowerCase() == 'transfer') {
      return Icons.swap_horiz;
    }

    if (transaction.category == null) {
      return transaction.type.toLowerCase() == 'income'
          ? Icons.arrow_downward
          : Icons.arrow_upward;
    }

    switch (transaction.category!.icon?.toLowerCase() ?? '') {
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_cart;
      case 'transport':
        return Icons.directions_car;
      case 'bills':
        return Icons.receipt;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'housing':
        return Icons.home;
      default:
        return transaction.type.toLowerCase() == 'income'
            ? Icons.arrow_downward
            : Icons.arrow_upward;
    }
  }

  // Improved transaction icon selection - considers category and type more effectively
  IconData _getTransactionIconV2(TransactionModel transaction) {
    if (transaction.type.toLowerCase() == 'transfer') {
      return Icons.swap_horiz;
    }

    switch (transaction.category?.name?.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_cart;
      case 'transport':
        return Icons.directions_car;
      case 'bills':
        return Icons.receipt;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'housing':
        return Icons.home;
      default:
        // Fallback to type-based icons
        return transaction.type.toLowerCase() == 'income'
            ? Icons.arrow_downward
            : Icons.arrow_upward;
    }
  }

  // Helper method to get color based on transaction type
  Color _getTransactionColor(TransactionModel transaction) {
    if (transaction.type.toLowerCase() == 'transfer') {
      return AppColours.primaryColour;
    } else if (transaction.type.toLowerCase() == 'income') {
      return AppColours.incomeColor;
    } else {
      return AppColours.expenseColor;
    }
  }

  // Helper method to get account currency symbol by ID
  String _getAccountCurrencySymbol(String accountId) {
    try {
      final account = accounts.firstWhere((account) => account.id == accountId);
      // Safely check for currency and symbol
      if (account.currency != null && account.currency.symbol != null && account.currency.symbol.isNotEmpty) {
        return account.currency.symbol;
      }
    } catch (e) {
      // Account not found or currency not set
    }
    return defaultCurrencySymbol;
  }

  // Helper method to build income/expense cards
  Widget _buildCard({
    required String label,
    required double amount,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                label == 'Income' ? Icons.arrow_downward : Icons.arrow_upward,
                color: textColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppStyles.regular1(color: textColor, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$defaultCurrencySymbol${amount.toStringAsFixed(2)}',
            style: AppStyles.bold(color: textColor, size: 16),
          ),
        ],
      ),
    );
  }

  // Helper method to build segment tabs
  Widget _buildSegment({
    required String label,
    required TransactionFilter filter,
    bool isActive = false
  }) {
    return GestureDetector(
      onTap: () => _onFilterChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColours.primaryColour : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppStyles.regular1(
            color: isActive ? Colors.white : Colors.grey,
            size: 14,
          ),
        ),
      ),
    );
  }

  String _getChartTitle() {
    switch (currentFilter) {
      case TransactionFilter.today:
        return 'Today\'s Expenses';
      case TransactionFilter.week:
        return 'Weekly Expenses';
      case TransactionFilter.month:
        return 'Monthly Expenses (Daily Average)';
    }
  }

  // Navigation methods
  void _toggleAddMenu() {
    setState(() {
      _isAddMenuOpen = !_isAddMenuOpen;
    });
  }

  void _showAddIncomeScreen() {
    setState(() {
      _isAddMenuOpen = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IncomeScreen()),
    ).then((_) => loadDashboardData()); // Refresh data when returning
  }

  void _showAddExpenseScreen() {
    setState(() {
      _isAddMenuOpen = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExpenseScreen()),
    ).then((_) => loadDashboardData()); // Refresh data when returning
  }

  void _showTransferScreen() {
    setState(() {
      _isAddMenuOpen = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransferScreen()),
    ).then((_) => loadDashboardData()); // Refresh data when returning
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _navigateToTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransactionScreen()),
    );
  }

  void _navigateToBudget() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BudgetScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentMonth = DateFormat('MMMM').format(selectedDate);
    final String currentYear = DateFormat('yyyy').format(selectedDate);

    return Scaffold(
      backgroundColor: AppColours.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: loadDashboardData, // Pull to refresh
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header section with gradient background
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFAE6D3), // Gradient start
                            Color(0xFFFFF7EC), // Gradient end
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Top row: profile icon, date dropdown and notification icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Profile icon on the left
                              InkWell(
                                onTap: _navigateToProfile,
                                child: _avatarFile != null
                                    ? CircleAvatar(
                                        radius: 24, // Medium size
                                        backgroundImage: FileImage(_avatarFile!),
                                      )
                                    : const CircleAvatar(
                                        radius: 24, // Medium size
                                      ),
                              ),
                              // Month Filter centered
                              PopupMenuButton<String>(
                                offset: const Offset(0, 40),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$currentMonth $currentYear',
                                      style: AppStyles.bold(size: 15),
                                    ),
                                    const Icon(Icons.arrow_drop_down, size: 18),
                                  ],
                                ),
                                onSelected: (String value) {
                                  final date = DateFormat('yyyy-MM').parse(value);
                                  setState(() {
                                    selectedDate = date;
                                  });
                                  loadDashboardData();
                                },
                                itemBuilder: (BuildContext context) {
                                  final now = DateTime.now();
                                  final months = List.generate(12, (index) {
                                    final date = DateTime(now.year, now.month - 11 + index);
                                    return {
                                      'value': DateFormat('yyyy-MM').format(date),
                                      'text': DateFormat('MMMM yyyy').format(date),
                                    };
                                  });
                                  return months.map((month) => PopupMenuItem<String>(
                                    value: month['value'],
                                    child: Text(month['text']!),
                                  )).toList();
                                },
                              ),
                              // Notification icon on the right
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications, size: 26, color: Colors.black87),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                                      );
                                      _loadUnreadCount();
                                    },
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 6,
                                      top: 10,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          AppSpacing.vertical(size: 24),

                          // Account Balance - centered
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Account Balance',
                                  style: AppStyles.medium(
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                AppSpacing.vertical(size: 8),
                                Text(
                                  '${defaultCurrencySymbol}${accountBalance.toStringAsFixed(2)}',
                                  style: AppStyles.titleX(size: 36, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.vertical(size: 16),

                          // Row with Income & Expenses Cards
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: _buildCard(
                                    label: 'Income',
                                    amount: income,
                                    backgroundColor: AppColours.incomeColor,
                                    textColor: AppColours.backgroundColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildCard(
                                    label: 'Expenses',
                                    amount: expenses,
                                    backgroundColor: AppColours.expenseColor,
                                    textColor: AppColours.backgroundColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.vertical(size: 16),
                        ],
                      ),
                    ),

                    // Spend Frequency Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getChartTitle(), style: AppStyles.medium(size: 18)),
                          AppSpacing.vertical(size: 16),
                          // Bar chart using fl_chart for dynamic spend data
                          SizedBox(
                            height: 150,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: spendData.isNotEmpty ?
                                (spendData.reduce((a, b) => a > b ? a : b) + 10).clamp(10, double.infinity) : 100,
                                barTouchData: BarTouchData(enabled: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (double value, TitleMeta meta) {
                                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                                          return Text(days[value.toInt()]);
                                        }
                                        return const Text('');
                                      },
                                      reservedSize: 42,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (double value, TitleMeta meta) {
                                        if (value == 0) return const Text('0');
                                        return Text('${value.toInt()}');
                                      },
                                      reservedSize: 32,
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
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
                                        color: AppColours.expenseColor,
                                        width: 16,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                      )
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                          AppSpacing.vertical(size: 16),
                          // Segmented Tabs only (no See All)
                          Row(
                            children: [
                              Flexible(
                                flex: 3,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildSegment(
                                        label: 'Today',
                                        filter: TransactionFilter.today,
                                        isActive: currentFilter == TransactionFilter.today,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildSegment(
                                        label: 'Week',
                                        filter: TransactionFilter.week,
                                        isActive: currentFilter == TransactionFilter.week,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildSegment(
                                        label: 'Month',
                                        filter: TransactionFilter.month,
                                        isActive: currentFilter == TransactionFilter.month,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Recent Transactions Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Recent Transactions (${_getFilterDisplayName()})',
                                  style: AppStyles.bold(size: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Removed See All button
                            ],
                          ),
                          AppSpacing.vertical(size: 16),

                          // Transactions list - showing all filtered transactions
                          filteredTransactions.isEmpty
                              ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No transactions for ${_getFilterDisplayName().toLowerCase()}',
                                style: AppStyles.regular1(color: Colors.grey),
                              ),
                            ),
                          )
                              : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = filteredTransactions[index];

                              // Get account name and handle errors properly
                              String accountName = _getAccountNameById(transaction.accountId);

                              // Format title and subtitle correctly
                              final categoryName = transaction.category?.name ??
                                  (transaction.type.toLowerCase() == 'transfer' ? 'Transfer' :
                                  transaction.type.toLowerCase() == 'income' ? 'Income' : 'Expense');

                              // Format subtitle as "Account Name - Description"
                              final subtitle = transaction.description?.isNotEmpty == true
                                  ? '$accountName - ${transaction.description}'
                                  : accountName;

                              return _buildTransactionItem(
                                icon: transaction.category?.icon != null && transaction.category?.icon != ''
                                    ? _getCategoryIconFromId(transaction.category?.id)
                                    : Icons.category,
                                label: categoryName,
                                description: subtitle,
                                amount: transaction.amount,
                                type: transaction.type,
                                time: transaction.getFormattedTime(),
                                currencySymbol: _getAccountCurrencySymbol(transaction.accountId),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Bottom padding to ensure content isn't obscured by the nav bar
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),

          // Add menu overlay
          if (_isAddMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleAddMenu, // Close menu when tapping outside
                child: Container(
                  color: Colors.black54, // Semi-transparent overlay
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Income button
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ElevatedButton.icon(
                            onPressed: _showAddIncomeScreen,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColours.incomeColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.arrow_downward, color: Colors.white),
                            ),
                            label: const Text('Income'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: AppStyles.medium(size: 16),
                            ),
                          ),
                        ),

                        // Transfer button
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ElevatedButton.icon(
                            onPressed: _showTransferScreen,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColours.primaryColour,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.swap_horiz, color: Colors.white),
                            ),
                            label: const Text('Transfer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: AppStyles.medium(size: 16),
                            ),
                          ),
                        ),

                        // Expense button
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ElevatedButton.icon(
                            onPressed: _showAddExpenseScreen,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColours.expenseColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.arrow_upward, color: Colors.white),
                            ),
                            label: const Text('Expense'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: AppStyles.medium(size: 16),
                            ),
                          ),
                        ),

                        // Close button
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: FloatingActionButton(
                            onPressed: _toggleAddMenu,
                            backgroundColor: Colors.purple,
                            child: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // Bottom navigation bar with updated onTap handler for Profile navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColours.primaryColour,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: _currentIndex,
        onTap: (index) {
          // If it's the add button (middle item)
          if (index == 2) {
            _toggleAddMenu();
            return;
          }

          if (index == 1) {
            _navigateToTransaction();
            return;
          }

          if (index == 3) {
            _navigateToBudget();
            return;
          }

          // If it's the profile tab
          if (index == 4) {
            _navigateToProfile();
            return;
          }

          setState(() {
            _currentIndex = index;
            // Close add menu if it's open
            if (_isAddMenuOpen) {
              _isAddMenuOpen = false;
            }

            // You can add navigation logic for other tabs here if needed
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transaction',
          ),
          // Center add button - special styling
          BottomNavigationBarItem(
            icon: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isAddMenuOpen ? Colors.purple : AppColours.primaryColour,
                shape: BoxShape.circle,
              ),
              child: Icon(
                  _isAddMenuOpen ? Icons.close : Icons.add,
                  color: Colors.white,
                  size: 30
              ),
            ),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Budget',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getFilterDisplayName() {
    switch (currentFilter) {
      case TransactionFilter.today:
        return 'Today';
      case TransactionFilter.week:
        return 'This Week';
      case TransactionFilter.month:
        return 'This Month';
    }
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required String label,
    required String description,
    required double amount,
    required String type,
    required String time,
    required String currencySymbol,
  }) {
    // Determine prefix and color based on transaction type
    final isExpense = type.toLowerCase() == 'expense';
    final isTransfer = type.toLowerCase() == 'transfer';
    final isIncome = type.toLowerCase() == 'income';

    String prefix;
    Color amountColor;

    if (isTransfer) {
      prefix = '';  // No prefix for transfers
      amountColor = AppColours.primaryColour;
    } else if (isIncome) {
      prefix = '+ ';
      amountColor = AppColours.incomeColor;
    } else {
      prefix = '- ';
      amountColor = AppColours.expenseColor;
    }

    // Format amount with currency symbol
    final formattedAmount = '$prefix$currencySymbol${amount.toStringAsFixed(2)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: amountColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedAmount,
                style: TextStyle(
                  color: amountColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to get category icon from ID
  IconData _getCategoryIconFromId(String? categoryId) {
    if (categoryId == null || categories.isEmpty) return Icons.category;
    try {
      final category = categories.firstWhere(
        (cat) => (cat.id ?? cat['id']) == categoryId,
        orElse: () => null,
      );
      if (category != null) {
        String? iconName = category.icon ?? category['icon'];
        return _getIconFromName(iconName);
      }
    } catch (e) {
      // Handle case where no matching category is found
    }
    return Icons.category;
  }

  // Helper method to get category name by ID (returns the category name, not type or id)
  String _getCategoryNameById(String? categoryId) {
    if (categoryId == null || categories.isEmpty) return '';
    try {
      final category = categories.firstWhere(
        (cat) => (cat.id ?? cat['id']) == categoryId,
        orElse: () => null,
      );
      if (category != null) {
        if (category.name != null && category.name is String) {
          return category.name;
        }
        if (category['name'] != null && category['name'] is String) {
          return category['name'];
        }
      }
    } catch (e) {}
    return '';
  }

  // Helper to get icon from icon name string
  IconData _getIconFromName(String? iconName) {
    if (iconName == null) return Icons.category;
    switch (iconName.toLowerCase()) {
      case 'shopping_bag':
      case 'shopping':
        return Icons.shopping_bag;
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      case 'directions_bus':
      case 'transport':
      case 'transportation':
        return Icons.directions_bus;
      case 'work':
      case 'business':
        return Icons.work;
      case 'subscriptions':
      case 'entertainment':
        return Icons.subscriptions;
      case 'swap_horiz':
      case 'transfer':
        return Icons.swap_horiz;
      case 'payment':
      case 'money':
        return Icons.payment;
      case 'home':
        return Icons.home;
      case 'medical_services':
      case 'health':
        return Icons.medical_services;
      case 'school':
      case 'education':
        return Icons.school;
      case 'local_gas_station':
      case 'fuel':
        return Icons.local_gas_station;
      case 'phone':
        return Icons.phone;
      case 'electric_bolt':
      case 'utilities':
        return Icons.electric_bolt;
      default:
        return Icons.category;
    }
  }

  // Helper method to get account name by ID with proper error handling
  String _getAccountNameById(String accountId) {
    try {
      final account = accounts.firstWhere(
        (acc) => acc.id == accountId,
      );
      return account?.name ?? 'Unknown Account';
    } catch (e) {
      return 'Unknown Account';
    }
  }
}
