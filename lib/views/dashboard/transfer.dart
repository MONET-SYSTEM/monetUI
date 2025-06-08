import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:monet/controller/account.dart';
import 'package:monet/controller/transfer.dart';
import 'package:monet/models/account.dart';
import 'package:monet/models/transaction.dart';
import 'package:monet/utils/helper.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({Key? key, this.transaction}) : super(key: key);
  final TransactionModel? transaction;

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String _displayAmount = '0';
  bool isLoading = false;
  List<AccountModel> accounts = [];
  AccountModel? sourceAccount;
  AccountModel? destinationAccount;
  bool useRealTimeRate = true;
  String selectedCurrencySymbol = '₱';
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    amountController.addListener(() {
      setState(() {
        _displayAmount = amountController.text.isEmpty ? '0' : amountController.text;
      });
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    setState(() => isLoading = true);

    try {
      final result = await AccountController.load();
      if (result.isSuccess && result.results != null) {
        setState(() {
          accounts = result.results!.where((account) => account.active == 1).toList();
          isLoading = false;

          if (accounts.isNotEmpty) {
            selectedCurrencySymbol = accounts.first.currency.symbol;
          }
        });
      } else {
        setState(() => isLoading = false);
        Helper.snackBar(context, message: result.message, isSuccess: false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      Helper.snackBar(context, message: "Failed to load accounts", isSuccess: false);
    }
  }

  void _handleTransfer() async {
    // Basic validation
    if (_displayAmount == '0' || amountController.text.isEmpty) {
      Helper.snackBar(context, message: 'Please enter an amount', isSuccess: false);
      return;
    }

    if (sourceAccount == null) {
      Helper.snackBar(context, message: 'Please select source account', isSuccess: false);
      return;
    }

    if (destinationAccount == null) {
      Helper.snackBar(context, message: 'Please select destination account', isSuccess: false);
      return;
    }

    if (sourceAccount!.id == destinationAccount!.id) {
      Helper.snackBar(context, message: 'Source and destination accounts cannot be the same', isSuccess: false);
      return;
    }

    double? sourceAmount;
    try {
      sourceAmount = double.parse(amountController.text.trim());
    } catch (e) {
      Helper.snackBar(context, message: 'Invalid amount format', isSuccess: false);
      return;
    }

    if (sourceAmount <= 0) {
      Helper.snackBar(context, message: 'Amount must be greater than zero', isSuccess: false);
      return;
    }

    if (sourceAccount!.currentBalance < sourceAmount) {
      Helper.snackBar(context, message: 'Insufficient balance in the source account', isSuccess: false);
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await TransferController.transferFunds(
        sourceAccountId: sourceAccount!.id,
        destinationAccountId: destinationAccount!.id,
        amount: sourceAmount,
        description: descriptionController.text.trim().isEmpty ?
        'Fund Transfer' : descriptionController.text.trim(),
        useRealTimeRate: useRealTimeRate,
        transactionDate: DateFormat('yyyy-MM-dd').format(selectedDate),
        isReconciled: false,
      );

      setState(() => isLoading = false);

      if (result.isSuccess) {
        Helper.snackBar(context, message: 'Transfer successful!', isSuccess: true);
        Navigator.of(context).pop(true);
      } else {
        String errorMessage = result.message;
        if (result.errors != null && result.errors!.isNotEmpty) {
          errorMessage = result.errors!.values.first.toString();
        }
        Helper.snackBar(context, message: errorMessage, isSuccess: false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      Helper.snackBar(context, message: 'An error occurred during transfer', isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Blue header section - Made more responsive
          Container(
            height: MediaQuery.of(context).size.height * 0.35, // Reduced from 0.4 to 0.35
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E88E5),
                  Color(0xFF1976D2),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // App bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Transfer',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Amount section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      children: [
                        const Text(
                          'How much?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              selectedCurrencySymbol,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),

          // White form section - Made scrollable with proper layout
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: isLoading ?
              const Center(child: CircularProgressIndicator()) :
              Column(
                children: [
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // From and To fields
                          Row(
                            children: [
                              Expanded(
                                child: _buildAccountSelector(
                                  label: 'From',
                                  account: sourceAccount,
                                  onTap: () => _showAccountSelector(context, true),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1976D2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.swap_horiz,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildAccountSelector(
                                  label: 'To',
                                  account: destinationAccount,
                                  onTap: () => _showAccountSelector(context, false),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Description field
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

                          const SizedBox(height: 24),

                          // Date picker
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
                            title: const Text('Transaction Date'),
                            subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(const Duration(days: 1)),
                              );
                              if (picked != null && picked != selectedDate) {
                                setState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                          ),

                          // Add some extra space at bottom for scrolling
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),

                  // Fixed bottom section with button and home indicator
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          offset: const Offset(0, -2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _handleTransfer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Home indicator
                        Container(
                          width: 134,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSelector({
    required String label,
    required AccountModel? account,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              account?.name ?? 'Select Account',
              style: TextStyle(
                color: account != null ? Colors.black : Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (account != null)
              Text(
                '${account.currency.symbol} ${account.currentBalance}',
                style: const TextStyle(
                  color: Color(0xFF1976D2),
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAccountSelector(BuildContext context, bool isSource) {
    if (accounts.isEmpty) {
      Helper.snackBar(context, message: "No accounts available", isSuccess: false);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSource ? 'Select Source Account' : 'Select Destination Account',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: accounts.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  if ((isSource && account.id == destinationAccount?.id) ||
                      (!isSource && account.id == sourceAccount?.id)) {
                    return const SizedBox.shrink();
                  }

                  return ListTile(
                    leading: Icon(
                      _getAccountTypeIcon(account.accountType.code),
                      color: const Color(0xFF1976D2),
                    ),
                    title: Text(account.name),
                    subtitle: Text(
                      '${account.currency.symbol} ${account.currentBalance}',
                      style: const TextStyle(
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        if (isSource) {
                          sourceAccount = account;
                          selectedCurrencySymbol = account.currency.symbol;
                        } else {
                          destinationAccount = account;
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAccountTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'bank':
        return Icons.account_balance;
      case 'credit-card':
      case 'credit_card':
        return Icons.credit_card;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }
}

