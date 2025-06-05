import 'package:flutter/material.dart';
import 'package:monet/controller/account.dart';
import 'package:monet/controller/auth.dart';
import 'package:monet/models/account.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/resources/app_spacing.dart';
import 'package:monet/services/auth_service.dart';
import 'package:monet/models/user.dart';
import 'package:monet/utils/helper.dart';
import 'package:monet/views/dashboard/budget.dart';
import 'package:monet/views/dashboard/income.dart';
import 'package:monet/views/dashboard/expense.dart';
import 'package:monet/views/dashboard/transaction.dart';
import 'package:monet/views/dashboard/transfer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;
  int _currentIndex = 4; // Profile tab index
  bool _isAddMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await AuthService.get();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
    ).then((_) => _loadUserData());
  }

  void _showAddExpenseScreen() {
    setState(() {
      _isAddMenuOpen = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExpenseScreen()),
    ).then((_) => _loadUserData());
  }

  void _showTransferScreen() {
    setState(() {
      _isAddMenuOpen = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransferScreen()),
    ).then((_) => _loadUserData());
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

  Future<void> _showLogoutConfirmation() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout', style: AppStyles.semibold()),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      _handleLogout();
    }
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthController.logout();
      if (result.isSuccess) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.walkthrough);
      } else {
        setState(() {
          _isLoading = false;
        });
        Helper.snackBar(context, message: result.message, isSuccess: false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Helper.snackBar(context, message: "An error occurred", isSuccess: false);
    }
  }

  void _onNavigationTap(int index) {
    if (index == _currentIndex) return;

    // If it's the add button (middle item)
    if (index == 2) {
      _toggleAddMenu();
      return;
    }

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case 1:
        _navigateToTransaction();
        break;
      case 3:
        _navigateToBudget();
        break;
      case 4:
       // Already on profile screen
        break;
    }
  }

  void _showAccountsBottomSheet() async {
    setState(() => _isLoading = true);
    final result = await AccountController.load();
    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      Helper.snackBar(context, message: result.message, isSuccess: false);
      return;
    }

    final accounts = result.results as List<AccountModel>;

    if (accounts.isEmpty) {
      Helper.snackBar(context, message: "No accounts found", isSuccess: false);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Your Accounts", style: AppStyles.bold(size: 20)),
            AppSpacing.vertical(size: 16),
            Expanded(
              child: ListView.builder(
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: AppColours.primaryColour,
                        child: Text(
                          account.name[0],
                          style: AppStyles.bold(color: Colors.white),
                        ),
                      ),
                      title: Text(account.name, style: AppStyles.semibold()),
                      subtitle: Text(
                        "${account.currency.symbol} ${account.currentBalance}",
                        style: AppStyles.medium(color: Colors.grey.shade700),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.teal),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            AppRoutes.editAccount,
                            arguments: account,
                          ).then((_) => _loadUserData());
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColours.primaryColour,
                    child: Text(
                      _user?.name?.isNotEmpty == true ? _user!.name[0] : "?",
                      style: AppStyles.bold(size: 24, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _user!.name,
                                style: AppStyles.bold(size: 20),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.teal),
                              tooltip: 'Show Profile',
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.showProfile);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user!.email,
                          style: AppStyles.medium(color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text('Account Management', style: AppStyles.semibold()),
            const SizedBox(height: 12),

            // Add Account menu item
            _buildMenuItem(
              icon: Icons.add_circle,
              iconColor: Colors.white,
              backgroundColor: AppColours.primaryColour,
              title: "Add Account",
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.addAccount),
            ),

            const SizedBox(height: 12),
            // Manage Accounts menu item
            _buildMenuItem(
              icon: Icons.account_balance_wallet,
              iconColor: Colors.white,
              backgroundColor: Colors.teal,
              title: "Manage Accounts",
              onTap: () => _showAccountsBottomSheet(),
            ),

            const SizedBox(height: 12),
            // Edit Profile menu item
            _buildMenuItem(
              icon: Icons.person,
              iconColor: Colors.white,
              backgroundColor: Colors.blue,
              title: "Edit Profile",
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.editProfile),
            ),

            const SizedBox(height: 12),
            // Change Password menu item
            _buildMenuItem(
              icon: Icons.lock,
              iconColor: Colors.white,
              backgroundColor: Colors.orange,
              title: "Change Password",
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.changePassword),
            ),

            const SizedBox(height: 24),
            Text('Other', style: AppStyles.semibold()),
            const SizedBox(height: 12),

            // Logout menu item
            _buildMenuItem(
              icon: Icons.logout,
              iconColor: Colors.white,
              backgroundColor: Colors.red,
              title: "Logout",
              onTap: _showLogoutConfirmation,
            ),

            // Add padding at the bottom to avoid content being hidden behind the navigation bar
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: AppStyles.medium())),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColours.primaryColour,
        title: Text('Profile', style: AppStyles.semibold(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(child: Text('No user data'))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      color: Colors.white,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColours.primaryColour,
                            child: Text(
                              _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                              style: AppStyles.bold(size: 28, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _user!.name,
                                        style: AppStyles.bold(size: 20),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.visibility, color: Colors.teal),
                                      tooltip: 'Show Profile',
                                      onPressed: () {
                                        Navigator.pushNamed(context, AppRoutes.showProfile);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _user!.email,
                                  style: AppStyles.medium(color: Colors.grey.shade700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Account Management', style: AppStyles.semibold()),
                            const SizedBox(height: 12),

                            // Add Account menu item
                            _buildMenuItem(
                              icon: Icons.add_circle,
                              iconColor: Colors.white,
                              backgroundColor: AppColours.primaryColour,
                              title: "Add Account",
                              onTap: () => Navigator.of(context).pushNamed(AppRoutes.addAccount),
                            ),

                            const SizedBox(height: 12),
                            // Manage Accounts menu item
                            _buildMenuItem(
                              icon: Icons.account_balance_wallet,
                              iconColor: Colors.white,
                              backgroundColor: Colors.teal,
                              title: "Manage Accounts",
                              onTap: () => _showAccountsBottomSheet(),
                            ),

                            const SizedBox(height: 12),
                            // Edit Profile menu item
                            _buildMenuItem(
                              icon: Icons.person,
                              iconColor: Colors.white,
                              backgroundColor: Colors.blue,
                              title: "Edit Profile",
                              onTap: () => Navigator.of(context).pushNamed(AppRoutes.editProfile),
                            ),

                            const SizedBox(height: 12),
                            // Change Password menu item
                            _buildMenuItem(
                              icon: Icons.lock,
                              iconColor: Colors.white,
                              backgroundColor: Colors.orange,
                              title: "Change Password",
                              onTap: () => Navigator.of(context).pushNamed(AppRoutes.changePassword),
                            ),

                            const SizedBox(height: 24),
                            Text('Other', style: AppStyles.semibold()),
                            const SizedBox(height: 12),

                            // Logout menu item
                            _buildMenuItem(
                              icon: Icons.logout,
                              iconColor: Colors.white,
                              backgroundColor: Colors.red,
                              title: "Logout",
                              onTap: _showLogoutConfirmation,
                            ),

                            // Add padding at the bottom to avoid content being hidden behind the navigation bar
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColours.primaryColour,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: _onNavigationTap,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          // Center add button with special styling
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

