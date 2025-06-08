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
import 'package:monet/views/dashboard/expense.dart';
import 'package:monet/views/dashboard/income.dart';
import 'package:monet/views/dashboard/transfer.dart';
import 'package:intl/intl.dart';
import 'package:monet/views/navigation/bottom_navigation.dart';
import 'package:monet/views/transaction/edit_transaction.dart';

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

  // Show options when a transaction is tapped
  void _showTransactionOptions(TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: AppColours.primaryColour),
                title: Text('Edit Transaction'),
                onTap: () {
                  Navigator.pop(context);
                  _editTransaction(transaction);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete Transaction'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(transaction);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Transaction'),
        content: Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(context);
              _deleteTransaction(transaction);
            },
          ),
        ],
      ),
    );
  }

  // Delete transaction
  Future<void> _deleteTransaction(TransactionModel transaction) async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await TransactionController.deleteTransaction(transaction.id);

      if (result.isSuccess) {
        // Update the UI by removing the transaction from the list
        setState(() {
          allTransactions.removeWhere((t) => t.id == transaction.id);
          isLoading = false;
        });

        // Also update account balance if needed - this ensures the UI stays consistent
        _loadAccounts();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Failed to delete transaction'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while deleting transaction: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Edit transaction
  void _editTransaction(TransactionModel transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transaction: transaction),
      ),
    ).then((result) {
      // Refresh data if transaction was updated
      if (result == true) {
        _loadData();
      }
    });
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

  // Helper method to get category name from transaction.category
  String _getCategoryNameFromTransaction(dynamic category) {
    if (category == null) return 'Unknown Category';
    try {
      if (category is Map<String, dynamic>) {
        return category['name']?.toString() ?? 'Unknown Category';
      } else if (category is String) {
        // If it's just an ID, look up in categories
        return _getCategoryNameFromId(category);
      } else {
        // Try object property
        var name = category.name;
        if (name != null && name.toString().isNotEmpty) {
          return name.toString();
        }
        // Try id lookup
        var id = category.id;
        if (id != null) {
          return _getCategoryNameFromId(id.toString());
        }
      }
    } catch (_) {}
    return 'Unknown Category';
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

  // Helper method to get category name from ID (returns name, not type)
  String _getCategoryNameFromId(String? categoryId) {
    if (categoryId == null || categories.isEmpty) return 'Unknown Category';
    try {
      final category = categories.firstWhere(
        (cat) => (cat.id?.toString() ?? cat['id']?.toString()) == categoryId,
        orElse: () => null,
      );
      if (category != null) {
        final name = (category.name != null && category.name is String)
            ? category.name
            : (category['name'] != null && category['name'] is String)
                ? category['name']
                : null;
        if (name != null && name.toString().isNotEmpty) {
          return name.toString();
        }
      }
    } catch (e) {}
    return 'Category #$categoryId';
  }

  // Enhanced method to get icon for transaction
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

  // Returns a filtered and sorted list of transactions based on current filter settings
  List<TransactionModel> _getFilteredTransactions() {
    List<TransactionModel> filtered = List.from(allTransactions);

    // Filter by transaction type
    if (filterType != TransactionType.all) {
      final filterTypeString = filterType.toString().split('.').last;
      filtered = filtered.where((transaction) =>
      transaction.type?.toLowerCase() == filterTypeString.toLowerCase()
      ).toList();
    }

    // Filter by month (if selectedMonth is set)
    if (selectedMonth.isNotEmpty) {
      final parts = selectedMonth.split(' ');
      if (parts.length == 2) {
        final month = parts[0];
        final year = parts[1];
        filtered = filtered.where((transaction) {
          final date = DateTime.tryParse(transaction.transactionDate ?? '');
          if (date == null) return false;
          final monthName = DateFormat('MMMM').format(date);
          return monthName == month && date.year.toString() == year;
        }).toList();
      }
    }

    // Sort
    switch (sortBy) {
      case SortBy.highest:
        filtered.sort((a, b) => (b.amount ?? 0).compareTo(a.amount ?? 0));
        break;
      case SortBy.lowest:
        filtered.sort((a, b) => (a.amount ?? 0).compareTo(b.amount ?? 0));
        break;
      case SortBy.newest:
        filtered.sort((a, b) => (b.transactionDate ?? '').compareTo(a.transactionDate ?? ''));
        break;
      case SortBy.oldest:
        filtered.sort((a, b) => (a.transactionDate ?? '').compareTo(b.transactionDate ?? ''));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Apply filters and sorting to get filtered transactions
    final filteredTransactions = _getFilteredTransactions();
    // Group transactions by date label (Today, Yesterday, or date)
    Map<String, List<TransactionModel>> groupedTransactions = {};
    for (var transaction in filteredTransactions) {
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
    return BottomNavigatorScreen(
      currentIndex: _currentIndex,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedMonth,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                      underline: SizedBox(),
                      style: TextStyle(color: Colors.black, fontSize: 14),
                      dropdownColor: Colors.white,
                      items: availableMonths.map((String month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(month, style: TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedMonth = newValue;
                          });
                          // Optionally, filter transactions by month here
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'Transaction',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Expanded(child: SizedBox()), // For symmetry
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.menu, color: Colors.black),
              onPressed: _showFilterBottomSheet,
            ),
            SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
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

                          // Get the account information
                          final account = accountMap[transaction.accountId];
                          final accountName = account?.name ?? 'Unknown Account';

                          // Get the currency symbol from account
                          final currencySymbol = account?.currency?.symbol ?? defaultCurrencySymbol;

                          // Format the amount with the account's currency
                          final formattedAmount =
                              (isExpense ? '- ' : isIncome ? '+ ' : '') +
                                  currencySymbol +
                                  amount.toStringAsFixed(2);

                          final amountColor = _getTransactionColor(type);

                          final transactionDate = DateTime.tryParse(transaction.transactionDate ?? '') ?? DateTime.now();
                          final time = _formatDate(transactionDate);

                          // Get category name for display
                          String categoryName = '';
                          if (transaction.category != null) {
                            categoryName = _getCategoryNameFromTransaction(transaction.category);
                          }

                          final description = transaction.description ?? '';

                          // Format title: use category name or fallback to transaction type
                          final title = isTransfer
                              ? 'Transfer'
                              : categoryName.isNotEmpty
                              ? categoryName
                              : isIncome
                              ? 'Income'
                              : 'Expense';

                          // Format subtitle in the requested format: "Category Name Account Name - Description"
                          // But we already used category name as title, so format as: "Account Name - Description"
                          final subtitle = description.isNotEmpty
                              ? '$accountName - $description'
                              : accountName;

                          return GestureDetector(
                            onTap: () => _showTransactionOptions(transaction),
                            child: _buildTransactionItem(
                              icon: icon,
                              iconColor: amountColor,
                              title: title,
                              subtitle: subtitle,
                              amount: formattedAmount,
                              time: time,
                              isExpense: isExpense,
                            ),
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
            if (_isAddMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleAddMenu,
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAddMenuItem(
                            icon: Icons.arrow_upward,
                            color: Colors.green,
                            label: 'Income',
                            onTap: _showAddIncomeScreen,
                          ),
                          const SizedBox(height: 16),
                          _buildAddMenuItem(
                            icon: Icons.arrow_downward,
                            color: Colors.red,
                            label: 'Expense',
                            onTap: _showAddExpenseScreen,
                          ),
                          const SizedBox(height: 16),
                          _buildAddMenuItem(
                            icon: Icons.swap_horiz,
                            color: Colors.purple,
                            label: 'Transfer',
                            onTap: _showTransferScreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMenuItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
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
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
                amount,
                style: TextStyle(
                  color: iconColor,
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

  void _showFilterBottomSheet() async {
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

    // Await the result and call setState if filters were applied
    final result = await _showFilterBottomSheetWithValues(
      tempFilterType,
      tempSortBy,
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<bool?> _showFilterBottomSheetWithValues(
      ValueNotifier<TransactionType> tempFilterType,
      ValueNotifier<SortBy> tempSortBy,
      {VoidCallback? reopenFilterSheet,}
      ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Transactions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  Text('Transaction Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterOption('All', tempFilterType.value == TransactionType.all,
                                () => setState(() => tempFilterType.value = TransactionType.all)),
                        const SizedBox(width: 8),
                        _buildFilterOption('Income', tempFilterType.value == TransactionType.income,
                                () => setState(() => tempFilterType.value = TransactionType.income)),
                        const SizedBox(width: 8),
                        _buildFilterOption('Expense', tempFilterType.value == TransactionType.expense,
                                () => setState(() => tempFilterType.value = TransactionType.expense)),
                        const SizedBox(width: 8),
                        _buildFilterOption('Transfer', tempFilterType.value == TransactionType.transfer,
                                () => setState(() => tempFilterType.value = TransactionType.transfer)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text('Sort By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterOption('Newest', tempSortBy.value == SortBy.newest,
                                () => setState(() => tempSortBy.value = SortBy.newest)),
                        const SizedBox(width: 8),
                        _buildFilterOption('Oldest', tempSortBy.value == SortBy.oldest,
                                () => setState(() => tempSortBy.value = SortBy.oldest)),
                        const SizedBox(width: 8),
                        _buildFilterOption('Highest', tempSortBy.value == SortBy.highest,
                                () => setState(() => tempSortBy.value = SortBy.highest)),
                        const SizedBox(width: 8),
                        _buildFilterOption('Lowest', tempSortBy.value == SortBy.lowest,
                                () => setState(() => tempSortBy.value = SortBy.lowest)),
                      ],
                    ),
                  ),

                  const Spacer(),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColours.primaryColour,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        filterType = tempFilterType.value;
                        sortBy = tempSortBy.value;
                        Navigator.pop(context, true); // Return true to trigger parent setState
                      },
                      child: Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

  // Helper method to get color based on transaction type
  Color _getTransactionColor(String type) {
    if (type.toLowerCase() == 'transfer') {
      return AppColours.transferColor;
    } else if (type.toLowerCase() == 'income') {
      return AppColours.incomeColor;
    } else {
      return AppColours.expenseColor;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}