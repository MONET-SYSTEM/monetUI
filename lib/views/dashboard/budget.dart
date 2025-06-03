import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/views/dashboard/home.dart';
import 'package:monet/views/dashboard/expense.dart';
import 'package:monet/views/dashboard/income.dart';
import 'package:monet/views/dashboard/profile.dart';
import 'package:monet/views/dashboard/transaction.dart';
import 'package:monet/views/dashboard/transfer.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  int _currentIndex = 3; // Budget tab index
  bool _isAddMenuOpen = false;
  DateTime _selectedMonth = DateTime.now();

  // Sample budget data - replace with your actual data model
  List<Map<String, dynamic>> budgets = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Column(
            children: [
              // Header with month navigation
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColours.primaryColour, Color(0xFF7C3AED)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month - 1,
                              );
                            });
                          },
                          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                        ),
                        Text(
                          _getMonthName(_selectedMonth),
                          style: AppStyles.bold(size: 20, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month + 1,
                              );
                            });
                          },
                          icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Main content
              Expanded(
                child: budgets.isEmpty ? _buildEmptyState() : _buildBudgetList(),
              ),
            ],
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
      // Bottom navigation bar - matching HomeScreen
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

          if (index == 1) {
            _navigateToTransaction();
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Empty state illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pie_chart_outline,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "You don't have a budget.",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Let's make one so you in control.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            // Create budget button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 32),
              child: ElevatedButton(
                onPressed: _createBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColours.primaryColour,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Create a budget',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        return _buildBudgetItem(budget);
      },
    );
  }

  Widget _buildBudgetItem(Map<String, dynamic> budget) {
    final spent = budget['spent'] as double;
    final total = budget['total'] as double;
    final progress = spent / total;
    final remaining = total - spent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColours.primaryColour.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  budget['icon'] as IconData,
                  color: AppColours.primaryColour,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget['category'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${remaining.toStringAsFixed(2)} remaining',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${spent.toStringAsFixed(2)} / \$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.8 ? Colors.red : AppColours.primaryColour,
            ),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  String _getMonthName(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // Navigation methods to match HomeScreen
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _navigateToTransaction() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TransactionScreen()),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  // Add menu toggle and button methods
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
    );
  }

  void _showAddExpenseScreen() {
    setState(() {
      _isAddMenuOpen = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExpenseScreen()),
    );
  }

  void _showTransferScreen() {
    setState(() {
      _isAddMenuOpen = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransferScreen()),
    );
  }

  void _createBudget() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Budget'),
        content: const Text('Budget creation functionality would go here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                budgets.add({
                  'category': 'Food & Dining',
                  'icon': Icons.restaurant,
                  'spent': 250.0,
                  'total': 500.0,
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}