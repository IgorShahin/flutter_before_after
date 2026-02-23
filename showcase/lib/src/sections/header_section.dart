import 'package:flutter/material.dart';

import '../platform/demo_platform_profile.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key, required this.profile, required this.isWide});

  final DemoPlatformProfile profile;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF19315A)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A0C172A),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge('before_after_slider'),
              _badge(profile.platformBadge),
              if (isWide) _badge('Interactive demo'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Before/After Showcase',
            style: (isWide
                    ? theme.textTheme.headlineMedium
                    : theme.textTheme.headlineSmall)
                ?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A clean playground focused on real usage: compare, drag, zoom, and tune behavior live.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFC5D4EC),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x55FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFE6EEF9),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
