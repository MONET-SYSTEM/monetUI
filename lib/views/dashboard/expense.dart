import 'package:flutter/material.dart';
import 'package:monet/controller/account.dart';
import 'package:monet/models/account.dart';
import 'package:monet/models/transaction.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/resources/app_spacing.dart';
import 'package:monet/models/category.dart';
import 'package:monet/controller/category.dart';
import 'package:monet/controller/transaction.dart';
import 'package:monet/utils/helper.dart';
import 'package:monet/views/dashboard/frequency.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({Key? key, this.transaction}) : super(key: key);
  final TransactionModel? transaction;

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  TextEditingController amountController = TextEditingController(text: '0');
  CategoryModel? selectedCategory;
  TextEditingController descriptionController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  bool repeatTransaction = false;
  String? repeatFrequency;
  DateTime? repeatEndDate;
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
          title: const Text('Create New Other Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryNameController,
                decoration: const InputDecoration(
                  labelText: 'Other Category Name',
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
                    // Find the newly created category and select it
                    CategoryModel? newCat;
                    if (categories.isNotEmpty) {
                      newCat = categories.firstWhere(
                        (cat) => cat.name.toLowerCase() == categoryNameController.text.trim().toLowerCase(),
                        orElse: () => categories.last,
                      );
                    } else {
                      newCat = null;
                    }
                    setState(() {
                      selectedCategory = newCat;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Other category created and selected successfully")),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to create other category: "+(result.message??''))),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error creating other category: $e")),
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
                  Text('Select Other Category', style: AppStyles.medium(size: 18)),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search other categories',
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
                        'No other categories found',
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
                      'Other Category',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Green header section for expense (matching IncomeScreen style)
          Container(
            color: const Color(0xFFD32F2F), // Expense red
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
                          'Expense',
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
                                color: Color(0xFFD32F2F),
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
                        activeColor: const Color(0xFFD32F2F),
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                  if (repeatTransaction && repeatFrequency != null && repeatEndDate != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
                      child: Text(
                        'Repeats: $repeatFrequency until '
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
                    onPressed: isSaving ? null : _saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
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

