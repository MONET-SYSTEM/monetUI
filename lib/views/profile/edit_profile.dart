import 'package:flutter/material.dart';
import 'package:monet/models/user.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/controller/profile.dart';
import 'package:monet/utils/helper.dart';
import 'package:monet/widgets/app_button.dart';
import 'package:monet/widgets/app_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  // Additional controllers
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();

  UserModel? _user;
  bool _isLoading = false;
  String? _gender;
  DateTime? _dateOfBirth;
  File? _avatarFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _genderOptions = ['male', 'female', 'other'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final result = await ProfileController.getProfile();
      if (result.isSuccess && result.results != null) {
        setState(() {
          _user = result.results;
          _nameController.text = _user?.name ?? '';
          _emailController.text = _user?.email ?? '';
          _phoneController.text = _user?.phone ?? '';
          _bioController.text = _user?.bio ?? '';
          _gender = _user?.gender;
          _dateOfBirth = _user?.dateOfBirth;
          _countryController.text = _user?.country ?? '';
          _cityController.text = _user?.city ?? '';
          // Load avatar from user model if exists
          if (_user?.avatar != null && _user!.avatar!.isNotEmpty) {
            _avatarFile = File(_user!.avatar!);
          }
        });
      } else {
        _showSnackBar(result.message ?? 'Failed to load profile');
      }
    } catch (e) {
      _showSnackBar('Error loading profile: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Save avatar path if selected
      String? avatarPath = _avatarFile?.path;
      final result = await ProfileController.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
        gender: _gender,
        dateOfBirth: _dateOfBirth,
        country: _countryController.text.isNotEmpty ? _countryController.text : null,
        city: _cityController.text.isNotEmpty ? _cityController.text : null,
        avatar: avatarPath,
      );

      if (result.isSuccess) {
        _showSnackBar('Profile updated successfully', isSuccess: true);
        Navigator.pop(context, true); // Return success to previous screen
      } else {
        _showSnackBar(result.message ?? 'Failed to update profile');
      }
    } catch (e) {
      _showSnackBar('Error updating profile: ${e.toString()}');
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _pickAvatar() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Save to app's documents directory (not assets, which is read-only)
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      setState(() {
        _avatarFile = savedImage;
      });
      _showSnackBar('Avatar updated!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColours.primaryColour,
        title: Text('Edit Profile', style: AppStyles.semibold(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading && _user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Avatar Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColours.primaryColour,
                        backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                        child: _avatarFile == null
                            ? Text(
                          _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                          style: AppStyles.bold(size: 40, color: Colors.white),
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickAvatar,
                      child: Text(
                        'Change Avatar',
                        style: AppStyles.medium(color: AppColours.primaryColour),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text('Basic Information', style: AppStyles.semibold(size: 18)),
              const SizedBox(height: 16),

              // Name Field
              AppTextField(
                controller: _nameController,
                labelText: 'Full Name',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field
              AppTextField(
                controller: _emailController,
                labelText: 'Email Address',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                readOnly: true, // Make email field read-only
                textStyle: AppStyles.medium(color: Colors.grey.shade700), // Style to indicate it's not editable
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field
              AppTextField(
                controller: _phoneController,
                labelText: 'Phone Number (optional)',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              Text('Personal Details', style: AppStyles.semibold(size: 18)),
              const SizedBox(height: 16),

              // Date of Birth Field
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth (optional)',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  child: Text(
                    _dateOfBirth != null
                        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                        : 'Select date',
                    style: AppStyles.regular1(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Gender (optional)',
                  prefixIcon: const Icon(Icons.people),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                value: _gender,
                items: _genderOptions.map((String gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(
                      gender.substring(0, 1).toUpperCase() + gender.substring(1),
                      style: AppStyles.regular1(),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _gender = newValue);
                },
              ),
              const SizedBox(height: 16),

              // Bio Field
              AppTextField(
                controller: _bioController,
                labelText: 'Bio (optional)',
                prefixIcon: Icons.description,
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 24),

              Text('Location', style: AppStyles.semibold(size: 18)),
              const SizedBox(height: 16),

              // Country Field
              AppTextField(
                controller: _countryController,
                labelText: 'Country (optional)',
                prefixIcon: Icons.public,
              ),
              const SizedBox(height: 16),

              // City Field
              AppTextField(
                controller: _cityController,
                labelText: 'City (optional)',
                prefixIcon: Icons.location_city,
              ),
              const SizedBox(height: 32),

              // Save Button
              AppButton(
                onPressed: _updateProfile,
                text: 'Save Changes',
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}