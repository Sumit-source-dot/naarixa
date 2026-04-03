import 'package:flutter/material.dart';

class RenterBudgetBanner extends StatelessWidget {
  const RenterBudgetBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 380;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8703A).withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Your Budget',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Filter properties that fit your monthly budget range.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _BudgetChip(label: '< INR 8K'),
                    _BudgetChip(label: 'INR 8K-15K', selected: true),
                    _BudgetChip(label: 'INR 15K+'),
                  ],
                ),
              ],
            ),
          ),
          if (!narrow) ...[
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8703A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _BudgetChip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE8703A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: selected ? null : Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
    );
  }
}
