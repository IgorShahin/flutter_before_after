import 'package:flutter/material.dart';

class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD6E2F9)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334A6B),
            ),
      ),
    );
  }
}
