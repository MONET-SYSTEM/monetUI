import 'package:flutter/material.dart';
import 'package:monet/controller/account.dart';
import 'package:monet/models/account.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/resources/app_spacing.dart';
import 'package:monet/models/category.dart';
import 'package:monet/controller/category.dart';
import 'package:monet/controller/transaction.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
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
  bool isSaving = false; // Separate loading state for saving
  List<CategoryModel> categories = [];
  List<CategoryModel> filteredCategories = [];
  List<AccountModel> accounts = [];
  AccountModel? selectedAccount;
  String selectedCurrencySymbol = '\$';
  File? selectedFile;
  String? selectedFileName;
  String? selectedFileMimeType;

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load accounts: ${result.message}")),
          );
        }
      }
    } catch (e) {
      print("Error loading accounts: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading accounts: $e")),
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

  String _getMimeType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _pickFile() async {
    try {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select attachment source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImageFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImageFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.file_present),
                  title: const Text('Document or Other File'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickDocument();
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print("Error in file picker dialog: $e");
      if (context.mounted) {
        Helper.snackBar(context, message: "Error opening file picker: $e", isSuccess: false);
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        final file = File(image.path);
        if (await file.exists()) {
          final fileSize = await file.length();
          if (fileSize > 10 * 1024 * 1024) {
            if (context.mounted) {
              Helper.snackBar(context, message: "File size exceeds 10MB limit", isSuccess: false);
            }
            return;
          }

          setState(() {
            selectedFile = file;
            selectedFileName = image.name;
            selectedFileMimeType = _getMimeType(image.name);
          });

          if (context.mounted) {
            Helper.snackBar(context, message: "Photo selected: ${image.name}", isSuccess: true);
          }
        } else {
          if (context.mounted) {
            Helper.snackBar(context, message: "Selected file is not accessible", isSuccess: false);
          }
        }
      }
    } catch (e) {
      print("Error picking image from gallery: $e");
      if (context.mounted) {
        Helper.snackBar(context, message: "Error selecting photo: $e", isSuccess: false);
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo != null) {
        final file = File(photo.path);
        if (await file.exists()) {
          final fileSize = await file.length();
          if (fileSize > 10 * 1024 * 1024) {
            if (context.mounted) {
              Helper.snackBar(context, message: "File size exceeds 10MB limit", isSuccess: false);
            }
            return;
          }

          final fileName = "photo_${DateTime.now().millisecondsSinceEpoch}.jpg";
          setState(() {
            selectedFile = file;
            selectedFileName = fileName;
            selectedFileMimeType = 'image/jpeg';
          });

          if (context.mounted) {
            Helper.snackBar(context, message: "Photo captured successfully", isSuccess: true);
          }
        } else {
          if (context.mounted) {
            Helper.snackBar(context, message: "Captured photo is not accessible", isSuccess: false);
          }
        }
      }
    } catch (e) {
      print("Error capturing photo: $e");
      if (context.mounted) {
        Helper.snackBar(context, message: "Error capturing photo: $e", isSuccess: false);
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'csv', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;

        if (platformFile.path != null) {
          final file = File(platformFile.path!);

          if (await file.exists()) {
            final fileSize = await file.length();
            if (fileSize > 10 * 1024 * 1024) {
              if (context.mounted) {
                Helper.snackBar(context, message: "File size exceeds 10MB limit", isSuccess: false);
              }
              return;
            }

            setState(() {
              selectedFile = file;
              selectedFileName = platformFile.name;
              selectedFileMimeType = _getMimeType(platformFile.name);
            });

            if (context.mounted) {
              Helper.snackBar(context, message: "File selected: ${platformFile.name}", isSuccess: true);
            }
          } else {
            if (context.mounted) {
              Helper.snackBar(context, message: "Selected file is not accessible", isSuccess: false);
            }
          }
        } else {
          if (context.mounted) {
            Helper.snackBar(context, message: "Could not access file path", isSuccess: false);
          }
        }
      }
    } catch (e) {
      print("Error picking document: $e");
      if (context.mounted) {
        Helper.snackBar(context, message: "Error selecting document: $e", isSuccess: false);
      }
    }
  }

  void _removeFile() {
    setState(() {
      selectedFile = null;
      selectedFileName = null;
      selectedFileMimeType = null;
    });
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
                    icon: iconNameController.text.trim().isNotEmpty ? iconNameController.text.trim() : null,
                  );

                  if (result.isSuccess && result.results != null) {
                    setState(() {
                      CategoryModel newCategory = result.results;
                      categories.add(newCategory);
                      filteredCategories = List.from(categories);
                      selectedCategory = newCategory;
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Category '${categoryNameController.text}' created successfully")),
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
                              color: AppColours.primaryColour.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getCategoryIcon(category.icon),
                              color: AppColours.primaryColour,
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
                      backgroundColor: AppColours.primaryColour,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Other Category',
                      style: TextStyle(color: Colors.white),
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fixed _saveExpense method with better transaction handling
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

      // Validate file if selected (but don't fail if no file)
      if (selectedFile != null) {
        if (!await selectedFile!.exists()) {
          Helper.snackBar(context, message: "Selected file is no longer accessible", isSuccess: false);
          setState(() {
            isSaving = false;
          });
          return;
        }

        final fileSize = await selectedFile!.length();
        if (fileSize > 10 * 1024 * 1024) {
          Helper.snackBar(context, message: "File size exceeds 10MB limit", isSuccess: false);
          setState(() {
            isSaving = false;
          });
          return;
        }

        print("File validation passed:");
        print("- File path: ${selectedFile!.path}");
        print("- File name: $selectedFileName");
        print("- File size: ${fileSize} bytes");
        print("- MIME type: $selectedFileMimeType");
      }

      print("Saving transaction with parameters:");
      print("- Account ID: ${selectedAccount!.id}");
      print("- Type: expense");
      print("- Amount: $amount");
      print("- Category ID: ${selectedCategory!.id}");
      print("- Description: ${descriptionController.text}");
      print("- Date: $fullTimestamp");
      print("- Has attachment: ${selectedFile != null}");

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

      print("Transaction save result:");
      print("- Success: ${result.isSuccess}");
      print("- Message: ${result.message}");
      print("- Transaction ID: ${result.results?.id}");

      if (result.isSuccess && result.results != null) {
        final transactionId = result.results!.id;
        print("Transaction saved successfully with ID: $transactionId");

        // Handle attachment upload separately if we have one
        if (selectedFile != null && transactionId != null) {
          print("Starting attachment upload for transaction: $transactionId");

          try {
            final attachResult = await TransactionController.uploadAttachment(
              transactionId: transactionId,
              file: selectedFile!,
              description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
            );

            print("Attachment upload result:");
            print("- Success: ${attachResult.isSuccess}");
            print("- Message: ${attachResult.message}");
            print("- Errors: ${attachResult.errors}");

            if (attachResult.isSuccess) {
              if (mounted) {
                Helper.snackBar(context, message: "Transaction and attachment saved successfully!", isSuccess: true);
              }
            } else {
              // Transaction saved but attachment failed - this is still a partial success
              String attachError = attachResult.message ?? "Unknown attachment error";
              if (attachResult.errors != null) {
                if (attachResult.errors is Map) {
                  attachResult.errors?.forEach((key, value) {
                    attachError += "\n• $key: ${value is List ? value.join(', ') : value}";
                  });
                } else {
                  attachError += "\n• ${attachResult.errors}";
                }
              }

              print("Attachment upload failed but transaction was saved: $attachError");
              if (mounted) {
                Helper.snackBar(
                    context,
                    message: "Transaction saved successfully, but attachment upload failed: $attachError",
                    isSuccess: false
                );
              }
            }
          } catch (attachError) {
            print("Attachment upload exception: $attachError");
            if (mounted) {
              Helper.snackBar(
                  context,
                  message: "Transaction saved successfully, but attachment upload failed: $attachError",
                  isSuccess: false
              );
            }
          }
        } else {
          // No attachment, just show success
          if (mounted) {
            Helper.snackBar(context, message: result.message ?? "Expense saved successfully", isSuccess: true);
          }
        }

        // Navigate back on success
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        // Transaction save failed
        String errorMsg = result.message ?? "Failed to save expense";
        print("Transaction save failed: $errorMsg");

        if (result.errors != null) {
          print("Transaction validation errors: ${result.errors}");
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
                              style: TextStyle(
                                color: AppColours.primaryColour,
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

                  // Attachment - Updated to work with XFile
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Icon(
                          selectedFile != null ? Icons.attach_file : Icons.attach_file_outlined,
                          color: selectedFile != null ? AppColours.primaryColour : Colors.grey.shade500
                      ),
                      title: Text(
                        selectedFile != null ? selectedFileName! : 'Add attachment',
                        style: TextStyle(
                          fontSize: 16,
                          color: selectedFile != null ? Colors.black87 : Colors.grey.shade500,
                        ),
                      ),
                      trailing: selectedFile != null
                          ? IconButton(
                        icon: Icon(Icons.close, color: Colors.grey.shade500),
                        onPressed: _removeFile,
                      )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      onTap: selectedFile != null ? null : _pickFile,
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
                        onChanged: (v) => setState(() => repeatTransaction = v),
                        activeColor: AppColours.primaryColour,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                    onPressed: _saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColours.primaryColour,
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
