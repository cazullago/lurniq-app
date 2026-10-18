import 'package:flutter/material.dart';

import 'strings.dart';

/// Global option lists. Every list ends with an "Other" entry that opens a
/// free-text field — the user asked that no option list ever trap them.
class OptionLists {
  static const subjects = <String>[
    'Mathematics',
    'Science',
    'Biology',
    'Chemistry',
    'Physics',
    'English',
    'Languages',
    'History',
    'Geography',
    'Computer Science',
    'Business',
    'Arts',
    'Music',
    'Physical Education',
  ];

  static const educationLevels = <String>[
    'Elementary',
    'High School',
    'Senior High',
    'College',
    'Graduated',
  ];

  static const taskTypes = <String>[
    'Assignment',
    'Activity',
    'Project',
    'Quiz',
    'Exam',
    'Thesis',
    'Performance',
  ];

  static const priorities = <String>['Low', 'Medium', 'High'];

  static const taskStatuses = <String>['To do', 'Doing', 'Done'];

  static const countries = <String>[
    'Philippines',
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'India',
    'Indonesia',
    'Malaysia',
    'Singapore',
    'Japan',
    'South Korea',
    'United Arab Emirates',
    'Saudi Arabia',
    'Nigeria',
    'South Africa',
    'Brazil',
    'Mexico',
    'Germany',
    'France',
  ];

  static const languages = <String>[
    'English',
    'Filipino',
    'Spanish',
    'French',
    'German',
    'Portuguese',
    'Hindi',
    'Indonesian',
    'Malay',
    'Japanese',
    'Korean',
    'Chinese',
    'Arabic',
  ];

  static const currencies = <String>[
    'USD',
    'PHP',
    'EUR',
    'GBP',
    'CAD',
    'AUD',
    'JPY',
    'INR',
    'SGD',
    'AED',
  ];

  static const themeModes = <String>['System', 'Light', 'Dark'];
}

/// Bottom-sheet option picker with an "Other…" row that reveals a free-text
/// field. Returns the chosen value, or null if dismissed.
class OptionPicker {
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<String> options,
    String? current,
    String otherLabel = 'Other…',
    String otherHint = 'Type your own',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _OptionSheet(
        title: title,
        options: options,
        current: current,
        otherLabel: otherLabel,
        otherHint: otherHint,
      ),
    );
  }
}

class _OptionSheet extends StatefulWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    this.current,
    required this.otherLabel,
    required this.otherHint,
  });

  final String title;
  final List<String> options;
  final String? current;
  final String otherLabel;
  final String otherHint;

  @override
  State<_OptionSheet> createState() => _OptionSheetState();
}

class _OptionSheetState extends State<_OptionSheet> {
  final _otherCtrl = TextEditingController();
  bool _otherOpen = false;

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  bool _isCustom(String? v) =>
      v != null && v.isNotEmpty && !widget.options.contains(v);

  @override
  Widget build(BuildContext context) {
    final current = widget.current;
    final customSelected = _isCustom(current) && !_otherOpen;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...widget.options.map((o) => ListTile(
                        title: Text(o),
                        trailing: current == o
                            ? const Icon(Icons.check_rounded)
                            : null,
                        onTap: () => Navigator.of(context).pop(o),
                      )),
                  ListTile(
                    leading: const Icon(Icons.edit_rounded),
                    title: Text(widget.otherLabel),
                    subtitle: customSelected ? Text(current!) : null,
                    trailing:
                        customSelected ? const Icon(Icons.check_rounded) : null,
                    onTap: () {
                      if (customSelected) {
                        Navigator.of(context).pop(current);
                      } else {
                        setState(() {
                          _otherOpen = true;
                          if (_isCustom(current)) {
                            _otherCtrl.text = current!;
                          }
                        });
                      }
                    },
                  ),
                  if (_otherOpen) ...[
                    const SizedBox(height: 4),
                    TextField(
                      controller: _otherCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: widget.otherHint,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_rounded),
                          onPressed: () {
                            final v = _otherCtrl.text.trim();
                            if (v.isNotEmpty) {
                              Navigator.of(context).pop(v);
                            }
                          },
                        ),
                      ),
                      onSubmitted: (v) {
                        final t = v.trim();
                        if (t.isNotEmpty) Navigator.of(context).pop(t);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only label for a form field that opens [OptionPicker] on tap.
/// Scroll-safe: intrinsic height, no fixed row widths (the v1 task form
/// overflowed on real phone widths — see the "New task" screenshot).
class OptionField extends StatelessWidget {
  const OptionField({
    super.key,
    required this.label,
    required this.value,
    required this.title,
    required this.options,
    required this.onChanged,
    this.icon,
  });

  final String label;
  final String value;
  final String title;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            )),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final picked = await OptionPicker.show(
              context,
              title: title,
              options: options,
              current: value.isEmpty ? null : value,
            );
            if (picked != null) onChanged(picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon:
                  icon == null ? null : Icon(icon, size: 20),
              suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
            ),
            child: Text(
              value.isEmpty ? S.notSet : value,
              style: TextStyle(
                color: value.isEmpty
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
