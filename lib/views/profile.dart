import 'package:flutter/material.dart';
import 'package:monet/controller/auth.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/services/auth_service.dart';
import 'package:monet/models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;
  int _currentIndex = 4; // Set to Profile tab index (4)

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
      final userData = await AuthService.get();
      setState(() {
        _user = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load user profile: $e")),
      );
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Logout?',
            style: AppStyles.bold(size: 18),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Are you sure do you wanna logout?',
            style: AppStyles.regular1(size: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFE8E3F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'No',
                      style: AppStyles.medium(size: 16, color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColours.primaryColour,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Yes',
                      style: AppStyles.medium(size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
      // First clear local storage regardless of API response
      await AuthService.delete();

      // Then attempt to notify the server
      try {
        await AuthController.logout();
      } catch (e) {
        // Log but don't block logout due to API errors
        print("Error during server logout: $e");
      }

      // Navigate to login screen and clear navigation stack
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error during logout: $e")),
        );
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: Text(
          'Profile',
          style: AppStyles.bold(size: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Section
                  Row(
                    children: [
                      // Profile Image
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: AssetImage('assets/images/avatar.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Profile Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Username',
                              style: AppStyles.regular1(
                                  size: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _user?.name ?? 'User Profile',
                                    style: AppStyles.bold(size: 24),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Transform.rotate(
                                  angle: 0.785398, // 45 degrees in radians
                                  child: const Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Menu Items with the new design
                  _buildMenuItem(
                    icon: Icons.account_circle,
                    iconColor: AppColours.primaryColour,
                    backgroundColor: const Color(0xFFE3F2FD),
                    title: 'Account',
                    onTap: () {
                      // Navigate to account info
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.settings,
                    iconColor: AppColours.primaryColour,
                    backgroundColor: const Color(0xFFE8E3F3),
                    title: 'Settings',
                    onTap: () {
                      // Navigate to settings
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.upload,
                    iconColor: AppColours.primaryColour,
                    backgroundColor: const Color(0xFFE3F2FD),
                    title: 'Export Data',
                    onTap: () {
                      // Handle export data
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.logout,
                    iconColor: AppColours.expenseColor,
                    backgroundColor: const Color(0xFFFFEBEE),
                    title: 'Logout',
                    onTap: _showLogoutConfirmation,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Navigation Bar - using the same style as HomeScreen for consistency
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColours.primaryColour,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == 0) {  // Home
                _navigateToHome();
              }
              // Add other navigation options as needed
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
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
                    color: AppColours.primaryColour,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
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
        ],
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: AppStyles.medium(size: 16),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}