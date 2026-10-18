import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import 'become_tutor_screen.dart';
import 'tutor_detail.dart';

/// Tutor directory (Phase 1: seeded demo tutors, browse-only).
/// Tutor registration, courses, and bookings arrive in Phase 3.
class TutorTab extends StatefulWidget {
  const TutorTab({super.key});

  @override
  State<TutorTab> createState() => _TutorTabState();
}

class _TutorTabState extends State<TutorTab> {
  final _search = TextEditingController();
  String _query = '';
  String? _subject;
  String? _level;
  String? _country;
  String? _language;
  String _pricing = 'all'; // all | free | paid
  double _minRating = 0;
  double _maxPrice = 20;
  String _sort = 'rating';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Tutor> _results(AppStore store) => store.findTutors(
        query: _query,
        subject: _subject,
        level: _level,
        country: _country,
        language: _language,
        freeOnly: _pricing == 'free',
        maxPrice: _pricing == 'paid' ? _maxPrice : null,
        minRating: _minRating,
        sort: _sort,
      );

  int get _activeFilterCount {
    var n = 0;
    if (_subject != null) n++;
    if (_level != null) n++;
    if (_country != null) n++;
    if (_language != null) n++;
    if (_pricing != 'all') n++;
    if (_minRating > 0) n++;
    return n;
  }

  void _clearFilters() {
    setState(() {
      _subject = null;
      _level = null;
      _country = null;
      _language = null;
      _pricing = 'all';
      _minRating = 0;
      _maxPrice = 20;
      _query = '';
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final results = _results(store);
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.tutorTitle),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: S.filters,
                onPressed: _openFilterSheet,
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: S.tutorSearchHint,
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: results.length + 2,
              itemBuilder: (context, i) {
                if (i == 0) return const _DemoTutorsNote();
                if (i == 1) return const _BecomeTutorCard();
                return _TutorCard(tutor: results[i - 2]);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TutorFilterSheet(
        subject: _subject,
        level: _level,
        country: _country,
        language: _language,
        pricing: _pricing,
        minRating: _minRating,
        maxPrice: _maxPrice,
        sort: _sort,
        onApply: (f) => setState(() {
          _subject = f.subject;
          _level = f.level;
          _country = f.country;
          _language = f.language;
          _pricing = f.pricing;
          _minRating = f.minRating;
          _maxPrice = f.maxPrice;
          _sort = f.sort;
        }),
        onClear: _clearFilters,
      ),
    );
  }
}

class _DemoTutorsNote extends StatelessWidget {
  const _DemoTutorsNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          DemoChip(),
          SizedBox(width: 10),
          Expanded(child: Text(S.demoTutorsNote)),
        ],
      ),
    );
  }
}

class _BecomeTutorCard extends StatelessWidget {
  const _BecomeTutorCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.school_outlined,
                color: scheme.onSecondaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.becomeTutorTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    S.becomeTutorBody,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const BecomeTutorScreen()),
              ),
              child: const Text(S.becomeTutorCta),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({required this.tutor});

  final Tutor tutor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => TutorDetailScreen(tutorId: tutor.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  UserAvatar(
                    name: tutor.name,
                    colorValue: tutor.colorValue,
                    radius: 28,
                  ),
                  if (tutor.onlineNow)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: scheme.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tutor.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        PriceTag(priceUsd: tutor.priceUsd),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        VerificationBadge(
                            status: tutor.verification, compact: true),
                        const SizedBox(width: 8),
                        StarsRow(rating: tutor.rating),
                        const SizedBox(width: 4),
                        Text(
                          '(${tutor.reviewCount})',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: scheme.onSurfaceVariant),
                        ),
                        if (tutor.onlineNow) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· ${S.tutorOnline}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tutor.intro,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tutor.subjects
                          .take(4)
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterValues {
  String? subject;
  String? level;
  String? country;
  String? language;
  String pricing = 'all';
  double minRating = 0;
  double maxPrice = 20;
  String sort = 'rating';
}

class _TutorFilterSheet extends StatefulWidget {
  const _TutorFilterSheet({
    required this.subject,
    required this.level,
    required this.country,
    required this.language,
    required this.pricing,
    required this.minRating,
    required this.maxPrice,
    required this.sort,
    required this.onApply,
    required this.onClear,
  });

