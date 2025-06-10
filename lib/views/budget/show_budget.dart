import 'package:flutter/material.dart';
import 'package:monet/controller/budget.dart';
import 'package:monet/models/budget.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/views/budget/create_budget.dart';

class ShowBudgetScreen extends StatelessWidget {
  final BudgetModel budget;
  const ShowBudgetScreen({Key? key, required this.budget}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spent = budget.spentAmount;
    final total = budget.amount;
    final remaining = total - spent;
    final progress = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;

    Color pillColor = AppColours.primaryColour;
    if (budget.categoryColour != null) {
      // parse hex, default to primary on failure
      try {
        var hex = budget.categoryColour!.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        pillColor = Color(int.parse('0x$hex'));
      } catch (_) {}
    }

    Widget categoryPill() {
      final text = budget.categoryName ?? 'Uncategorized';
      IconData icon;
      // if you provided an icon name, you could map it properly; fallback:
      switch (budget.categoryIcon) {
        case 'shopping':
          icon = Icons.shopping_bag;
          break;
        case 'food':
          icon = Icons.restaurant;
          break;
        case 'transport':
          icon = Icons.directions_car;
          break;
        default:
          icon = Icons.category;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: pillColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: pillColor),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    Future<void> _delete() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete Budget?'),
          content: Text('Are you sure you want to delete "${budget.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        ),
      );
      if (confirm == true) {
        final result = await BudgetController.deleteBudget(budget.id);
        if (result.isSuccess) {
          Navigator.of(context).pop(true); // Pass true to indicate deletion
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Failed to delete.')),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.black87),
            onPressed: _delete,
          ),
        ],
        centerTitle: true,
        title: const Text(
          'Detail Budget',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            categoryPill(),
            const SizedBox(height: 32),
            const Text(
              'Remaining',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              '₱${remaining.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 1.0 ? Colors.red : pillColor,
                ),
              ),
            ),
            if (remaining < 0)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.error_outline, color: Color(0xFFEB5757), size: 20),
                    SizedBox(width: 6),
                    Text(
                      "You've exceeded the limit",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFEB5757)),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => CreateBudgetScreen(initialBudget: budget),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColours.primaryColour,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
