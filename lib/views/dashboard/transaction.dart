import 'package:flutter/material.dart';
import 'package:monet/controller/account.dart';
import 'package:monet/controller/account_type.dart';
import 'package:monet/controller/category.dart';
import 'package:monet/controller/transaction.dart';
import 'package:monet/models/account.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/models/transaction.dart';
import 'package:monet/models/result.dart';
import 'package:monet/views/dashboard/home.dart';
import 'package:monet/views/dashboard/expense.dart';
import 'package:monet/views/dashboard/income.dart';
import 'package:monet/views/dashboard/profile.dart';
import 'package:monet/views/dashboard/budget.dart';
import 'package:monet/views/dashboard/transfer.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

enum TransactionType { all, income, expense, transfer }
enum SortBy { highest, lowest, newest, oldest }

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({Key? key}) : super(key: key);

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  TransactionType selectedType = TransactionType.all;
  TransactionType filterType = TransactionType.all;
  SortBy sortBy = SortBy.newest;
  String selectedCategory = '';
  String selectedAccountType = '';
  String selectedMonth = 'June 2025';
  final String defaultCurrencySymbol = '₱';

  // Bottom navigation state
  int _currentIndex = 1; // 1 represents Transaction tab
  bool _isAddMenuOpen = false;

  // State management for API data
  bool isLoading = true;
  bool isLoadingAccountTypes = true;
  bool isLoadingCategories = true;
  bool hasError = false;
  bool hasAccountTypeError = false;
  bool hasCategoryError = false;
  String errorMessage = '';
  String accountTypeErrorMessage = '';
  String categoryErrorMessage = '';
  List<TransactionModel> allTransactions = [];
  List<dynamic> accountTypes = [];
  List<dynamic> categories = [];
  List<AccountModel> accounts = [];
  Map<String, AccountModel> accountMap = {};

  // Month options for dropdown
  List<String> availableMonths = [
    'January 2025', 'February 2025', 'March 2025', 'April 2025',
    'May 2025', 'June 2025', 'July 2025', 'August 2025',
    'September 2025', 'October 2025', 'November 2025', 'December 2025'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Add menu toggle and navigation methods
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
    ).then((_) => _loadData()); // Refresh data when returning
  }

  void _showAddExpenseScreen() {
    setState(() {
      _isAddMenuOpen = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExpenseScreen()),
    ).then((_) => _loadData()); // Refresh data when returning
  }

  void _showTransferScreen() {
    setState(() {
      _isAddMenuOpen = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransferScreen()),
    ).then((_) => _loadData()); // Refresh data when returning
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _navigateToBudget() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BudgetScreen()),
    );
  }

  void _navigateToTransaction() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TransactionScreen()),
    );
  }

  Future<void> _loadData() async {
    // Load transactions, account types, categories, and accounts concurrently
    await Future.wait([
      _loadTransactions(),
      _loadAccountTypes(),
      _loadCategories(),
      _loadAccounts(),
    ]);
  }

  Future<void> _loadTransactions() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });

    try {
      final Result<List<TransactionModel>> result = await TransactionController.loadTransactions();

      if (result.isSuccess && result.results != null) {
        setState(() {
          allTransactions = result.results!;
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage = result.message ?? 'Failed to load transactions';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'An error occurred while loading transactions';
        isLoading = false;
      });
    }
  }

  Future<void> _loadAccountTypes() async {
    setState(() {
      isLoadingAccountTypes = true;
      hasAccountTypeError = false;
      accountTypeErrorMessage = '';
    });

    try {
      final Result result = await AccountTypeController.load();

      if (result.isSuccess && result.results != null) {
        setState(() {
          accountTypes = result.results!;
          isLoadingAccountTypes = false;
        });
      } else {
        setState(() {
          hasAccountTypeError = true;
          accountTypeErrorMessage = result.message ?? 'Failed to load account types';
          isLoadingAccountTypes = false;
        });
      }
    } catch (e) {
      setState(() {
        hasAccountTypeError = true;
        accountTypeErrorMessage = 'An error occurred while loading account types';
        isLoadingAccountTypes = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      isLoadingCategories = true;
      hasCategoryError = false;
      categoryErrorMessage = '';
    });

    try {
      final Result result = await CategoryController.load();

      if (result.isSuccess && result.results != null) {
        setState(() {
          categories = result.results!;
          isLoadingCategories = false;
        });
        print("Loaded ${categories.length} categories from API");
      } else {
        setState(() {
          hasCategoryError = true;
          categoryErrorMessage = result.message ?? 'Failed to load categories';
          isLoadingCategories = false;
        });
        print("Failed to load categories: ${result.message}");
      }
    } catch (e) {
      setState(() {
        hasCategoryError = true;
        categoryErrorMessage = 'An error occurred while loading categories';
        isLoadingCategories = false;
      });
      print("Error loading categories: $e");
    }
  }

  Future<void> _loadAccounts() async {
    try {
      final result = await AccountController.load();
      if (result.isSuccess && result.results != null) {
        setState(() {
          accounts = result.results!;
          accountMap = { for (var acc in accounts) acc.id : acc };
        });
      }
    } catch (e) {
      // Optionally handle error
    }
  }

  // Helper method to safely get category ID from transaction.category
  String? _getCategoryId(dynamic category) {
    if (category == null) return null;

    // If it's a CategoryModel object
    if (category is Map<String, dynamic>) {
      return category['id']?.toString();
    }

    // If it's already a string
    if (category is String) {
      return category;
    }

    // If it has an id property
    try {
      return category.id?.toString();
    } catch (e) {
      return category.toString();
    }
  }

  // Helper method to get category name from transaction.category
  String _getCategoryNameFromTransaction(dynamic category) {
    if (category == null) return '';

    // If it's a CategoryModel object with properties
    if (category is Map<String, dynamic>) {
      return category['name']?.toString() ?? '';
    }

    // If it's a string (category ID), look it up
    if (category is String) {
      return _getCategoryNameFromId(category);
    }

    // If it has name and id properties
    try {
      String? name = category.name;
      if (name != null && name.isNotEmpty) {
        return name;
      }
      String? id = category.id;
      if (id != null) {
        return _getCategoryNameFromId(id);
      }
    } catch (e) {
      // Fallback to string conversion
    }

    return category.toString();
  }

  // Helper method to get category name from ID
  String _getCategoryNameFromId(String? categoryId) {
    if (categoryId == null || categories.isEmpty) return '';

    try {
      final category = categories.firstWhere(
            (cat) => (cat.id ?? cat['id']) == categoryId,
        orElse: () => null,
      );

      if (category != null) {
        return category.name ?? category['name'] ?? '';
      }
    } catch (e) {
      // Handle case where no matching category is found
    }

    return categoryId;
  }

  // Helper method to get category icon from transaction.category
  IconData _getCategoryIconFromTransaction(dynamic category) {
    if (category == null) return Icons.category;

    // If it's a CategoryModel object with properties
    if (category is Map<String, dynamic>) {
      String? iconName = category['icon']?.toString();
      return _getIconFromName(iconName);
    }

    // If it's a string (category ID), look it up
    if (category is String) {
      return _getCategoryIconFromId(category);
    }

    // If it has icon and id properties
    try {
      String? iconName = category.icon;
      if (iconName != null && iconName.isNotEmpty) {
        return _getIconFromName(iconName);
      }
      String? id = category.id;
      if (id != null) {
        return _getCategoryIconFromId(id);
      }
    } catch (e) {
      // Fallback
    }

    return Icons.category;
  }

  // Helper method to convert icon name to IconData
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

  // Helper method to get account type from account ID
  String _getAccountTypeFromAccountId(String? accountId) {
    if (accountId == null || accountTypes.isEmpty) return '';

    try {
      final accountType = accountTypes.firstWhere(
            (type) => type.id == accountId || type['id'] == accountId,
        orElse: () => null,
      );

      if (accountType != null) {
        return accountType.name ?? accountType['name'] ?? '';
      }
    } catch (e) {
      // Handle case where no matching account type is found
    }

    return '';
  }

  // Helper method to get account type name by ID
  String _getAccountTypeNameById(String accountTypeId) {
    if (accountTypes.isEmpty) return accountTypeId;

    try {
      final accountType = accountTypes.firstWhere(
            (type) => (type.id ?? type['id']) == accountTypeId,
        orElse: () => null,
      );

      if (accountType != null) {
        return accountType.name ?? accountType['name'] ?? accountTypeId;
      }
    } catch (e) {
      // Handle case where no matching account type is found
    }

    return accountTypeId;
  }

  // Helper method to get category name by ID
  String _getCategoryNameById(String categoryId) {
    if (categories.isEmpty) return categoryId;

    try {
      final category = categories.firstWhere(
            (cat) => (cat.id ?? cat['id']) == categoryId,
        orElse: () => null,
      );

      if (category != null) {
        return category.name ?? category['name'] ?? categoryId;
      }
    } catch (e) {
      // Handle case where no matching category is found
    }

    return categoryId;
  }

  // Enhanced method to get icon for transaction - FIXED
  IconData _getTransactionIcon(TransactionModel transaction) {
    String type = transaction.type?.toLowerCase() ?? '';

    // First try to get icon from category if available
    if (transaction.category != null) {
      IconData categoryIcon = _getCategoryIconFromTransaction(transaction.category);
      if (categoryIcon != Icons.category) {
        return categoryIcon;
      }
    }

    // Fallback to type-based icons
    switch (type) {
      case 'income':
        return Icons.work;
      case 'expense':
        return Icons.payment;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.payment;
    }
  }

  // Show month selector bottom sheet
  void _showMonthSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Month', style: AppStyles.bold(size: 20)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: availableMonths.length,
                  itemBuilder: (context, index) {
                    final month = availableMonths[index];
                    final isSelected = month == selectedMonth;

                    return ListTile(
                      title: Text(month),
                      leading: const Icon(Icons.calendar_month),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: AppColours.primaryColour)
                          : null,
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          selectedMonth = month;
                        });
                        Navigator.pop(context);
                        // Here you could add filtering by date if needed
                        // Example: _filterTransactionsByMonth(month);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group transactions by date label (Today, Yesterday, or date)
    Map<String, List<TransactionModel>> groupedTransactions = {};
    for (var transaction in allTransactions) {
      final transactionDate = DateTime.tryParse(transaction.transactionDate ?? '') ?? DateTime.now();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final transactionDay = DateTime(transactionDate.year, transactionDate.month, transactionDate.day);
      String label;
      if (transactionDay == today) {
        label = 'Today';
      } else if (transactionDay == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('MMM d, yyyy').format(transactionDate);
      }
      groupedTransactions.putIfAbsent(label, () => []).add(transaction);
    }
    final groupedKeys = groupedTransactions.keys.toList();
    groupedKeys.sort((a, b) {
      // Sort by date descending: Today > Yesterday > others by date
      if (a == 'Today') return -1;
      if (b == 'Today') return 1;
      if (a == 'Yesterday') return -1;
      if (b == 'Yesterday') return 1;
      // Parse date for other labels
      DateTime? da, db;
      try { da = DateFormat('MMM d, yyyy').parse(a); } catch (_) {}
      try { db = DateFormat('MMM d, yyyy').parse(b); } catch (_) {}
      if (da != null && db != null) return db.compareTo(da);
      return 0;
    });
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.keyboard_arrow_down, color: Colors.black),
            SizedBox(width: 8),
            Text(
              selectedMonth, // Show selected month
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Icon(Icons.menu, color: Colors.black),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Financial Report Card
          GestureDetector(
            onTap: () {}, // TODO: Implement navigation to report
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.purple[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'See your financial report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),

          // Transactions List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : allTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No transactions found'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: groupedKeys.fold(0, (sum, k) => sum! + 1 + groupedTransactions[k]!.length),
                        itemBuilder: (context, index) {
                          int runningIndex = 0;
                          for (final key in groupedKeys) {
                            if (index == runningIndex) {
                              // Section header
                              return Padding(
                                padding: EdgeInsets.only(top: 16, bottom: 8),
                                child: Text(
                                  key,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            }
                            runningIndex++;
                            final txList = groupedTransactions[key]!;
                            if (index < runningIndex + txList.length) {
                              final transaction = txList[index - runningIndex];
                              final type = transaction.type?.toLowerCase() ?? '';
                              final isExpense = type == 'expense';
                              final isIncome = type == 'income';
                              final isTransfer = type == 'transfer';
                              final icon = _getTransactionIcon(transaction);
                              final amount = transaction.amount ?? 0.0;
                              final account = accountMap[transaction.accountId];
                              final currencySymbol = account?.currency.symbol ?? defaultCurrencySymbol;
                              final formattedAmount =
                                  (isExpense ? '- ' : isIncome ? '+ ' : '') +
                                  currencySymbol +
                                  amount.toStringAsFixed(2);
                              final amountColor = isExpense
                                  ? Colors.red
                                  : isIncome
                                      ? Colors.green
                                      : Colors.purple;
                              final transactionDate = DateTime.tryParse(transaction.transactionDate ?? '') ?? DateTime.now();
                              final time = _formatDate(transactionDate);
                              final categoryName = _getCategoryNameFromId(transaction.category?.id ?? transaction.category?.name);
                              final label = isTransfer
                                  ? 'Transfer'
                                  : categoryName.isNotEmpty
                                      ? categoryName
                                      : isIncome
                                          ? 'Income'
                                          : 'Expense';
                              final description = transaction.description ?? 'No description';
                              return _buildTransactionItem(
                                icon: icon,
                                iconColor: amountColor,
                                title: label,
                                subtitle: description,
                                amount: formattedAmount,
                                time: time,
                                isExpense: isExpense,
                              );
                            }
                            runningIndex += txList.length;
                          }
                          return SizedBox.shrink();
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColours.primaryColour,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _toggleAddMenu();
            return;
          }
          if (index == 0) {
            _navigateToHome();
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
          if (index == 4) {
            _navigateToProfile();
            return;
          }
          setState(() {
            _currentIndex = index;
            if (_isAddMenuOpen) {
              _isAddMenuOpen = false;
            }
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
                size: 30,
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

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required String time,
    required bool isExpense,
  }) {
    // Parse the time string to DateTime if possible
    DateTime? date;
    try {
      date = DateTime.tryParse(time);
    } catch (_) {
      date = null;
    }
    String displayTime = time;
    if (date != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final transactionDay = DateTime(date.year, date.month, date.day);
      if (transactionDay == today) {
        displayTime = 'Today';
      } else if (transactionDay == yesterday) {
        displayTime = 'Yesterday';
      } else {
        displayTime = DateFormat('MMM d, yyyy').format(date);
      }
    }
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Amount and Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text(
                displayTime,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateTotalBalance() {
    double total = 0;
    for (var transaction in allTransactions) {
      if (transaction.type?.toLowerCase() == 'income') {
        total += transaction.amount ?? 0;
      } else if (transaction.type?.toLowerCase() == 'expense') {
        total -= transaction.amount ?? 0;
      }
    }
    return total;
  }

  double _calculateTotalIncome() {
    return allTransactions
        .where((transaction) => transaction.type?.toLowerCase() == 'income')
        .fold(0.0, (sum, transaction) => sum + (transaction.amount ?? 0));
  }

  double _calculateTotalExpense() {
    return allTransactions
        .where((transaction) => transaction.type?.toLowerCase() == 'expense')
        .fold(0.0, (sum, transaction) => sum + (transaction.amount ?? 0));
  }

  // FIXED: Changed from _formatTime to _formatDate to show actual dates
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (transactionDay == today) {
      return 'Today';
    } else if (transactionDay == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      // Show day of week for recent dates
      return DateFormat('EEE').format(dateTime); // Mon, Tue, etc.
    } else if (dateTime.year == now.year) {
      // Show month and day for current year
      return DateFormat('MMM d').format(dateTime); // Jan 15, Feb 3, etc.
    } else {
      // Show full date for older dates
      return DateFormat('MMM d, y').format(dateTime); // Jan 15, 2024
    }
  }

  // FIXED: Completely rewritten filter bottom sheet to fix overflow issue
  void _showFilterBottomSheet() {
    // Always use the current filterType as the initial value
    final tempFilterType = ValueNotifier<TransactionType>(filterType);
    final tempSortBy = ValueNotifier<SortBy>(sortBy);

    void reopenFilterSheet() {
      Navigator.of(context).pop();
      Future.delayed(const Duration(milliseconds: 200), () {
        _showFilterBottomSheetWithValues(
          tempFilterType,
          tempSortBy,
        );
      });
    }

    _showFilterBottomSheetWithValues(
      tempFilterType,
      tempSortBy,
    );
  }

  void _showFilterBottomSheetWithValues(
    ValueNotifier<TransactionType> tempFilterType,
    ValueNotifier<SortBy> tempSortBy,
    {VoidCallback? reopenFilterSheet,}
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Filter Transactions', style: AppStyles.bold(size: 20)),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type filter options
                              Text('Type', style: AppStyles.medium(size: 16)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _buildFilterOption(
                                    'All',
                                    tempFilterType.value == TransactionType.all,
                                        () => setState(() => tempFilterType.value = TransactionType.all),
                                  ),
                                  _buildFilterOption(
                                    'Income',
                                    tempFilterType.value == TransactionType.income,
                                        () => setState(() => tempFilterType.value = TransactionType.income),
                                  ),
                                  _buildFilterOption(
                                    'Expense',
                                    tempFilterType.value == TransactionType.expense,
                                        () => setState(() => tempFilterType.value = TransactionType.expense),
                                  ),
                                  _buildFilterOption(
                                    'Transfer',
                                    tempFilterType.value == TransactionType.transfer,
                                        () => setState(() => tempFilterType.value = TransactionType.transfer),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text('Sort by', style: AppStyles.medium(size: 16)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _buildFilterOption(
                                    'Newest',
                                    tempSortBy.value == SortBy.newest,
                                        () => setState(() => tempSortBy.value = SortBy.newest),
                                  ),
                                  _buildFilterOption(
                                    'Oldest',
                                    tempSortBy.value == SortBy.oldest,
                                        () => setState(() => tempSortBy.value = SortBy.oldest),
                                  ),
                                  _buildFilterOption(
                                    'Highest',
                                    tempSortBy.value == SortBy.highest,
                                        () => setState(() => tempSortBy.value = SortBy.highest),
                                  ),
                                  _buildFilterOption(
                                    'Lowest',
                                    tempSortBy.value == SortBy.lowest,
                                        () => setState(() => tempSortBy.value = SortBy.lowest),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text('Category', style: AppStyles.medium(size: 16)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  _showCategorySelector(selectedCategory, (category) {
                                    setState(() {
                                      selectedCategory = category;
                                    });
                                    Navigator.pop(context);
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedCategory.isEmpty
                                              ? 'All Categories'
                                              : _getCategoryNameById(selectedCategory),
                                          style: AppStyles.regular1(size: 14),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),
                              Text('Account', style: AppStyles.medium(size: 16)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  if (reopenFilterSheet != null) {
                                    _showAccountTypeSelector(selectedAccountType, (accountType) {
                                      setState(() {
                                        selectedAccountType = accountType;
                                      });
                                      reopenFilterSheet();
                                    });
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedAccountType.isEmpty
                                              ? 'All Accounts'
                                              : _getAccountTypeNameById(selectedAccountType),
                                          style: AppStyles.regular1(size: 14),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  tempFilterType.value = TransactionType.all;
                                  tempSortBy.value = SortBy.newest;
                                  selectedCategory = '';
                                  selectedAccountType = '';
                                });
                              },
                              child: Text(
                                'Reset',
                                style: TextStyle(color: AppColours.primaryColour),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  filterType = tempFilterType.value;
                                  selectedType = tempFilterType.value;
                                  sortBy = tempSortBy.value;
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColours.primaryColour,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text('Apply', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColours.primaryColour : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColours.primaryColour : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: AppStyles.regular1(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  void _showAccountTypeSelector(String currentAccountType, Function(String) onAccountTypeSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Account', style: AppStyles.bold(size: 20)),
              const SizedBox(height: 20),
              Expanded(
                child: _buildAccountTypeList(currentAccountType, onAccountTypeSelected),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountTypeList(String currentAccountType, Function(String) onAccountTypeSelected) {
    if (isLoadingAccountTypes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasAccountTypeError) {
      return Center(
        child: Text(accountTypeErrorMessage),
      );
    }

    return ListView.builder(
      itemCount: accountTypes.length + 1, // +1 for "All Accounts" option
      itemBuilder: (context, index) {
        if (index == 0) {
          // All Accounts option
          return ListTile(
            title: const Text('All Accounts'),
            leading: const Icon(Icons.account_balance),
            selected: currentAccountType.isEmpty,
            onTap: () {
              setState(() {
                selectedAccountType = '';
              });
              Navigator.pop(context);
            },
          );
        } else {
          // Account type options
          final accountType = accountTypes[index - 1];
          final accountTypeId = accountType.id ?? accountType['id'] ?? '';
          final accountTypeName = accountType.name ?? accountType['name'] ?? 'Unknown';

          return ListTile(
            title: Text(accountTypeName),
            leading: const Icon(Icons.account_balance_wallet),
            selected: accountTypeId == currentAccountType,
            onTap: () {
              setState(() {
                selectedAccountType = accountTypeId;
              });
              Navigator.pop(context);
            },
          );
        }
      },
    );
  }

  void _showCategorySelector(String currentCategory, Function(String) onCategorySelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Category', style: AppStyles.bold(size: 20)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length + 1, // +1 for "All Categories" option
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // All Categories option
                      return ListTile(
                        title: const Text('All Categories'),
                        leading: const Icon(Icons.category),
                        selected: currentCategory.isEmpty,
                        onTap: () {
                          setState(() {
                            selectedCategory = '';
                          });
                          Navigator.pop(context);
                        },
                      );
                    } else {
                      // Category options
                      final category = categories[index - 1];
                      final categoryId = category.id ?? category['id'] ?? '';
                      final categoryName = category.name ?? category['name'] ?? 'Unknown';
                      final iconName = category.icon ?? category['icon'];

                      return ListTile(
                        title: Text(categoryName),
                        leading: Icon(_getIconFromName(iconName)),
                        selected: categoryId == currentCategory,
                        onTap: () {
                          setState(() {
                            selectedCategory = categoryId;
                          });
                          Navigator.pop(context);
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
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
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}