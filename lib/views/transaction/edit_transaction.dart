import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monet/controller/account.dart';
import 'package:monet/controller/category.dart';
import 'package:monet/controller/transaction.dart';
import 'package:monet/models/account.dart';
import 'package:monet/models/category.dart';
import 'package:monet/models/result.dart';
import 'package:monet/models/transaction.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({Key? key, required this.transaction}) : super(key: key);

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _categoryNameController = TextEditingController();

  String _selectedAccountId = '';
  String _selectedCategoryId = '';
  DateTime _selectedDate = DateTime.now();
  bool _isReconciled = false;
  bool _isLoading = false;

  List<AccountModel> _accounts = [];
  List<dynamic> _categories = [];
  String _transactionType = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadAccountsAndCategories();
  }

  void _initializeData() {
    TransactionModel tx = widget.transaction;
    _transactionType = tx.type.toLowerCase();
    _amountController.text = tx.amount.toString();
    _descriptionController.text = tx.description ?? '';
    _selectedAccountId = tx.accountId;
    _isReconciled = tx.isReconciled;

    // Handle category more robustly
    if (tx.category != null) {
      var normalizedCategory = _normalizeCategoryData(tx.category);
      if (normalizedCategory.isNotEmpty) {
        _selectedCategoryId = normalizedCategory['id']?.toString() ?? '';
        String categoryName = normalizedCategory['name']?.toString() ?? '';
        if (categoryName.isNotEmpty) {
          _categoryNameController.text = categoryName;
        }
      }
    }

    // Handle date
    if (tx.transactionDate.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(tx.transactionDate);
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      } catch (_) {
        _selectedDate = DateTime.now();
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      }
    } else {
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    }

    print('Initialized with category ID: $_selectedCategoryId, name: ${_categoryNameController.text}');
  }

  Map<String, dynamic> _normalizeCategoryData(dynamic category) {
    if (category == null) return {};

    try {
      if (category is Map<String, dynamic>) {
        return category;
      } else if (category is Map) {
        return Map<String, dynamic>.from(category);
      } else if (category is CategoryModel) {
        return {
          'id': category.id,
          'name': category.name,
          'type': category.type,
          'icon': category.icon,
          'colourCode': category.colourCode,
          'description': category.description,
          'isSystem': category.isSystem,
        };
      }
    } catch (e) {
      print('Error normalizing category data: $e');
    }

    return {};
  }

  Future<void> _loadAccountsAndCategories() async {
    setState(() => _isLoading = true);

    try {
      // Load accounts
      final accountResult = await AccountController.load();
      if (accountResult.isSuccess && accountResult.results != null) {
        setState(() => _accounts = accountResult.results!);
      }

      // Load categories
      final categoryResult = await CategoryController.load();
      if (categoryResult.isSuccess && categoryResult.results != null) {
        print('Loaded categories: ${categoryResult.results}');
        setState(() => _categories = categoryResult.results!);

        // Debug: Print the categories structure
        for (var cat in _categories) {
          print('Category: $cat, Type: ${cat.runtimeType}');
        }
      }

      // Validate selected IDs after loading data
      _validateSelectedIds();
    } catch (e) {
      print('Error loading categories: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _validateSelectedIds() {
    // Validate account ID
    if (_selectedAccountId.isNotEmpty) {
      bool accountExists = _accounts.any((account) => account.id == _selectedAccountId);
      if (!accountExists) {
        print('Account ID $_selectedAccountId not found in loaded accounts');
        _selectedAccountId = '';
      }
    }

    // Validate category ID
    if (_selectedCategoryId.isNotEmpty) {
      bool categoryExists = _categories
          .where((cat) => _getCategoryType(cat) == _transactionType)
          .any((cat) => _getCategoryId(cat) == _selectedCategoryId);
      if (!categoryExists) {
        print('Category ID $_selectedCategoryId not found in loaded categories');
        // Don't clear the ID, keep it for display purposes
      }
    }
  }

  String _getCategoryId(dynamic category) {
    try {
      if (category is Map) {
        return category['id']?.toString() ?? '';
      } else if (category is CategoryModel) {
        return category.id?.toString() ?? '';
      } else {
        // Try reflection for other objects
        return category.id?.toString() ?? '';
      }
    } catch (e) {
      print('Error getting category ID: $e');
      return '';
    }
  }

  String _getCategoryName(dynamic category) {
    if (category == null) return 'Unknown';

    try {
      if (category is Map) {
        return category['name']?.toString() ?? 'Unknown';
      } else if (category is CategoryModel) {
        return category.name?.toString() ?? 'Unknown';
      } else {
        // Try reflection for other objects
        return category.name?.toString() ?? 'Unknown';
      }
    } catch (e) {
      print('Error getting category name: $e');
      return 'Unknown';
    }
  }

  String _getCategoryNameById(String categoryId) {
    if (categoryId.isEmpty) {
      return 'No Category Selected';
    }

    try {
      // First, try to find the category in the loaded categories
      for (var cat in _categories) {
        String catId = _getCategoryId(cat);
        if (catId == categoryId) {
          String name = _getCategoryName(cat);
          if (name != 'Unknown' && name.isNotEmpty) {
            return name;
          }
        }
      }

      // If not found in loaded categories, check if we have it in the controller
      if (_categoryNameController.text.isNotEmpty) {
        return _categoryNameController.text;
      }

      // Last resort: try to get from the original transaction
      if (widget.transaction.category != null) {
        try {
          if (widget.transaction.category is CategoryModel) {
            CategoryModel cat = widget.transaction.category as CategoryModel;
            if (cat.id == categoryId) {
              return cat.name;
            }
          } else {
            // Handle dynamic category
            var cat = widget.transaction.category as dynamic;
            if (cat['id'] == categoryId && cat['name'] != null) {
              return cat['name'].toString();
            }
          }
        } catch (e) {
          print('Error accessing original transaction category: $e');
        }
      }
    } catch (e) {
      print('Error in _getCategoryNameById: $e');
    }

    return 'Category Not Found (ID: $categoryId)';
  }

  String _getCategoryType(dynamic category) {
    try {
      if (category is Map) {
        return category['type']?.toString().toLowerCase() ?? 'expense';
      } else if (category is CategoryModel) {
        return category.type?.toString().toLowerCase() ?? 'expense';
      } else {
        return category.type?.toString().toLowerCase() ?? 'expense';
      }
    } catch (e) {
      print('Error getting category type: $e');
      return 'expense';
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  double _getSanitizedAmount() {
    // Remove any non-numeric characters except dot and comma
    String raw = _amountController.text.replaceAll(RegExp(r'[^0-9.,]'), '');
    // Replace comma with dot if present
    raw = raw.replaceAll(',', '.');
    // Parse to double
    return double.tryParse(raw) ?? 0.0;
  }

  Future<void> _updateTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final double sanitizedAmount = _getSanitizedAmount();
      print('Sanitized amount to send: $sanitizedAmount');

      // Find the selected category as a CategoryModel
      CategoryModel? selectedCategoryModel;
      if (_selectedCategoryId.isNotEmpty) {
        final found = _categories.cast<dynamic>().firstWhere(
              (cat) => (_getCategoryId(cat) == _selectedCategoryId),
          orElse: () => null,
        );

        if (found != null) {
          if (found is CategoryModel) {
            selectedCategoryModel = found;
          } else if (found is Map<String, dynamic>) {
            selectedCategoryModel = CategoryModel.fromMap(found);
          } else if (found is Map) {
            selectedCategoryModel = CategoryModel.fromMap(Map<String, dynamic>.from(found));
          }
        } else {
          // If category not found in loaded list, try to create from original transaction
          if (widget.transaction.category != null) {
            try {
              if (widget.transaction.category is CategoryModel) {
                selectedCategoryModel = widget.transaction.category as CategoryModel;
              } else {
                var catMap = _normalizeCategoryData(widget.transaction.category);
                if (catMap.isNotEmpty) {
                  selectedCategoryModel = CategoryModel.fromMap(catMap);
                }
              }
            } catch (e) {
              print('Error creating category model from transaction: $e');
            }
          }
        }
      }

      // Always update the category name in the selectedCategoryModel before saving transaction
      if (selectedCategoryModel != null && _categoryNameController.text.trim().isNotEmpty) {
        selectedCategoryModel = CategoryModel()
          ..id = selectedCategoryModel.id
          ..name = _categoryNameController.text.trim()
          ..icon = selectedCategoryModel.icon
          ..type = selectedCategoryModel.type
          ..colourCode = selectedCategoryModel.colourCode
          ..description = selectedCategoryModel.description
          ..isSystem = selectedCategoryModel.isSystem;

        // Persist the category name change globally
        try {
          await CategoryController.updateCategory(selectedCategoryModel);
        } catch (e) {
          print('Warning: Could not update category globally: $e');
        }
      }

      final updatedTransaction = widget.transaction.copyWith(
        accountId: _selectedAccountId,
        type: _transactionType,
        amount: sanitizedAmount,
        description: _descriptionController.text,
        transactionDate: _dateController.text,
        isReconciled: _isReconciled,
        category: selectedCategoryModel,
      );

      final Result<TransactionModel> result =
      await TransactionController.updateTransaction(updatedTransaction);

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Failed to update transaction'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating transaction: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<DropdownMenuItem<String>> _buildCategoryDropdownItems() {
    if (_categories.isEmpty) {
      return [];
    }

    // Filter categories by transaction type
    final filteredCategories = _categories
        .where((cat) => _getCategoryType(cat) == _transactionType)
        .toList();

    // Return empty list if no matching categories
    if (filteredCategories.isEmpty) {
      return [];
    }

    // Build dropdown items
    return filteredCategories.map((category) {
      String id = _getCategoryId(category);
      String name = _getCategoryName(category);

      return DropdownMenuItem<String>(
        value: id,
        child: Text(name),
      );
    }).toList();
  }

  String _getCurrencySymbol() {
    try {
      if (_selectedAccountId.isEmpty || _accounts.isEmpty) {
        return '\$'; // Default symbol if no account selected
      }

      // Find the selected account using orElse to handle not found case
      final selectedAccount = _accounts.firstWhere(
            (account) => account.id == _selectedAccountId,
        orElse: () => _accounts.first, // Fallback to first account
      );

      // Return the currency symbol from the account's currency
      return selectedAccount?.currency?.symbol ?? '\$';
    } catch (e) {
      print('Error getting currency symbol: $e');
      return '\$'; // Default symbol on error
    }
  }

  Color _getHeaderColor() {
    switch (_transactionType) {
      case 'income':
        return AppColours.incomeColor;
      case 'expense':
        return AppColours.expenseColor;
      case 'transfer':
        return AppColours.transferColor;
      default:
        return AppColours.primaryColour;
    }
  }

  IconData _getCategoryIconById(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty || _categories.isEmpty) return Icons.category;
    try {
      final category = _categories.firstWhere(
        (cat) => _getCategoryId(cat) == categoryId,
        orElse: () => null,
      );
      if (category != null) {
        String? iconName;
        if (category is Map) {
          iconName = category['icon']?.toString();
        } else {
          iconName = category.icon?.toString();
        }
        return _getIconFromName(iconName);
      }
    } catch (e) {}
    return Icons.category;
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${_transactionType.capitalize()}'),
        backgroundColor: _getHeaderColor(),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount field
              Text('Amount', style: AppStyles.medium()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter amount',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
                    child: Text(
                      _getCurrencySymbol(),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Account dropdown (read-only)
              Text('Account', style: AppStyles.medium()),
              const SizedBox(height: 8),
              AbsorbPointer(
                absorbing: true,
                child: DropdownButtonFormField<String>(
                  value: _selectedAccountId.isNotEmpty &&
                      _accounts.any((account) => account.id == _selectedAccountId)
                      ? _selectedAccountId
                      : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Select account',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  items: _accounts.map((account) {
                    return DropdownMenuItem<String>(
                      value: account.id,
                      child: Text(account.name ?? 'Unknown Account'),
                    );
                  }).toList(),
                  onChanged: null, // Disable changing
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an account';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Category dropdown (read-only)
              Text('Category', style: AppStyles.medium()),
              const SizedBox(height: 8),
              AbsorbPointer(
                absorbing: true,
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(_getCategoryIconById(_selectedCategoryId), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _selectedCategoryId.isNotEmpty
                              ? _getCategoryNameById(_selectedCategoryId)
                              : 'Unknown Category',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description field
              Text('Description', style: AppStyles.medium()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter description',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),

              // Date field
              Text('Date', style: AppStyles.medium()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Select date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),

              // Reconciled checkbox
              CheckboxListTile(
                title: Text('Reconciled', style: AppStyles.medium()),
                value: _isReconciled,
                onChanged: (value) {
                  setState(() => _isReconciled = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              // Update button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _updateTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getHeaderColor(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Update',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _categoryNameController.dispose();
    super.dispose();
  }
}

extension StringExtensions on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}