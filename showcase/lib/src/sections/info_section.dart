import 'package:flutter/material.dart';

import '../platform/demo_platform_profile.dart';
import '../widgets/stat_pill.dart';

class InfoSection extends StatelessWidget {
  const InfoSection({super.key, required this.profile});

  final DemoPlatformProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE5F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What this demo proves',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const StatPill(text: 'Any widget as before/after'),
              const StatPill(text: 'Horizontal + vertical slider'),
              const StatPill(text: 'High precision drag hit zone'),
              if (profile.isMobile) const StatPill(text: 'Pinch + pan'),
              if (!profile.isMobile)
                StatPill(text: '${profile.modifierLabel} + wheel zoom'),
              const StatPill(text: 'Container scale effect'),
            ],
          ),
        ],
      ),
    );
  }
}
