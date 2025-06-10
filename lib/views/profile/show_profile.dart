import 'package:flutter/material.dart';
import 'package:monet/controller/profile.dart';
import 'package:monet/models/result.dart';
import 'package:monet/models/user.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/resources/app_spacing.dart';
import 'package:monet/utils/helper.dart';
import 'package:intl/intl.dart';
import 'package:monet/services/profile_service.dart';
import 'dart:io';

class ShowProfileScreen extends StatefulWidget {
  const ShowProfileScreen({Key? key}) : super(key: key);

  @override
  State<ShowProfileScreen> createState() => _ShowProfileScreenState();
}

class _ShowProfileScreenState extends State<ShowProfileScreen> {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  Future<void> _getProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await ProfileController.getProfile();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess && result.results != null) {
          _user = result.results;
        } else {
          _error = result.message ?? 'Failed to load profile';
        }
      });
    }
  }

  Widget _buildProfileField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppStyles.medium(color: Colors.grey.shade600, size: 14),
          ),
          AppSpacing.vertical(size: 4),
          Text(
            value.isNotEmpty ? value : 'Not provided',
            style: AppStyles.semibold(size: 16),
          ),
          AppSpacing.vertical(size: 8),
          Divider(color: Colors.grey.shade300),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColours.primaryColour,
        title: Text('Profile Details', style: AppStyles.semibold(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _user == null
                  ? Center(child: Text('No profile information available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile avatar
                          _user!.avatar != null && _user!.avatar!.isNotEmpty && File(_user!.avatar!).existsSync()
                              ? Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: AppColours.primaryColour,
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: FileImage(File(_user!.avatar!)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: AppColours.primaryColour,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : "?",
                                      style: AppStyles.bold(size: 48, color: Colors.white),
                                    ),
                                  ),
                                ),
                          AppSpacing.vertical(size: 16),
                          // User name
                          Text(
                            _user!.name,
                            style: AppStyles.bold(size: 24),
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.vertical(size: 8),
                          // User email
                          Text(
                            _user!.email,
                            style: AppStyles.regular1(color: Colors.grey.shade700),
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.vertical(size: 32),
                          // Profile information card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Personal Information section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Personal Information',
                                      style: AppStyles.bold(size: 18),
                                    ),
                                    Icon(Icons.person, color: AppColours.primaryColour),
                                  ],
                                ),
                                AppSpacing.vertical(size: 16),
                                _buildProfileField(label: 'Email', value: _user!.email),
                                if (_user!.phone != null)
                                  _buildProfileField(label: 'Phone', value: _user!.phone!),
                                if (_user!.bio != null && _user!.bio!.isNotEmpty)
                                  _buildProfileField(label: 'Bio', value: _user!.bio!),
                                if (_user!.dateOfBirth != null)
                                  _buildProfileField(label: 'Date of Birth', value: _formatDate(_user!.dateOfBirth)),
                                if (_user!.gender != null && _user!.gender!.isNotEmpty)
                                  _buildProfileField(label: 'Gender', value: _user!.gender!),
                                // Location Information section
                                AppSpacing.vertical(size: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Location Information',
                                      style: AppStyles.bold(size: 18),
                                    ),
                                    Icon(Icons.location_on, color: AppColours.primaryColour),
                                  ],
                                ),
                                AppSpacing.vertical(size: 16),
                                if (_user!.country != null && _user!.country!.isNotEmpty)
                                  _buildProfileField(label: 'Country', value: _user!.country!),
                                if (_user!.city != null && _user!.city!.isNotEmpty)
                                  _buildProfileField(label: 'City', value: _user!.city!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}