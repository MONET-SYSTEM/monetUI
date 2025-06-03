import 'package:flutter/material.dart';
import 'package:monet/controller/account_type.dart';
import 'package:monet/controller/category.dart';
import 'package:monet/controller/transaction.dart';
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

  Future<void> _loadData() async {
    // Load transactions, account types, and categories concurrently
    await Future.wait([
      _loadTransactions(),
      _loadAccountTypes(),
      _loadCategories(),
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

  List<TransactionModel> get filteredTransactions {
    List<TransactionModel> filtered = allTransactions;

    // Filter by type
    if (filterType != TransactionType.all) {
      filtered = filtered.where((transaction) {
        return transaction.type?.toLowerCase() == filterType.name;
      }).toList();
    }

    // Filter by category
    if (selectedCategory.isNotEmpty) {
      filtered = filtered.where((transaction) {
        // Handle both CategoryModel and String cases
        String? categoryId = _getCategoryId(transaction.category);
        return categoryId == selectedCategory;
      }).toList();
    }

    // Filter by account type
    if (selectedAccountType.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return transaction.accountId == selectedAccountType ||
            _getAccountTypeFromAccountId(transaction.accountId) == selectedAccountType;
      }).toList();
    }

    // Sort transactions
    filtered.sort((a, b) {
      switch (sortBy) {
        case SortBy.highest:
          return (b.amount ?? 0).compareTo(a.amount ?? 0);
        case SortBy.lowest:
          return (a.amount ?? 0).compareTo(b.amount ?? 0);
        case SortBy.newest:
          DateTime dateA = DateTime.tryParse(a.transactionDate ?? '') ?? DateTime.now();
          DateTime dateB = DateTime.tryParse(b.transactionDate ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        case SortBy.oldest:
          DateTime dateA = DateTime.tryParse(a.transactionDate ?? '') ?? DateTime.now();
          DateTime dateB = DateTime.tryParse(b.transactionDate ?? '') ?? DateTime.now();
          return dateA.compareTo(dateB);
      }
    });

    return filtered;
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
    return Scaffold(
      backgroundColor: AppColours.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Transaction',
          style: AppStyles.bold(size: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showFilterBottomSheet,
            icon: const Icon(Icons.tune, color: Colors.black),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          RefreshIndicator(
            onRefresh: _loadData,
            child: Column(
              children: [
                // Month selector
                GestureDetector(
                  onTap: () => _showMonthSelector(),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedMonth,
                          style: AppStyles.medium(size: 16),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),

                // Transaction type filter
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All', TransactionType.all),
                      const SizedBox(width: 8),
                      _buildFilterChip('Income', TransactionType.income),
                      const SizedBox(width: 8),
                      _buildFilterChip('Expense', TransactionType.expense),
                      const SizedBox(width: 8),
                      _buildFilterChip('Transfer', TransactionType.transfer),
                    ],
                  ),
                ),

                // Transaction summary card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColours.primaryColour, AppColours.primaryColour.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Transaction Summary',
                        style: AppStyles.medium(size: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${defaultCurrencySymbol}${_calculateTotalBalance().toStringAsFixed(2)}',
                        style: AppStyles.titleX(size: 28, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBalanceItem(
                            'Income',
                            _calculateTotalIncome(),
                            Colors.white,
                            Icons.arrow_downward,
                          ),
                          _buildBalanceItem(
                            'Expense',
                            _calculateTotalExpense(),
                            Colors.white,
                            Icons.arrow_upward,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Transactions list header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transactions',
                        style: AppStyles.medium(size: 18),
                      ),
                      Row(
                        children: [
                          Text(
                            sortBy.name.capitalize(),
                            style: AppStyles.regular1(
                              size: 14,
                              color: AppColours.primaryColour,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColours.primaryColour,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Transactions list or loading/error states
                Expanded(
                  child: _buildTransactionsList(),
                ),

                // Add bottom padding to prevent content being hidden by nav bar
                const SizedBox(height: 80),
              ],
            ),
          ),

          // Add menu overlay (same as HomeScreen)
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
                              child: const Icon(Icons.arrow_downward, color: Colors.white),
                            ),
                            label: const Text('Income'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                              child: const Icon(Icons.swap_horiz, color: Colors.white),
                            ),
                            label: const Text('Transfer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                              child: const Icon(Icons.arrow_upward, color: Colors.white),
                            ),
                            label: const Text('Expense'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      // Bottom navigation bar - identical to HomeScreen
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

          if (index == 0) {
            _navigateToHome();
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
  Widget _buildTransactionsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No transactions found'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionItem(filteredTransactions[index]);
      },
    );
  }

  Widget _buildFilterChip(String label, TransactionType type) {
    final isSelected = selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;
          filterType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColours.primaryColour : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColours.primaryColour : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: AppStyles.medium(
            size: 14,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String title, double amount, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: AppStyles.regular1(color: color, size: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${defaultCurrencySymbol}${amount.toStringAsFixed(2)}',
          style: AppStyles.bold(color: color, size: 16),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final type = transaction.type?.toLowerCase() ?? '';
    final isExpense = type == 'expense';
    final isTransfer = type == 'transfer';
    final isIncome = type == 'income';

    String prefix;
    Color amountColor;

    if (isTransfer) {
      prefix = '';
      amountColor = AppColours.primaryColour;
    } else if (isIncome) {
      prefix = '+ ';
      amountColor = AppColours.incomeColor;
    } else {
      prefix = '- ';
      amountColor = AppColours.expenseColor;
    }

    final amount = transaction.amount ?? 0.0;
    final formattedAmount = '$prefix$defaultCurrencySymbol${amount.toStringAsFixed(2)}';

    DateTime transactionDate = DateTime.tryParse(transaction.transactionDate ?? '') ?? DateTime.now();

    IconData icon = _getTransactionIcon(transaction);

    // Get category name for display
    String categoryName = _getCategoryNameFromId(transaction.category?.id ?? transaction.category?.name);
    String label = isTransfer ? 'Transfer' :
    categoryName.isNotEmpty ? categoryName :
    isIncome ? 'Income' : 'Expense';

    String description = transaction.description ?? 'No description';

    // Add account type info to description if available
    String accountTypeName = _getAccountTypeFromAccountId(transaction.accountId);
    if (accountTypeName.isNotEmpty && accountTypeName != description) {
      description = '$description - $accountTypeName';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: amountColor),
          ),
          const SizedBox(width: 16),
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppStyles.medium(size: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppStyles.regular1(color: Colors.grey, size: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Amount and date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedAmount,
                style: AppStyles.bold(color: amountColor, size: 16),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(transactionDate), // FIXED: Now shows actual date
                style: AppStyles.regular1(color: Colors.grey, size: 14),
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
    TransactionType tempFilterType = filterType;
    SortBy tempSortBy = sortBy;
    String tempSelectedCategory = selectedCategory;
    String tempSelectedAccountType = selectedAccountType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow flexible height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75, // Start at 75% of screen height
              minChildSize: 0.5, // Minimum 50% of screen height
              maxChildSize: 0.9, // Maximum 90% of screen height
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with handle
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

                      // Scrollable content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Transaction type filter
                              Text('Type', style: AppStyles.medium(size: 16)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _buildFilterOption(
                                    'All',
                                    tempFilterType == TransactionType.all,
                                        () => setState(() => tempFilterType = TransactionType.all),
                                  ),
                                  _buildFilterOption(
                                    'Income',
                                    tempFilterType == TransactionType.income,
                                        () => setState(() => tempFilterType = TransactionType.income),
                                  ),
                                  _buildFilterOption(
                                    'Expense',
                                    tempFilterType == TransactionType.expense,
                                        () => setState(() => tempFilterType = TransactionType.expense),
                                  ),
                                  _buildFilterOption(
                                    'Transfer',
                                    tempFilterType == TransactionType.transfer,
                                        () => setState(() => tempFilterType = TransactionType.transfer),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Sort by filter
                              Text('Sort by', style: AppStyles.medium(size: 16)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _buildFilterOption(
                                    'Newest',
                                    tempSortBy == SortBy.newest,
                                        () => setState(() => tempSortBy = SortBy.newest),
                                  ),
                                  _buildFilterOption(
                                    'Oldest',
                                    tempSortBy == SortBy.oldest,
                                        () => setState(() => tempSortBy = SortBy.oldest),
                                  ),
                                  _buildFilterOption(
                                    'Highest',
                                    tempSortBy == SortBy.highest,
                                        () => setState(() => tempSortBy = SortBy.highest),
                                  ),
                                  _buildFilterOption(
                                    'Lowest',
                                    tempSortBy == SortBy.lowest,
                                        () => setState(() => tempSortBy = SortBy.lowest),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Category filter
                              Text('Category', style: AppStyles.medium(size: 16)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _showCategorySelector(tempSelectedCategory, (category) {
                                    tempSelectedCategory = category;
                                    _showFilterBottomSheet(); // Re-open the filter sheet
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
                                          tempSelectedCategory.isEmpty
                                              ? 'All Categories'
                                              : _getCategoryNameById(tempSelectedCategory),
                                          style: AppStyles.regular1(size: 14),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Account type filter
                              Text('Account', style: AppStyles.medium(size: 16)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _showAccountTypeSelector(tempSelectedAccountType, (accountType) {
                                    tempSelectedAccountType = accountType;
                                    _showFilterBottomSheet(); // Re-open the filter sheet
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
                                          tempSelectedAccountType.isEmpty
                                              ? 'All Accounts'
                                              : _getAccountTypeNameById(tempSelectedAccountType),
                                          style: AppStyles.regular1(size: 14),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40), // Extra space at bottom
                            ],
                          ),
                        ),
                      ),

                      // Fixed bottom buttons
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  tempFilterType = TransactionType.all;
                                  tempSortBy = SortBy.newest;
                                  tempSelectedCategory = '';
                                  tempSelectedAccountType = '';
                                });
                              },
                              child: Text(
                                'Reset',
                                style: TextStyle(color: AppColours.primaryColour),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                this.setState(() {
                                  filterType = tempFilterType;
                                  sortBy = tempSortBy;
                                  selectedCategory = tempSelectedCategory;
                                  selectedAccountType = tempSelectedAccountType;
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
              onAccountTypeSelected('');
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
              onAccountTypeSelected(accountTypeId);
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
                child: _buildCategoryList(currentCategory, onCategorySelected),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryList(String currentCategory, Function(String) onCategorySelected) {
    if (isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasCategoryError) {
      return Center(
        child: Text(categoryErrorMessage),
      );
    }

    return ListView.builder(
      itemCount: categories.length + 1, // +1 for "All Categories" option
      itemBuilder: (context, index) {
        if (index == 0) {
          // All Categories option
          return ListTile(
            title: const Text('All Categories'),
            leading: const Icon(Icons.category),
            selected: currentCategory.isEmpty,
            onTap: () {
              onCategorySelected('');
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
              onCategorySelected(categoryId);
              Navigator.pop(context);
            },
          );
        }
      },
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}