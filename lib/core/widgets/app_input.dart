import 'package:flutter/material.dart';

class AppInput extends StatelessWidget {
  const AppInput({
    required this.hint,
    this.controller,
    this.obscureText = false,
    super.key,
  });

  final String hint;
  final TextEditingController? controller;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
