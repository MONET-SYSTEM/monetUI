import 'package:flutter/material.dart';
import 'package:monet/controller/budget.dart';
import 'package:monet/models/budget.dart';
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
  bool _isLoading = false;
  DateTime _currentMonth = DateTime.now();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBudgets();
  }

  Future<void> _fetchBudgets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // load local
    try {
      final local = await BudgetService.getAll();
      if (local.isNotEmpty) {
        setState(() => _budgets = local);
      }
    } catch (_) {}

    // then remote
    final result = await BudgetController.fetchBudgets();
    if (result.isSuccess && result.results != null) {
      setState(() => _budgets = result.results!);
    } else if (_budgets.isEmpty) {
      setState(() => _errorMessage = result.message);
    }

    setState(() => _isLoading = false);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  List<BudgetModel> get _filteredBudgets {
    // if you track budgets by month, filter here.
    // For now just show all.
    return _budgets;
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
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _prevMonth,
          ),
          title: Text(
            monthLabel,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: _nextMonth,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _fetchBudgets,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null && _filteredBudgets.isEmpty
              ? Center(child: Text(_errorMessage!))
              : _filteredBudgets.isEmpty
              ? _buildEmptyState()
              : _buildListView(),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _onCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColours.primaryColour,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Create a budget',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "You don't have any budgets yet",
        style: TextStyle(color: Colors.grey[600], fontSize: 16),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: _filteredBudgets.length,
      itemBuilder: (_, i) => _buildCard(_filteredBudgets[i]),
    );
  }

  Widget _buildCard(BudgetModel b) {
    final spent = b.spentAmount;
    final total = b.amount;
    final remaining = total - spent;
    final progress = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
    final color = _parseColor(b.color) ?? AppColours.primaryColour;

    return GestureDetector(
      onTap: () async {
        final deleted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => ShowBudgetScreen(budget: b)),
        );
        if (deleted == true) _fetchBudgets();
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
            // pill + warning icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _categoryPill(b, color),
                if (remaining < 0)
                  const Icon(Icons.error_outline, color: Color(0xFFEB5757)),
              ],
            ),
            const SizedBox(height: 12),
            // Remaining label & amount
            const Text('Remaining', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              '₱${remaining.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 1.0 ? Colors.red : color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // spent/total and warning text
            Text(
              '₱${spent.toStringAsFixed(0)} of ₱${total.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            if (remaining < 0) ...[
              const SizedBox(height: 4),
              const Text(
                "You've exceeded the limit!",
                style: TextStyle(color: Color(0xFFEB5757), fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _categoryPill(BudgetModel b, Color color) {
    final name = b.name.isNotEmpty ? b.name : 'Uncategorized';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(_getCategoryIcon(name), size: 16, color: color),
          const SizedBox(width: 6),
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _onCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateBudgetScreen()),
    );
    if (created == true) _fetchBudgets();
  }

  IconData _getCategoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('food')) return Icons.restaurant;
    if (n.contains('transport')) return Icons.directions_car;
    if (n.contains('shopping')) return Icons.shopping_bag;
    if (n.contains('health')) return Icons.favorite;
    if (n.contains('education')) return Icons.school;
    if (n.contains('bill')) return Icons.receipt;
    if (n.contains('entertainment')) return Icons.movie;
    return Icons.account_balance_wallet;
  }

  Color? _parseColor(String hex) {
    try {
      var h = hex.replaceAll('#', '');
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse('0x$h'));
    } catch (_) {
      return null;
    }
  }
}