  final String? subject;
  final String? level;
  final String? country;
  final String? language;
  final String pricing;
  final double minRating;
  final double maxPrice;
  final String sort;
  final ValueChanged<_FilterValues> onApply;
  final VoidCallback onClear;

  @override
  State<_TutorFilterSheet> createState() => _TutorFilterSheetState();
}

class _TutorFilterSheetState extends State<_TutorFilterSheet> {
  final f = _FilterValues();

  @override
  void initState() {
    super.initState();
    f.subject = widget.subject;
    f.level = widget.level;
    f.country = widget.country;
    f.language = widget.language;
    f.pricing = widget.pricing;
    f.minRating = widget.minRating;
    f.maxPrice = widget.maxPrice;
    f.sort = widget.sort;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final countries =
        store.tutors.map((t) => t.country).toSet().toList()..sort();
    final languages = store.tutors
        .expand((t) => t.languages)
        .toSet()
        .toList()
      ..sort();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.filters,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onClear();
                    Navigator.of(context).pop();
                  },
                  child: const Text(S.clearFilters),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LurniqDropdown<String>(
              label: S.tutorSubject,
              value: f.subject,
              hint: S.all,
              items: [
                const DropdownMenuItem(value: null, child: Text(S.all)),
                ...stringMenuItems(C.subjects),
              ],
              onChanged: (v) => setState(() => f.subject = v),
            ),
            const SizedBox(height: 12),
            LurniqDropdown<String>(
              label: S.tutorLevel,
              value: f.level,
              hint: S.all,
              items: [
                const DropdownMenuItem(value: null, child: Text(S.all)),
                ...stringMenuItems(C.educationLevels),
              ],
              onChanged: (v) => setState(() => f.level = v),
            ),
            const SizedBox(height: 12),
            LurniqDropdown<String>(
              label: S.tutorCountry,
              value: f.country,
              hint: S.all,
              items: [
                const DropdownMenuItem(value: null, child: Text(S.all)),
                ...stringMenuItems(countries),
              ],
              onChanged: (v) => setState(() => f.country = v),
            ),
            const SizedBox(height: 12),
            LurniqDropdown<String>(
              label: S.tutorLanguage,
              value: f.language,
              hint: S.all,
              items: [
                const DropdownMenuItem(value: null, child: Text(S.all)),
                ...stringMenuItems(languages),
              ],
              onChanged: (v) => setState(() => f.language = v),
            ),
            const SizedBox(height: 16),
            Text(S.tutorPricing,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text(S.all)),
                ButtonSegment(value: 'free', label: Text(S.free)),
                ButtonSegment(value: 'paid', label: Text(S.paid)),
              ],
              selected: {f.pricing},
              onSelectionChanged: (s) =>
                  setState(() => f.pricing = s.first),
            ),
            if (f.pricing == 'paid') ...[
              const SizedBox(height: 8),
              Text('${S.tutorMaxPrice}: \$${f.maxPrice.toStringAsFixed(0)}'),
              Slider(
                value: f.maxPrice,
                min: 5,
                max: 30,
                divisions: 5,
                label: '\$${f.maxPrice.toStringAsFixed(0)}',
                onChanged: (v) => setState(() => f.maxPrice = v),
              ),
            ],
            const SizedBox(height: 8),
            Text(
                '${S.tutorMinRating}: ${f.minRating == 0 ? S.all : f.minRating.toStringAsFixed(1)}+'),
            Slider(
              value: f.minRating,
              min: 0,
              max: 5,
              divisions: 10,
              onChanged: (v) => setState(() => f.minRating = v),
            ),
            const SizedBox(height: 8),
            LurniqDropdown<String>(
              label: S.sortBy,
              value: f.sort,
              items: const [
                DropdownMenuItem(
                    value: 'rating', child: Text(S.tutorSortRating)),
                DropdownMenuItem(
                    value: 'priceLow', child: Text(S.tutorSortPriceLow)),
                DropdownMenuItem(
                    value: 'priceHigh',
                    child: Text(S.tutorSortPriceHigh)),
                DropdownMenuItem(
                    value: 'name', child: Text(S.tutorSortName)),
              ],
              onChanged: (v) =>
                  setState(() => f.sort = v ?? 'rating'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onApply(f);
                  Navigator.of(context).pop();
                },
                child: const Text(S.apply),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
