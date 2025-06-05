import 'package:flutter/material.dart';
import 'package:monet/controller/account.dart';
import 'package:monet/models/account.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/resources/app_spacing.dart';
import 'package:monet/models/category.dart';
import 'package:monet/controller/category.dart';
import 'package:monet/controller/transaction.dart';
import 'package:monet/utils/helper.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  TextEditingController amountController = TextEditingController(text: '0');
  CategoryModel? selectedCategory;
  TextEditingController descriptionController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  bool repeatTransaction = false;
  bool isLoading = true;
  bool isLoadingAccounts = true; // Add specific loading state for accounts
  bool isSaving = false; // Separate loading state for saving
  List<CategoryModel> categories = [];
  List<CategoryModel> filteredCategories = [];
  List<AccountModel> accounts = [];
  AccountModel? selectedAccount;
  String selectedCurrencySymbol = '\$';
  String accountErrorMessage = '';

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
    setState(() {
      isLoadingAccounts = true;
      accountErrorMessage = '';
    });

    try {
      final result = await AccountController.load();
      if (result.isSuccess && result.results != null) {
        setState(() {
          accounts = result.results!;
          isLoadingAccounts = false;

          if (accounts.isNotEmpty) {
            selectedAccount = accounts[0];
            selectedCurrencySymbol = selectedAccount!.currency.symbol;
          } else {
            accountErrorMessage = "No accounts available. Please create an account first.";
          }
        });
      } else {
        setState(() {
          isLoadingAccounts = false;
          accountErrorMessage = "Failed to load accounts: ${result.message ?? 'Unknown error'}";
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(accountErrorMessage)),
          );
        }
      }
    } catch (e) {
      print("Error loading accounts: $e");
      setState(() {
        isLoadingAccounts = false;
        accountErrorMessage = "Error loading accounts: $e";
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accountErrorMessage)),
        );
      }
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
            categories = result.results.where((category) =>
            category.type.toLowerCase() == 'expense').toList();
            filteredCategories = List.from(categories);
            print("Loaded ${categories.length} expense categories from result");
          });
        }
      } else {
        print("Failed to load categories: ${result.message}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load categories: ${result.message}")),
          );
        }
      }
    } catch (e) {
      print("Error loading categories: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading categories")),
        );
      }
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

  void _showCreateCategoryDialog() {
    final TextEditingController categoryNameController = TextEditingController();
    final TextEditingController iconNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Expense Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryNameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Groceries, Travel',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: iconNameController,
                decoration: const InputDecoration(
                  labelText: 'Icon Name (Optional)',
                  hintText: 'e.g., food, shopping, transport',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Available icons: food, shopping, transport, bills, entertainment, health, education, groceries, housing, utilities, insurance, personal, clothing, gifts',
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
                backgroundColor: AppColours.primaryColour,
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
                Navigator.pop(context);

                try {
                  final result = await CategoryController.createCategory(
                    name: categoryNameController.text.trim(),
                    type: 'expense',
                    icon: iconNameController.text.trim(),
                  );

                  if (result.isSuccess && result.results != null) {
                    await _loadCategories();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Category created successfully")),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to create category: ${result.message}")),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error creating category: $e")),
                    );
                  }
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

  void _navigateToCreateAccount() {
    // This is where you would navigate to an account creation screen
    // For now, just show a message that this functionality would be added
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Navigate to create account screen")),
    );
    // Example navigation (uncomment and modify when you have an account creation screen):
    // Navigator.of(context).push(
    //   MaterialPageRoute(builder: (context) => CreateAccountScreen()),
    // ).then((_) {
    //   _loadAccounts(); // Refresh accounts after returning
    // });
  }

  IconData _getCategoryIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.category;
    }

    switch (iconName.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_cart;
      case 'transport':
        return Icons.directions_car;
      case 'bills':
        return Icons.receipt;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'housing':
        return Icons.home;
      case 'utilities':
        return Icons.power;
      case 'insurance':
        return Icons.security;
      case 'personal':
        return Icons.person;
      case 'clothing':
        return Icons.checkroom;
      case 'gifts':
        return Icons.card_giftcard;
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
          color: AppColours.primaryColour,
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
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search categories',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (_) {
                        setState(() {
                          _filterCategories();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: filteredCategories.isEmpty
                        ? Center(
                      child: Text(
                        'No categories found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                        : SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: filteredCategories
                            .map((category) => _buildCategoryItem(category))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _showCreateCategoryDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColours.primaryColour,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create New Category',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
      isScrollControlled: true, // Allow flexible height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.all(16),
                height: MediaQuery.of(context).size.height * 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Account', style: AppStyles.bold(size: 20)),
                    AppSpacing.vertical(size: 16),

                    // Handle different states
                    Expanded(
                      child: _buildAccountsList(),
                    ),

                    // Add account button at bottom
                    if (accounts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _navigateToCreateAccount();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColours.primaryColour,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Create New Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  Widget _buildAccountsList() {
    if (isLoadingAccounts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (accountErrorMessage.isNotEmpty && accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              accountErrorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAccounts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColours.primaryColour,
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No accounts found.\nPlease create an account first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        final formattedBalance = account.currentBalanceText.replaceAll(account.currency.symbol, '').trim();

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColours.primaryColour.withOpacity(0.1),
            child: Icon(
              _getAccountTypeIcon(account.accountType.code),
              color: AppColours.primaryColour,
            ),
          ),
          title: Text(account.name),
          subtitle: Text(
            '${account.currency.symbol} $formattedBalance',
            style: TextStyle(color: AppColours.primaryColour),
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
    );
  }

  // Simplified _saveExpense method without file handling
  Future<void> _saveExpense() async {
    // Validate required fields
    if (selectedAccount == null) {
      Helper.snackBar(context, message: "Please select an account", isSuccess: false);
      return;
    }

    if (selectedCategory == null) {
      Helper.snackBar(context, message: "Please select a category", isSuccess: false);
      return;
    }

    double? amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      Helper.snackBar(context, message: "Please enter a valid amount", isSuccess: false);
      return;
    }

    // Show loading indicator
    setState(() {
      isSaving = true;
    });

    try {
      final fullTimestamp = DateTime.now().toIso8601String();

      // Save the transaction
      final result = await TransactionController.saveTransaction(
        accountId: selectedAccount!.id,
        type: 'expense',
        amount: amount,
        categoryId: selectedCategory!.id,
        description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
        transaction_date: fullTimestamp,
        is_reconciled: false,
        repeat: repeatTransaction,
      );

      if (result.isSuccess && result.results != null) {
        if (mounted) {
          Helper.snackBar(context, message: "Expense saved successfully", isSuccess: true);
          Navigator.pop(context);
        }
      } else {
        // Transaction save failed
        String errorMsg = result.message ?? "Failed to save expense";

        if (result.errors != null) {
          if (result.errors is Map) {
            result.errors?.forEach((key, value) {
              errorMsg += "\n• $key: ${value is List ? value.join(', ') : value}";
            });
          } else {
            errorMsg += "\n• ${result.errors}";
          }
        }

        if (mounted) {
          Helper.snackBar(context, message: errorMsg, isSuccess: false);
        }
      }
    } catch (e) {
      print("Exception during transaction save: $e");
      if (mounted) {
        Helper.snackBar(context, message: "Error saving transaction: $e", isSuccess: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Red header section for expense
          Container(
            color: AppColours.expenseColor,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App bar row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const Text(
                          'Add Expense',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // How much? + amount
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How much?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              selectedCurrencySymbol,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (selectedCategory != null)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColours.primaryColour,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getCategoryIcon(selectedCategory!.icon),
                                color: Colors.white,
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.category,
                                color: Colors.white,
                              ),
                            ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedCategory?.name ?? 'Select Category',
                                style: TextStyle(
                                  color: selectedCategory != null ? Colors.black : Colors.grey[400],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: descriptionController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account/Wallet
                  GestureDetector(
                    onTap: () => _showWalletSelector(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (selectedAccount != null)
                            CircleAvatar(
                              backgroundColor: AppColours.primaryColour.withOpacity(0.1),
                              child: Icon(
                                _getAccountTypeIcon(selectedAccount!.accountType.code),
                                color: AppColours.primaryColour,
                              ),
                            )
                          else
                            CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                              ),
                            ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedAccount?.name ?? 'Select Account',
                                style: TextStyle(
                                  color: selectedAccount != null ? Colors.black : Colors.grey[400],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (selectedAccount != null)
                                Text(
                                  '${selectedAccount!.currency.symbol} ${selectedAccount!.currentBalanceText}',
                                  style: TextStyle(
                                    color: AppColours.primaryColour,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Repeat
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      title: const Text('Repeat this transaction'),
                      subtitle: const Text('The transaction will be repeated automatically'),
                      trailing: Switch(
                        value: repeatTransaction,
                        activeColor: AppColours.primaryColour,
                        onChanged: (value) {
                          setState(() {
                            repeatTransaction = value;
                          });
                        },
                      ),
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
                    onPressed: isSaving ? null : _saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColours.primaryColour,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
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