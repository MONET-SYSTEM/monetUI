import 'package:flutter/material.dart';
import 'package:monet/controller/account.dart';
import 'package:monet/models/account.dart';
import 'package:monet/models/transaction.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/resources/app_spacing.dart';
import 'package:monet/models/category.dart';
import 'package:monet/controller/category.dart';
import 'package:monet/views/dashboard/frequency.dart';
import '../../controller/transaction.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({Key? key, this.transaction}) : super(key: key);
  final TransactionModel? transaction;


  @override
  State<IncomeScreen> createState() => _IncomeScreenState();

}

class _IncomeScreenState extends State<IncomeScreen> {
  TextEditingController amountController = TextEditingController(text: '0');
  CategoryModel? selectedCategory;
  TextEditingController descriptionController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  bool repeatTransaction = false;
  String? repeatFrequency;
  DateTime? repeatEndDate;
  bool isLoading = true;
  List<CategoryModel> categories = [];
  List<CategoryModel> filteredCategories = [];
  List<AccountModel> accounts = [];
  AccountModel? selectedAccount;
  String selectedCurrencySymbol = '\$'; // Default

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadAccounts();
    searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterCategories);
    searchController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      final result = await AccountController.load();
      if (result.isSuccess && result.results != null) {
        setState(() {
          accounts = result.results!;
          if (accounts.isNotEmpty) {
            selectedAccount = accounts[0];
            selectedCurrencySymbol = selectedAccount!.currency.symbol;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load accounts: ${result.message}")),
        );
      }
    } catch (e) {
      print("Error loading accounts: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading accounts: $e")),
      );
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await CategoryController.load();

      if (result.isSuccess) {
        if (result.results != null && result.results is List) {
          setState(() {
            // Filter for income categories
            categories = result.results.where((category) =>
            category.type.toLowerCase() == 'income').toList();
            filteredCategories = List.from(categories);
            print("Loaded ${categories.length} income categories directly from result");
          });
        }
      } else {
        print("Failed to load categories: ${result.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load categories: ${result.message}")),
        );
      }
    } catch (e) {
      print("Error loading categories: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading categories")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterCategories() {
    if (searchController.text.isEmpty) {
      setState(() {
        filteredCategories = List.from(categories);
      });
    } else {
      setState(() {
        filteredCategories = categories
            .where((category) => category.name.toLowerCase().contains(searchController.text.toLowerCase()))
            .toList();
      });
    }
  }

  IconData _getCategoryIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.category;
    }

    switch (iconName.toLowerCase()) {
      case 'salary':
        return Icons.work;
      case 'freelance':
        return Icons.computer;
      case 'investment':
        return Icons.trending_up;
      case 'dividend':
        return Icons.attach_money;
      case 'gift':
        return Icons.card_giftcard;
      case 'refund':
        return Icons.replay;
      case 'bonus':
        return Icons.stars;
      case 'interest':
        return Icons.money;
      case 'rental':
        return Icons.home;
      case 'side hustle':
        return Icons.business_center;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }

  IconData _getAccountTypeIcon(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'bank':
      case 'bank account':
        return Icons.account_balance;
      case 'credit card':
        return Icons.credit_card;
      case 'e-wallet':
        return Icons.wallet;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Widget _buildCategoryItem(CategoryModel category) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
          Navigator.pop(context);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF00A86B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(category.icon),
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCategoryDialog() {
    final TextEditingController categoryNameController = TextEditingController();
    final TextEditingController iconNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Income Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryNameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Freelance, Bonus',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: iconNameController,
                decoration: const InputDecoration(
                  labelText: 'Icon Name (Optional)',
                  hintText: 'e.g., salary, investment, gift',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Available icons: salary, freelance, investment, dividend, gift, refund, bonus, interest, rental, side hustle, other',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
              ),
              onPressed: () async {
                if (categoryNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a category name")),
                  );
                  return;
                }

                setState(() {
                  isLoading = true;
                });
                Navigator.pop(context); // Close dialog

                try {
                  final result = await CategoryController.createCategory(
                    name: categoryNameController.text.trim(),
                    type: 'income',
                    icon: iconNameController.text.trim().isNotEmpty ? iconNameController.text.trim() : null,
                  );

                  if (result.isSuccess && result.results != null) {
                    setState(() {
                      // Add the new category to the list
                      CategoryModel newCategory = result.results;
                      categories.add(newCategory);
                      filteredCategories = List.from(categories);
                      selectedCategory = newCategory; // Select the new category
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Category '${categoryNameController.text}' created successfully")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to create category: ${result.message}")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error creating category: $e")),
                  );
                } finally {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showCategorySelector(BuildContext context) {
    searchController.clear();
    _filterCategories();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Category', style: AppStyles.medium(size: 18)),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search categories',
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                      ),
                      onChanged: (_) {
                        _filterCategories();
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: filteredCategories.isEmpty
                        ? const Center(child: Text("No matching categories found"))
                        : ListView.separated(
                      itemCount: filteredCategories.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A86B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getCategoryIcon(category.icon),
                              color: const Color(0xFF00A86B),
                              size: 24,
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            this.setState(() {
                              selectedCategory = category;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showCreateCategoryDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A86B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    child: const Text(
                      'Other Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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

  void _showWalletSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Account Type', style: AppStyles.bold(size: 20)),
              AppSpacing.vertical(size: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final formattedBalance = account.currentBalanceText.replaceAll(account.currency.symbol, '').trim();

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_getAccountTypeIcon(account.accountType.name)),
                      ),
                      title: Text(account.name),
                      subtitle: Text(
                        '${account.currency.symbol}${formattedBalance}',
                        style: const TextStyle(color: Color(0xFF00A86B)),
                      ),
                      onTap: () {
                        setState(() {
                          selectedAccount = account;
                          selectedCurrencySymbol = account.currency.symbol;
                        });
                        Navigator.pop(context);
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

  Future<void> _showFrequencyForm() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FrequencyFormScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result is Map<String, dynamic>) {
      setState(() {
        repeatFrequency = result['frequency'] as String?;
        repeatEndDate = result['endDate'] as DateTime?;
      });
    }
  }

  void _saveIncome() async {
    // Prevent multiple simultaneous saves
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Validate required fields first
      if (selectedAccount == null) {
        _showErrorMessage("Please select an account");
        return;
      }

      if (selectedCategory == null) {
        _showErrorMessage("Please select a category");
        return;
      }

      // Parse and validate amount
      double amount;
      try {
        // Get the raw text and remove currency symbols, commas, and spaces
        String rawAmount = amountController.text
            .replaceAll(selectedCurrencySymbol, '')
            .replaceAll(',', '')
            .replaceAll(' ', '')
            .trim();

        // Check if empty or just whitespace
        if (rawAmount.isEmpty || rawAmount == '0' || rawAmount == '0.0' || rawAmount == '0.00') {
          _showErrorMessage("Please enter an amount greater than zero");
          return;
        }

        // Parse the amount
        amount = double.parse(rawAmount);

        // Validate amount is positive and not too large
        if (amount <= 0) {
          _showErrorMessage("Amount must be greater than zero");
          return;
        }

        if (amount > 999999999.99) {
          _showErrorMessage("Amount is too large");
          return;
        }

      } catch (e) {
        _showErrorMessage("Please enter a valid amount (numbers only)");
        return;
      }

      // Validate description length if provided
      String description = descriptionController.text.trim();
      if (description.length > 255) {
        _showErrorMessage("Description is too long (maximum 255 characters)");
        return;
      }

      // Format today's date for transaction (using UTC to avoid timezone issues)
      final now = DateTime.now();
      final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      print("Saving income transaction:");
      print("- Account ID: ${selectedAccount!.id}");
      print("- Category ID: ${selectedCategory!.id}");
      print("- Amount: $amount");
      print("- Description: '$description'");
      print("- Date: $formattedDate");

      // Save the transaction
      final result = await TransactionController.saveTransaction(
        accountId: selectedAccount!.id,
        type: "income", // Explicitly set as income
        amount: amount,
        categoryId: selectedCategory!.id, // Now guaranteed to be non-null
        description: description.isEmpty ? null : description, // Send null if empty
        transaction_date: formattedDate,
        is_reconciled: true,
        repeat: repeatTransaction,
      );

      // Handle the result
      if (result.isSuccess) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Income added successfully"),
            backgroundColor: const Color(0xFF00A86B),
            duration: const Duration(seconds: 2),
          ),
        );

        // Clear the form or navigate back
        _clearForm();
        Navigator.of(context).pop(true); // Pass true to indicate success

      } else {
        // Show specific error message from the controller
        String errorMessage = result.message ?? "Failed to add income";
        _showErrorMessage("Failed to save: $errorMessage");
        print("Transaction save failed: ${result.message}");
      }

    } catch (e) {
      // Handle any unexpected errors
      print("Unexpected error saving income: $e");
      String userFriendlyMessage = "An unexpected error occurred. Please try again.";

      // Provide more specific error messages for common issues
      if (e.toString().contains('connection')) {
        userFriendlyMessage = "Network error. Please check your connection and try again.";
      } else if (e.toString().contains('timeout')) {
        userFriendlyMessage = "Request timed out. Please try again.";
      }

      _showErrorMessage(userFriendlyMessage);

    } finally {
      // Always reset loading state
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

// Helper method to show error messages consistently
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

// Helper method to clear the form after successful save
  void _clearForm() {
    amountController.text = '0';
    descriptionController.clear();
    setState(() {
      selectedCategory = null;
      repeatTransaction = false;
      repeatFrequency = null;
      repeatEndDate = null;
      // Keep selectedAccount as is, user probably wants to use the same account
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Green header section for income
          Container(
            color: const Color(0xFF00A86B),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App bar row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        const Text(
                          'Income',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // blank to balance
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // How much? + amount
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24)
                        .copyWith(top: 24, bottom: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How much?',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              selectedCurrencySymbol,
                              style: AppStyles.bold(color: Colors.white, size: 40),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: amountController,
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    fontSize: 48,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(
                                  fontSize: 48,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // White form area
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
                  // Category
                  GestureDetector(
                    onTap: () => _showCategorySelector(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        title: Text(
                          selectedCategory?.name ?? 'Select Category',
                          style: TextStyle(
                            fontSize: 16,
                            color: selectedCategory == null ? Colors.grey.shade400 : Colors.black87,
                          ),
                        ),
                        trailing: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Description',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account/Wallet
                  GestureDetector(
                    onTap: () => _showWalletSelector(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedAccount == null
                                ? Icons.account_balance_wallet
                                : _getAccountTypeIcon(selectedAccount!.accountType.name),
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedAccount == null
                                  ? 'Select Account Type'
                                  : '${selectedAccount!.name} (${selectedAccount!.accountType.name})',
                              style: TextStyle(
                                color: selectedAccount == null ? Colors.grey.shade500 : Colors.black87,
                              ),
                            ),
                          ),
                          if (selectedAccount != null)
                            Text(
                              '${selectedAccount!.currency.symbol}${selectedAccount!.currentBalance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF00A86B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Repeat
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Repeat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Repeat transaction',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      trailing: Switch(
                        value: repeatTransaction,
                        onChanged: (v) async {
                          if (v) {
                            await _showFrequencyForm();
                            if (repeatFrequency != null && repeatEndDate != null) {
                              setState(() {
                                repeatTransaction = true;
                              });
                            } else {
                              setState(() {
                                repeatTransaction = false;
                              });
                            }
                          } else {
                            setState(() {
                              repeatTransaction = false;
                              repeatFrequency = null;
                              repeatEndDate = null;
                            });
                          }
                        },
                        activeColor: const Color(0xFF00A86B),
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                  if (repeatTransaction && repeatFrequency != null && repeatEndDate != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
                      child: Text(
                        'Repeats: '
                        ' a0$repeatFrequency until '
                        '${repeatEndDate!.day}/${repeatEndDate!.month}/${repeatEndDate!.year}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Continue button
          SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _saveIncome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A86B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Bottom indicator line
                Container(
                  height: 4,
                  width: 36,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

