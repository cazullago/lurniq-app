import 'dart:io';

import 'package:flutter/material.dart';

import '../core/strings.dart';

/// Small "DEMO" badge for seeded sample content.
class DemoChip extends StatelessWidget {
  const DemoChip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        S.demoBadge,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: scheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, size: 44, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (action case final Widget a) a,
        ],
      ),
    );
  }
}

/// Avatar: photo when available, otherwise colored initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarPath,
    this.colorValue,
    this.radius = 20,
  });

  final String name;
  final String? avatarPath;
  final int? colorValue;
  final double radius;

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final file = avatarPath;
    if (file != null && file.isNotEmpty && File(file).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(file)),
      );
    }
    final color = colorValue != null
        ? Color(colorValue!)
        : scheme.primary;
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.16),
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}

class StarsRow extends StatelessWidget {
  const StarsRow({super.key, required this.rating, this.size = 14});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 2, color: Colors.amber[700]),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: size,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Price label: "Free" or "$12/hr". Prices are stored in USD (the internal
/// currency); live conversion arrives with payments in Phase 4.
class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.priceUsd, this.perHour = true});

  final double priceUsd;
  final bool perHour;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFree = priceUsd <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isFree
            ? scheme.secondaryContainer
            : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isFree
            ? S.free
            : '\$${priceUsd.toStringAsFixed(priceUsd.truncateToDouble() == priceUsd ? 0 : 2)}${perHour ? S.perHour : ''}',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: isFree
              ? scheme.onSecondaryContainer
              : scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class TagChips extends StatelessWidget {
  const TagChips({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags
          .take(6)
          .map(
            (t) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '#$t',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Maps folder icon keys to Material icons.
IconData folderIconFor(String key) {
  switch (key) {
    case 'flask':
      return Icons.science_outlined;
    case 'language':
      return Icons.translate_outlined;
    case 'history':
      return Icons.history_edu_outlined;
    case 'code':
      return Icons.code_outlined;
    case 'chart':
      return Icons.calculate_outlined;
    case 'palette':
      return Icons.palette_outlined;
    case 'globe':
      return Icons.public_outlined;
    case 'star':
      return Icons.star_outline_rounded;
    case 'book':
      return Icons.menu_book_outlined;
    case 'folder':
    default:
      return Icons.folder_outlined;
  }
}

/// Dropdown field with the app's rounded styling.
class LurniqDropdown<T> extends StatelessWidget {
  const LurniqDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

List<DropdownMenuItem<String>> stringMenuItems(List<String> values) =>
    values
        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
        .toList();

/// Verification badge with honest labeling.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.status, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final String label;
    late final IconData icon;
    late final Color color;
    switch (status) {
      case 'id':
        label = S.verificationId;
        icon = Icons.badge_outlined;
        color = scheme.secondary;
      case 'credential':
        label = S.verificationCredential;
        icon = Icons.verified_outlined;
        color = scheme.secondary;
      case 'unverified':
      default:
        label = S.verificationUnverified;
        icon = Icons.help_outline_rounded;
        color = scheme.onSurfaceVariant;
    }
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
