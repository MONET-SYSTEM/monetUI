import 'package:flutter/material.dart';
import 'package:monet/controller/budget.dart';
import 'package:monet/models/budget.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/views/budget/create_budget.dart';

class ShowBudgetScreen extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback? onDeleted;

  const ShowBudgetScreen({
    Key? key,
    required this.budget,
    this.onDeleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Compute some derived values
    final spent = budget.spentAmount;
    final total = budget.amount;
    final remaining = total - spent;
    final progress = total > 0
        ? (spent / total).clamp(0.0, 1.0)
        : 0.0;

    // Widgets
    Widget backButton = IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black87),
      onPressed: () => Navigator.of(context).pop(),
    );

    Widget deleteButton = IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.black87),
      onPressed: () async {
        // ask for confirmation
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
          onDeleted?.call();
          Navigator.of(context).pop();
        }
      },
    );

    Widget categoryPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColours.primaryColour.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            // replace with your category icon logic
            Icons.shopping_bag,
            color: AppColours.primaryColour,
          ),
          const SizedBox(width: 6),
          Text(
            budget.name.isNotEmpty ? budget.name : 'Uncategorized',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    Widget remainingLabel = const Text(
      'Remaining',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );

    Widget remainingAmount = Text(
      '₱${remaining.toStringAsFixed(0)}',
      style: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );

    Widget progressBar = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 8,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(
          progress > 1.0
              ? Colors.red
              : AppColours.primaryColour,
        ),
      ),
    );

    Widget warningPill = Visibility(
      visible: remaining < 0,
      child: Container(
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFEB5757),
              ),
            ),
          ],
        ),
      ),
    );

    Widget editButton = SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to your edit form
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateBudgetScreen(
                // TODO: pass initialBudget so the form is in edit mode
                initialBudget: budget,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColours.primaryColour,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Edit',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: backButton,
        actions: [deleteButton],
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
            categoryPill,
            const SizedBox(height: 32),
            remainingLabel,
            const SizedBox(height: 8),
            remainingAmount,
            const SizedBox(height: 24),
            progressBar,
            warningPill,
            const Spacer(),
            editButton,
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
