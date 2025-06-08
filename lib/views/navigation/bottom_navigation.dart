import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/views/dashboard/budget.dart';
import 'package:monet/views/dashboard/expense.dart';
import 'package:monet/views/dashboard/home.dart';
import 'package:monet/views/dashboard/income.dart';
import 'package:monet/views/dashboard/profile.dart';
import 'package:monet/views/dashboard/transaction.dart';
import 'package:monet/views/dashboard/transfer.dart';

class BottomNavigatorScreen extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function()? onRefresh;

  const BottomNavigatorScreen({
    Key? key,
    required this.child,
    required this.currentIndex,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<BottomNavigatorScreen> createState() => _BottomNavigatorScreenState();
}

class _BottomNavigatorScreenState extends State<BottomNavigatorScreen> {
  late int _currentIndex;
  bool _isAddMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

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
    ).then((_) => _refreshCurrentScreen());
  }

  void _showAddExpenseScreen() {
    setState(() {
      _isAddMenuOpen = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExpenseScreen()),
    ).then((_) => _refreshCurrentScreen());
  }

  void _showTransferScreen() {
    setState(() {
      _isAddMenuOpen = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransferScreen()),
    ).then((_) => _refreshCurrentScreen());
  }

  void _refreshCurrentScreen() {
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }

  void _navigateToScreen(int index) {
    // If current tab is tapped again, do nothing
    if (index == _currentIndex && index != 2) {
      return;
    }

    // If it's the add button (middle item)
    if (index == 2) {
      _toggleAddMenu();
      return;
    }

    // Navigate to the appropriate screen
    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1: // Transaction
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TransactionScreen()),
        );
        break;
      case 3: // Budget
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BudgetScreen()),
        );
        break;
      case 4: // Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        ).then((_) => _refreshCurrentScreen());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          widget.child,

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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColours.primaryColour,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: _currentIndex,
        onTap: _navigateToScreen,
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
}