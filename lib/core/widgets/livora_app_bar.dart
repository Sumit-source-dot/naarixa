import 'package:flutter/material.dart';

class LivoraAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LivoraAppBar({required this.title, this.actions, super.key});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}