import 'package:flutter/material.dart';

class RenterSearchBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onFilterTap;
  final String hintText;

  const RenterSearchBar({
    super.key,
    this.onChanged,
    this.controller,
    this.onFilterTap,
    this.hintText = 'Search location, area or property...',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shadowColor = Theme.of(context).shadowColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: colorScheme.onSurfaceVariant, size: 20),
                  hintText: hintText,
                  hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onFilterTap,
                child: Icon(Icons.tune_rounded, color: colorScheme.onPrimary, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
