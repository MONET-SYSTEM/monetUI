import 'package:flutter/material.dart';
import 'package:monet/controller/budget.dart';
import 'package:monet/controller/category.dart';
import 'package:monet/models/budget.dart';
import 'package:monet/models/category.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/services/budget_service.dart';
import 'package:monet/views/budget/create_budget.dart';
import 'package:monet/views/budget/show_budget.dart';
import 'package:monet/views/navigation/bottom_navigation.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<BudgetModel> _budgets = [];
  List<CategoryModel> categories = [];
  bool _isLoading = false;
  DateTime _currentMonth = DateTime.now();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _fetchBudgets();
  }

  Future<void> _loadCategories() async {
    final res = await CategoryController.load();
    if (res.isSuccess && res.results != null) {
      setState(() {
        categories = res.results!;
      });
    }
  }

  Future<void> _fetchBudgets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final local = await BudgetService.getAll();
      if (local.isNotEmpty) {
        _budgets = local;
      }
    } catch (_) {}
    final result = await BudgetController.fetchBudgets();
    if (result.isSuccess && result.results != null) {
      _budgets = result.results!;
    } else if (_budgets.isEmpty) {
      _errorMessage = result.message;
    }
    setState(() => _isLoading = false);
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

  String _getCategoryNameFromId(String? categoryId) {
    if (categoryId == null || categories.isEmpty) return 'Unknown Category';

    final cat = categories.firstWhere(
          (c) => c.id == categoryId,
    );
    return cat.name;
  }

  IconData _getCategoryIconFromId(String? categoryId) {
    if (categoryId == null || categories.isEmpty) return Icons.category;

    final cat = categories.firstWhere(
          (c) => c.id == categoryId,
    );
    return _getIconFromName(cat.icon);
  }

  Color? _parseColor(String hex) {
    try {
      var h = hex.replaceAll('#', '');
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse('0x$h'));
    } catch (_) {
      return AppColours.primaryColour;
    }
  }

  Widget _categoryPill(BudgetModel b) {
    final catName = b.categoryId == null
        ? 'Uncategorized'
        : (categories.firstWhere(
          (c) => c.id == b.categoryId,
    ).name);
    final icon = _getCategoryIconFromId(b.categoryId);
    final color = _parseColor(b.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(catName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat.MMMM().format(_currentMonth);

    return BottomNavigatorScreen(
      currentIndex: 3,
      onRefresh: _fetchBudgets,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppColours.primaryColour,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => setState(() {
              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
            }),
          ),
          title: Text(
            monthLabel,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColours.backgroundColor,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: () => setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
              }),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _fetchBudgets,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_errorMessage != null && _budgets.isEmpty)
              ? Center(child: Text(_errorMessage!))
              : _budgets.isEmpty
              ? _buildEmptyState()
              : _buildListView(),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateBudgetScreen()),
                );
                if (created == true) _fetchBudgets();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColours.primaryColour,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Create a budget', style: TextStyle(color: AppColours.backgroundColor, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(child: Text("You don't have any budgets yet", style: TextStyle(color: Colors.grey[600], fontSize: 16)));

  Widget _buildListView() {
    // Filter budgets for the selected month
    final filteredBudgets = _budgets.where((b) {
      if (b.startDate == null || b.endDate == null) return true;
      final start = DateTime(b.startDate!.year, b.startDate!.month);
      final end = DateTime(b.endDate!.year, b.endDate!.month);
      final current = DateTime(_currentMonth.year, _currentMonth.month);
      return (current.isAtSameMomentAs(start) || current.isAfter(start)) &&
             (current.isAtSameMomentAs(end) || current.isBefore(end));
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: filteredBudgets.length,
      itemBuilder: (_, i) {
        final b = filteredBudgets[i];
        final spent = b.spentAmount;
        final total = b.amount;
        final remaining = total - spent;
        final progress = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
        final color = _parseColor(b.color)!;

        return GestureDetector(
          onTap: () async {
            final updatedOrDeleted = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => ShowBudgetScreen(budget: b)),
            );
            if (updatedOrDeleted == true) _fetchBudgets();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _categoryPill(b),
                    if (remaining < 0) const Icon(Icons.error_outline, color: Color(0xFFEB5757)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Remaining', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('₱${remaining.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(remaining < 0 ? Colors.red : color),
                  ),
                ),
                const SizedBox(height: 8),
                Text('₱${spent.toStringAsFixed(0)} of ₱${total.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                if (remaining < 0) const Text("You've exceeded the limit!", style: TextStyle(color: Color(0xFFEB5757), fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }
}
