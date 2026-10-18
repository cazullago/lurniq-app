import 'package:flutter/material.dart';

import '../../core/strings.dart';
import 'compose_group_screen.dart';
import 'compose_post_screen.dart';
import 'compose_resource_screen.dart';

/// The Add Post tab: three creation options.
class ComposeTab extends StatelessWidget {
  const ComposeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.addPostTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            S.addPostSubtitle,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _OptionCard(
            icon: Icons.edit_note_rounded,
            title: S.optionGeneralPost,
            description: S.optionGeneralPostDesc,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      const ComposePostScreen()),
            ),
          ),
          _OptionCard(
            icon: Icons.group_add_outlined,
            title: S.optionStudyGroup,
            description: S.optionStudyGroupDesc,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      const ComposeGroupScreen()),
            ),
          ),
          _OptionCard(
            icon: Icons.folder_shared_outlined,
            title: S.optionResource,
            description: S.optionResourceDesc,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      const ComposeResourceScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon,
                    size: 30, color: scheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
