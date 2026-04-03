import 'package:flutter/material.dart';

class ProfileOptionTile extends StatelessWidget {
  const ProfileOptionTile({
    required this.title,
    required this.icon,
    this.onTap,
    this.backgroundColor,
    super.key,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedBackground = backgroundColor == null
        ? null
        : Theme.of(context).brightness == Brightness.dark
            ? Color.alphaBlend(
                backgroundColor!.withOpacity(0.25),
                colorScheme.surface,
              )
            : backgroundColor;
    return Card(
      color: resolvedBackground,
      child: ListTile(
        leading: Icon(icon, color: colorScheme.onSurface),
        title: Text(title, style: TextStyle(color: colorScheme.onSurface)),
        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}