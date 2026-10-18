import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../services/notify_service.dart';
import '../../store/app_store.dart';
import '../../widgets/tappable_name.dart';
import '../../widgets/ui.dart';
import 'become_tutor_screen.dart';
import 'bookings_screen.dart';
import 'course_detail_screen.dart';
import 'course_form_screen.dart';
import 'live_room_screen.dart';
import 'live_session_form_screen.dart';
import 'tutor_detail.dart';

/// Tutor tab (v2): three segmented sections — Tutors | Courses | Live.
///
/// Tutors keeps the directory UI (search/filters/sort) plus an
/// Everyone / My-country-only filter. Courses lists tutor courses with
/// enrollment + progress; Live lists public sessions with quizzes.
/// "My sessions" (1v1 bookings) opens from the AppBar action.
class TutorTab extends StatefulWidget {
  const TutorTab({super.key});

  @override
  State<TutorTab> createState() => _TutorTabState();
}

class _TutorTabState extends State<TutorTab> {
  int _segment = 0;
  static bool _notifAsked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAskNotifications();
    });
  }

  /// First open of the Tutor tab: explain, then ask for the notification
  /// permission (on-device demo reminders only).
  Future<void> _maybeAskNotifications() async {
    if (_notifAsked || !mounted) return;
    _notifAsked = true;
    final allow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Session reminders'),
        content: const Text(
          'Lurniq can send on-device reminders: 15 minutes before a '
          '1v1 session starts, plus alerts when you enroll in a course '
          'or send a booking request.\n\nDemo mode — notifications '
          'stay on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    if (allow != true || !mounted) return;
    final granted = await NotifyService.instance.requestPermission();
    if (!granted && mounted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reminders are off'),
          content: const Text(S.permissionDenied),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(S.close),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(S.openSettings),
            ),
          ],
        ),
      );
      if (open == true) await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.tutorTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note_outlined),
            tooltip: S.myBookings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const BookingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.person_search_outlined),
                  label: Text('Tutors'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.school_outlined),
                  label: Text(S.courses),
                ),
                ButtonSegment(
                  value: 2,
                  icon: Icon(Icons.live_tv_outlined),
                  label: Text(S.live),
                ),
              ],
              selected: {_segment},
              onSelectionChanged: (s) =>
                  setState(() => _segment = s.first),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _segment,
              children: const [
                _TutorsPage(),
                _CoursesPage(),
                _LivePage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tutors ───────────────────────────────────────────────

class _TutorsPage extends StatefulWidget {
  const _TutorsPage();

  @override
  State<_TutorsPage> createState() => _TutorsPageState();
}

class _TutorsPageState extends State<_TutorsPage> {
  final _search = TextEditingController();
  String _query = '';
  String? _subject;
  String? _level;
  String? _language;
  String _pricing = 'all'; // all | free | paid
  double _minRating = 0;
  double _maxPrice = 20;
  String _sort = 'rating';
  String _countryScope = 'all'; // all | mine

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String? _effectiveCountry(AppStore store) {
    if (_countryScope != 'mine') return null;
    final c = store.currentUser?.country.trim() ?? '';
    return c.isEmpty ? null : c;
  }

  List<Tutor> _results(AppStore store) => store.findTutors(
        query: _query,
        subject: _subject,
        level: _level,
        country: _effectiveCountry(store),
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
    if (_language != null) n++;
    if (_pricing != 'all') n++;
    if (_minRating > 0) n++;
    return n;
  }

  void _clearFilters() {
    setState(() {
      _subject = null;
      _level = null;
      _language = null;
      _pricing = 'all';
      _minRating = 0;
      _maxPrice = 20;
      _query = '';
      _search.clear();
    });
  }

  void _promptSetCountry() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.myCountryOnly),
        content: const Text(
          'Set your country in your profile first: open the Profile '
          'tab, edit your profile, and pick your country. Then come '
          'back to see tutors from home.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(S.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final results = _results(store);
    final myCountry = store.currentUser?.country.trim() ?? '';
    final needsCountry =
        _countryScope == 'mine' && myCountry.isEmpty;
    return Column(
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
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'all',
                      icon: Icon(Icons.public_rounded, size: 16),
                      label: Text(S.everyone),
                    ),
                    ButtonSegment(
                      value: 'mine',
                      icon: Icon(Icons.home_outlined, size: 16),
                      label: Text(S.myCountryOnly),
                    ),
                  ],
                  selected: {_countryScope},
                  onSelectionChanged: (s) {
                    final scope = s.first;
                    if (scope == 'mine' && myCountry.isEmpty) {
                      _promptSetCountry();
                      return;
                    }
                    setState(() => _countryScope = scope);
                  },
                ),
              ),
              const SizedBox(width: 8),
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
                          color:
                              Theme.of(context).colorScheme.primary,
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
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: results.length + 2 + (needsCountry ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == 0) return const _DemoTutorsNote();
              if (i == 1) return const _BecomeTutorCard();
              if (needsCountry && i == 2) {
                return _SetCountryCard(onTap: _promptSetCountry);
              }
              final tutor =
                  results[i - 2 - (needsCountry ? 1 : 0)];
              return _TutorCard(tutor: tutor);
            },
          ),
        ),
      ],
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TutorFilterSheet(
        subject: _subject,
        level: _level,
        language: _language,
        pricing: _pricing,
        minRating: _minRating,
        maxPrice: _maxPrice,
        sort: _sort,
        onApply: (f) => setState(() {
          _subject = f.subject;
          _level = f.level;
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

class _SetCountryCard extends StatelessWidget {
  const _SetCountryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(Icons.flag_outlined,
            color: scheme.primary),
        title: const Text('Set your country'),
        subtitle: const Text(
            'Add your country to your profile to see tutors from home.'),
        trailing: const Icon(Icons.arrow_forward_rounded),
        onTap: onTap,
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
                        if (tutor.isDemo) const DemoChip(),
                        const SizedBox(width: 4),
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

// ── Courses ──────────────────────────────────────────────

class _CoursesPage extends StatefulWidget {
  const _CoursesPage();

  @override
  State<_CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<_CoursesPage> {
  final _search = TextEditingController();
  String _query = '';
  String? _subject;
  String? _level;
  String _pricing = 'all'; // all | free | paid

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Course> _results(AppStore store) {
    var list = store.visibleCourses(
      subject: _subject,
      level: _level,
      query: _query,
      freeOnly: _pricing == 'free' ? true : null,
    );
    if (_pricing == 'paid') {
      list = list.where((c) => c.priceUsd > 0).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    final results = _results(store);
    final myLearning = store.myEnrolledCourses();
    final myCourses = me == null
        ? <Course>[]
        : (store.courses.where((c) => c.tutorId == me.id).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    final subjects = store.courses
        .map((c) => c.subject)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final levels = store.courses
        .map((c) => c.level)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (myLearning.isNotEmpty) ...[
          const SectionHeader(title: 'My learning'),
          SizedBox(
            height: 132,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              itemCount: myLearning.length,
              itemBuilder: (context, i) {
                final c = myLearning[i];
                final p = store.courseProgress(c.id);
                return SizedBox(
                  width: 220,
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () =>
                          Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(
                              courseId: c.id),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.title,
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w700),
                                  ),
                                ),
                                if (c.isDemo) const DemoChip(),
                              ],
                            ),
                            const Spacer(),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: p,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${(p * 100).round()}% · ${S.continueCourse}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (myCourses.isNotEmpty) ...[
          SectionHeader(
            title: S.myCourses,
            action: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const CourseFormScreen()),
              ),
              child: const Text(S.createCourse),
            ),
          ),
          ...myCourses.map((c) => _CourseCard(course: c)),
        ],
        if (me != null && myCourses.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const CourseFormScreen()),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(S.createCourse),
            ),
          ),
        const SectionHeader(title: 'All courses'),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(
              hintText: 'Search courses…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: LurniqDropdown<String>(
                  label: S.tutorSubject,
                  value: _subject,
                  hint: S.all,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text(S.all)),
                    ...stringMenuItems(subjects),
                  ],
                  onChanged: (v) =>
                      setState(() => _subject = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LurniqDropdown<String>(
                  label: S.tutorLevel,
                  value: _level,
                  hint: S.all,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text(S.all)),
                    ...stringMenuItems(levels),
                  ],
                  onChanged: (v) => setState(() => _level = v),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'all', label: Text(S.all)),
              ButtonSegment(
                  value: 'free', label: Text(S.free)),
              ButtonSegment(
                  value: 'paid', label: Text(S.paid)),
            ],
            selected: {_pricing},
            onSelectionChanged: (s) =>
                setState(() => _pricing = s.first),
          ),
        ),
        if (results.isEmpty)
          const EmptyState(
            icon: Icons.school_outlined,
            title: S.noCourses,
            subtitle: S.noCoursesBody,
          )
        else
          ...results.map((c) => _CourseCard(course: c)),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = context.watch<AppStore>();
    final enrolled = store.isEnrolled(course.id);
    final progress = store.courseProgress(course.id);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CourseDetailScreen(courseId: course.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      course.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (course.isDemo) const DemoChip(),
                  if (!course.published)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Chip(label: Text(S.draft)),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              TappableName(
                userId: course.tutorId,
                name: course.tutorName,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (course.subject.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 6),
                      child: Chip(label: Text(course.subject)),
                    ),
                  StarsRow(rating: course.rating),
                  const SizedBox(width: 4),
                  Text('(${course.reviewCount})',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall),
                  const Spacer(),
                  Text(
                    course.priceUsd == 0
                        ? S.free
                        : '\$${course.priceUsd.toStringAsFixed(course.priceUsd.truncateToDouble() == course.priceUsd ? 0 : 2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              if (enrolled) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).round()}%',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Live ─────────────────────────────────────────────────

class _LivePage extends StatelessWidget {
  const _LivePage();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    final sessions = store.visibleLiveSessions();
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (me != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        const LiveSessionFormScreen()),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(S.scheduleLive),
            ),
          ),
        if (sessions.isEmpty)
          const EmptyState(
            icon: Icons.live_tv_outlined,
            title: S.noLive,
            subtitle: S.noLiveBody,
          )
        else
          ...sessions.map(
              (s) => _LiveCard(session: s, me: me)),
      ],
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.session, required this.me});

  final LiveSession session;
  final AppUser? me;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final local = session.startsAtUtc == null
        ? null
        : utcToViewer(session.startsAtUtc!, me);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                LiveRoomScreen(sessionId: session.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (session.status == 'live')
                    Container(
                      margin:
                          const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: const Text(
                        S.liveNow,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      session.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (session.isDemo) const DemoChip(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${session.tutorName}'
                '${session.subject.isNotEmpty ? ' · ${session.subject}' : ''}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                        color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule_outlined,
                      size: 16,
                      color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      local == null
                          ? 'No time set'
                          : fmtDateTime(local),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ),
                  if (session.quiz.isNotEmpty) ...[
                    const Icon(Icons.quiz_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${session.quiz.length}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    session.status[0].toUpperCase() +
                        session.status.substring(1),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: session.status == 'live'
                          ? Colors.red
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tutor filters (v2: country handled by the Everyone/Mine toggle) ──

class _FilterValues {
  String? subject;
  String? level;
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
    f.language = widget.language;
    f.pricing = widget.pricing;
    f.minRating = widget.minRating;
    f.maxPrice = widget.maxPrice;
    f.sort = widget.sort;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
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
                const DropdownMenuItem(
                    value: null, child: Text(S.all)),
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
                const DropdownMenuItem(
                    value: null, child: Text(S.all)),
                ...stringMenuItems(C.educationLevels),
              ],
              onChanged: (v) => setState(() => f.level = v),
            ),
            const SizedBox(height: 12),
            LurniqDropdown<String>(
              label: S.tutorLanguage,
              value: f.language,
              hint: S.all,
              items: [
                const DropdownMenuItem(
                    value: null, child: Text(S.all)),
                ...stringMenuItems(languages),
              ],
              onChanged: (v) =>
                  setState(() => f.language = v),
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
                onChanged: (v) =>
                    setState(() => f.maxPrice = v),
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
              onChanged: (v) =>
                  setState(() => f.minRating = v),
            ),
            const SizedBox(height: 8),
            LurniqDropdown<String>(
              label: S.sortBy,
              value: f.sort,
              items: const [
                DropdownMenuItem(
                    value: 'rating', child: Text(S.tutorSortRating)),
                DropdownMenuItem(
                    value: 'priceLow',
                    child: Text(S.tutorSortPriceLow)),
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
