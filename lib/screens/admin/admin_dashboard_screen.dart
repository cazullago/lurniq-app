import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';

/// Protected admin dashboard (Phase 5 will expand each area).
/// Every action taken here is written to the audit log.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final stats = store.stats;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(S.adminDashboard)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats.entries
                  .map((e) => _StatChip(
                      label: e.key, value: e.value))
                  .toList(),
            ),
          ),
          SectionHeader(title: S.adminContent),
          _AdminTile(
            icon: Icons.report_outlined,
            title: S.adminReports,
            subtitle:
                '${store.openReports.length} ${S.openReports.toLowerCase()}',
            badge: store.openReports.length,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      const _ReportsScreen()),
            ),
          ),
          _AdminTile(
            icon: Icons.campaign_outlined,
            title: S.adminAnnouncements,
            subtitle:
                '${store.activeAnnouncements.length} active',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      const _AnnouncementsScreen()),
            ),
          ),
          _AdminTile(
            icon: Icons.percent_rounded,
            title: S.adminCommission,
            subtitle:
                '${(store.commissionRate * 100).toStringAsFixed(1)}%',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      const _CommissionScreen()),
            ),
          ),
          _AdminTile(
            icon: Icons.history_rounded,
            title: S.adminAuditLog,
            subtitle:
                '${store.adminLog.length} entries',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      const _AuditLogScreen()),
            ),
          ),
          SectionHeader(title: 'Phase 5 areas'),
          _AdminTile(
            icon: Icons.people_outline_rounded,
            title: S.adminUsers,
            subtitle: S.phase5Note,
            onTap: () => _phase5(context, S.adminUsers),
          ),
          _AdminTile(
            icon: Icons.school_outlined,
            title: S.adminTutorApps,
            subtitle:
                '${store.tutorInterests.length} interested · ${S.phase5Note}',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      const _TutorInterestsScreen()),
            ),
          ),
          _AdminTile(
            icon: Icons.play_circle_outline_rounded,
            title: S.adminCourses,
            subtitle: S.phase5Note,
            onTap: () => _phase5(context, S.adminCourses),
          ),
          _AdminTile(
            icon: Icons.payments_outlined,
            title: S.adminTransactions,
            subtitle: S.phase5Note,
            onTap: () =>
                _phase5(context, S.adminTransactions),
          ),
          _AdminTile(
            icon: Icons.money_off_outlined,
            title: S.adminRefunds,
            subtitle: S.phase5Note,
            onTap: () =>
                _phase5(context, S.adminRefunds),
          ),
          _AdminTile(
            icon: Icons.language_outlined,
            title: S.adminLanguages,
            subtitle: S.phase5Note,
            onTap: () =>
                _phase5(context, S.adminLanguages),
          ),
          _AdminTile(
            icon: Icons.analytics_outlined,
            title: S.adminAnalytics,
            subtitle: S.phase5Note,
            onTap: () =>
                _phase5(context, S.adminAnalytics),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              S.adminSecurityNote,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                      color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  void _phase5(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text(S.phase5Note),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(S.ok),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$value',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge = 0,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: scheme.primary),
        title: Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge > 0)
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: scheme.error,
                  shape: BoxShape.circle,
                ),
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ReportsScreen extends StatelessWidget {
  const _ReportsScreen();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final reports = store.openReports;
    return Scaffold(
      appBar: AppBar(title: const Text(S.adminReports)),
      body: reports.isEmpty
          ? const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: S.noOpenReports,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: reports.length,
              itemBuilder: (context, i) {
                final r = reports[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(r.reason,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                            '${r.targetType} · ${r.targetSummary}'),
                        Text(
                          timeAgo(r.createdAt),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () => store
                                  .resolveReport(
                                      r.id, 'dismissed'),
                              child: const Text(
                                  S.dismissReport),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonal(
                              onPressed: () => store
                                  .resolveReport(
                                      r.id, 'actioned'),
                              child: const Text(
                                  S.hideContent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _AnnouncementsScreen extends StatelessWidget {
  const _AnnouncementsScreen();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      appBar: AppBar(
          title: const Text(S.adminAnnouncements)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newAnnouncement(context, store),
        icon: const Icon(Icons.add_rounded),
        label: const Text(S.newAnnouncement),
      ),
      body: store.announcements.isEmpty
          ? const EmptyState(
              icon: Icons.campaign_outlined,
              title: S.noAnnouncements,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: store.announcements.length,
              itemBuilder: (context, i) {
                final a = store.announcements[i];
                return Card(
                  child: ListTile(
                    title: Text(a.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${a.body}\n${a.active ? S.activate : S.deactivate}'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'toggle') {
                          store.toggleAnnouncement(a.id);
                        } else if (v == 'delete') {
                          store.deleteAnnouncement(a.id);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(a.active
                              ? S.deactivate
                              : S.activate),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(S.delete),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _newAnnouncement(
      BuildContext context, AppStore store) {
    final title = TextEditingController();
    final body = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.newAnnouncement),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: title,
                decoration: const InputDecoration(
                    labelText: S.announcementTitle)),
            const SizedBox(height: 12),
            TextField(
                controller: body,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                    labelText: S.announcementBody,
                    alignLabelWithHint: true)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () {
              try {
                store.addAnnouncement(
                    title.text, body.text);
                Navigator.of(ctx).pop();
                showSnack(
                    context, S.announcementPublished);
              } on StoreException catch (e) {
                showSnack(ctx, e.message);
              }
            },
            child: const Text(S.publish),
          ),
        ],
      ),
    );
  }
}

class _CommissionScreen extends StatefulWidget {
  const _CommissionScreen();

  @override
  State<_CommissionScreen> createState() =>
      _CommissionScreenState();
}

class _CommissionScreenState
    extends State<_CommissionScreen> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = context.read<AppStore>().commissionRate;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      appBar:
          AppBar(title: const Text(S.adminCommission)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.commissionRate}: ${(_value * 100).toStringAsFixed(1)}%',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(S.commissionHint),
            const SizedBox(height: 16),
            Slider(
              value: _value,
              min: 0,
              max: 0.5,
              divisions: 50,
              label:
                  '${(_value * 100).toStringAsFixed(1)}%',
              onChanged: (v) =>
                  setState(() => _value = v),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Example: a \$20.00 course at ${(_value * 100).toStringAsFixed(0)}% → '
                'platform \$${(20 * _value).toStringAsFixed(2)}, '
                'tutor \$${(20 * (1 - _value)).toStringAsFixed(2)} '
                '(before payment fees, taxes, refunds).',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  store.setCommissionRate(_value);
                  showSnack(
                      context, S.commissionSaved);
                },
                child: const Text(S.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditLogScreen extends StatelessWidget {
  const _AuditLogScreen();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final log = store.adminLog;
    return Scaffold(
      appBar: AppBar(title: const Text(S.adminAuditLog)),
      body: log.isEmpty
          ? const EmptyState(
              icon: Icons.history_rounded,
              title: S.noAuditEntries,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: log.length,
              itemBuilder: (context, i) {
                final e = log[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: const Icon(
                        Icons.shield_outlined),
                    title: Text(e.action,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    subtitle: Text(
                        '${e.detail}\n${fmtDateTime(e.at)}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

class _TutorInterestsScreen extends StatelessWidget {
  const _TutorInterestsScreen();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final list = store.tutorInterests;
    return Scaffold(
      appBar: AppBar(title: const Text(S.adminTutorApps)),
      body: list.isEmpty
          ? const EmptyState(
              icon: Icons.school_outlined,
              title: S.noOpenReports,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final t = list[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: UserAvatar(
                        name: t.name, radius: 20),
                    title: Text(t.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${t.contact}\n${t.subjects}\n${fmtDateTime(t.createdAt)}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
