// lib/views/budget/create_budget.dart

import 'package:flutter/material.dart';
import 'package:monet/controller/budget.dart';
import 'package:monet/controller/category.dart';
import 'package:monet/models/budget.dart';
import 'package:monet/models/category.dart';
import 'package:monet/models/result.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/views/navigation/bottom_navigation.dart';

class CreateBudgetScreen extends StatefulWidget {
  final BudgetModel? initialBudget;

  const CreateBudgetScreen({Key? key, this.initialBudget}) : super(key: key);

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();

  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;

  String _selectedPeriod = 'monthly';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _sendNotifications = true;
  int _notificationThreshold = 80;

  bool _isLoading = false;
  String? _errorMessage;

  final _periodOptions = ['daily','weekly','monthly','quarterly','yearly'];

  @override
  void initState() {
    super.initState();
    _loadCategories();

    // If we're editing, prefill the fields:
    final b = widget.initialBudget;
    if (b != null) {
      _amountCtrl.text = b.amount.toStringAsFixed(2);
      _descriptionCtrl.text = b.description ?? '';
      _nameCtrl.text = b.name;
      _selectedPeriod = b.period;
      _startDate = b.startDate;
      _endDate = b.endDate;
      _sendNotifications = b.sendNotifications;
      _notificationThreshold = b.notificationThreshold;
      _selectedCategoryId = b.categoryId;
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await CategoryController.load();
      if (res.isSuccess && res.results != null) {
        final expenses = res.results!.where((c) => c.type == 'expense').toList();
        setState(() {
          _categories = expenses;
          // if no initial and categories exist, select first
          if (_selectedCategoryId == null && expenses.isNotEmpty) {
            _selectedCategoryId = expenses.first.id;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate({ required bool isStart }) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? (_startDate ?? DateTime.now()));
    final first = isStart ? DateTime(2000) : (_startDate ?? DateTime(2000));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    final amtText = _amountCtrl.text.trim();
    if (amtText.isEmpty) {
      setState(() => _errorMessage = 'Please enter an amount.');
      return;
    }
    final amount = double.tryParse(amtText);
    if (amount == null) {
      setState(() => _errorMessage = 'Invalid amount format.');
      return;
    }
    if (_startDate == null || _endDate == null) {
      setState(() => _errorMessage = 'Please pick both start and end dates.');
      return;
    }
    if (_selectedCategoryId == null) {
      setState(() => _errorMessage = 'Please select a category.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : 'Budget';
    final description = _descriptionCtrl.text.trim().isNotEmpty
        ? _descriptionCtrl.text.trim()
        : null;

    Result result;
    if (widget.initialBudget == null) {
      // creating
      result = await BudgetController.createBudget(
        name: name,
        description: description,
        amount: amount,
        categoryId: _selectedCategoryId,
        period: _selectedPeriod,
        startDate: _startDate!,
        endDate: _endDate!,
        sendNotifications: _sendNotifications,
        notificationThreshold: _notificationThreshold,
      );
    } else {
      // updating
      result = await BudgetController.updateBudget(
        budgetId: widget.initialBudget!.id,
        name: name,
        description: description,
        amount: amount,
        categoryId: _selectedCategoryId,
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
        sendNotifications: _sendNotifications,
        notificationThreshold: _notificationThreshold,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      // After creating/editing, pop and signal success to refresh BudgetScreen
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = result.message ?? 'Failed to save budget.');
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialBudget != null;
    return BottomNavigatorScreen(
      currentIndex: 3,
      onRefresh: () {},
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [ Color(0xFF2196F3), Color(0xFF1976D2) ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        BackButton(color: Colors.white),
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit Budget' : 'Create Budget',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildForm(),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading) ModalBarrier(dismissible: false, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ),
        const Text('Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. Groceries, Rent, ...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountCtrl,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '₱ ',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Description (optional)', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. Groceries, Rent, ...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Category', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        const Text('Period', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPeriod,
          items: _periodOptions.map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
          onChanged: (v) => setState(() => _selectedPeriod = v!),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => _pickDate(isStart: true), child: Text(
            _startDate == null
                ? 'Pick start date'
                : 'Start: ${_startDate!.toLocal().toIso8601String().split('T')[0]}',
          ))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton(onPressed: () => _pickDate(isStart: false), child: Text(
            _endDate == null
                ? 'Pick end date'
                : 'End: ${_endDate!.toLocal().toIso8601String().split('T')[0]}',
          ))),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Receive Alert', style: TextStyle(fontSize: 16)),
          Switch(
            value: _sendNotifications,
            onChanged: (v) => setState(() => _sendNotifications = v),
            activeColor: AppColours.primaryColour,
          ),
        ]),
        if (_sendNotifications) ...[
          Text('Notify at $_notificationThreshold%'),
          Slider(
            value: _notificationThreshold.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            label: '$_notificationThreshold%',
            onChanged: (v) => setState(() => _notificationThreshold = v.toInt()),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColours.primaryColour,
              foregroundColor: AppColours.primaryColour,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              widget.initialBudget == null ? 'Continue' : 'Save Changes',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
