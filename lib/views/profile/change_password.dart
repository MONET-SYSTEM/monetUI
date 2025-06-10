import 'package:flutter/material.dart';
import 'package:monet/controller/profile.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/utils/helper.dart';
import 'package:monet/widgets/app_button.dart';
import 'package:monet/widgets/app_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ProfileController.updatePassword(
        currentPassword: _currentPasswordController.text,
        password: _newPasswordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (result.isSuccess) {
        _showSnackBar('Password updated successfully', isSuccess: true);
        Navigator.pop(context, true); // Return success to previous screen
      } else {
        _showSnackBar(result.message ?? 'Failed to update password');
      }
    } catch (e) {
      _showSnackBar('Error updating password: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    Helper.snackBar(
      context,
      message: message,
      isSuccess: isSuccess,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColours.primaryColour,
        title: Text('Change Password', style: AppStyles.semibold(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Security icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColours.primaryColour.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 50,
                    color: AppColours.primaryColour,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Password Security',
                style: AppStyles.semibold(size: 18),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Please enter your current password and choose a new password.',
                style: AppStyles.regular1(color: Colors.grey.shade700),
              ),

              const SizedBox(height: 32),

              // Current Password Field
              AppTextField(
                controller: _currentPasswordController,
                labelText: 'Current Password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureCurrentPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // New Password Field
              AppTextField(
                controller: _newPasswordController,
                labelText: 'New Password',
                prefixIcon: Icons.lock,
                obscureText: _obscureNewPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() => _obscureNewPassword = !_obscureNewPassword);
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Confirm New Password Field
              AppTextField(
                controller: _confirmPasswordController,
                labelText: 'Confirm New Password',
                prefixIcon: Icons.lock,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Password Requirements
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Password requirements:', style: AppStyles.medium()),
                    const SizedBox(height: 8),
                    _buildRequirement('At least 6 characters long'),
                    _buildRequirement('Combination of letters, numbers, and special characters recommended'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Update Password Button
              AppButton(
                onPressed: _updatePassword,
                text: 'Update Password',
                isLoading: _isLoading,
                textColor: AppColours.backgroundColor,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppStyles.regular1()),
          ),
        ],
      ),
    );
  }
}