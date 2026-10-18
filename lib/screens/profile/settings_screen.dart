import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';

/// App settings: language, currency, timezone, notifications, blocked users,
/// help, legal placeholders, demo reset, danger zone.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    if (me == null) return const Scaffold();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(S.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SectionHeader(title: S.account),
          _Tile(
            icon: Icons.language_outlined,
            title: S.language,
            subtitle: 'English',
            onTap: () => _languageDialog(context),
          ),
          _Tile(
            icon: Icons.attach_money_rounded,
            title: S.currencyDisplay,
            subtitle: '${me.currency} — ${S.currencyNote}',
            onTap: () => _currencyDialog(context, store),
          ),
          _Tile(
            icon: Icons.schedule_outlined,
            title: S.timezone,
            subtitle: me.timezoneMode == 'device'
                ? '${S.timezoneDevice} (${offsetLabel(viewerOffsetMinutes(me))})'
                : me.timezoneLabel,
            onTap: () => _timezoneDialog(context, store),
          ),
          SectionHeader(title: S.notifications),
          _SwitchTile(
            icon: Icons.notifications_outlined,
            title: S.notifPush,
            value: me.notifPush,
            onChanged: (v) {
              me.notifPush = v;
              store.updateProfile(me);
            },
          ),
          _SwitchTile(
            icon: Icons.favorite_outline_rounded,
            title: S.notifLikes,
            value: me.notifLikes,
            onChanged: (v) {
              me.notifLikes = v;
              store.updateProfile(me);
            },
          ),
          _SwitchTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: S.notifComments,
            value: me.notifComments,
            onChanged: (v) {
              me.notifComments = v;
              store.updateProfile(me);
            },
          ),
          _SwitchTile(
            icon: Icons.alarm_outlined,
            title: S.notifReminders,
            value: me.notifReminders,
            onChanged: (v) {
              me.notifReminders = v;
              store.updateProfile(me);
            },
          ),
          _SwitchTile(
            icon: Icons.group_outlined,
            title: S.notifGroups,
            value: me.notifGroups,
            onChanged: (v) {
              me.notifGroups = v;
              store.updateProfile(me);
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              S.notifPhase2Note,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          SectionHeader(title: S.blockedUsers),
          if (me.blockedIds.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(S.noBlockedUsers),
            ),
          ...me.blockedIds.map((id) {
            final u = store.userById(id);
            return ListTile(
              leading: UserAvatar(
                  name: u?.displayName ?? '?', radius: 18),
              title: Text(u?.displayName ?? id),
              trailing: TextButton(
                onPressed: () => store.unblock(id),
                child: const Text(S.unblock),
              ),
            );
          }),
          SectionHeader(title: S.helpSupport),
          _Tile(
            icon: Icons.help_outline_rounded,
            title: S.helpSupport,
            onTap: () => _infoDialog(
                context, S.helpSupport, S.helpBody),
          ),
          _Tile(
            icon: Icons.description_outlined,
            title: S.termsOfService,
            onTap: () => _infoDialog(
                context, S.termsOfService, S.legalPlaceholder),
          ),
          _Tile(
            icon: Icons.privacy_tip_outlined,
            title: S.privacyPolicy,
            onTap: () => _infoDialog(
                context, S.privacyPolicy, S.legalPlaceholder),
          ),
          _Tile(
            icon: Icons.refresh_rounded,
            title: S.resetDemoContent,
            onTap: () async {
              final ok = await confirmDialog(
                context,
                title: S.resetDemoContent,
                body: S.resetDemoContentConfirm,
                confirmLabel: S.confirm,
                destructive: false,
              );
              if (ok) {
                await store.clearDemoContent();
                if (context.mounted) {
                  showSnack(
                      context, S.demoContentCleared);
                }
              }
            },
          ),
          SectionHeader(
            title: S.dangerZone,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(S.signOut),
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: S.signOut,
                      body: S.signOutConfirm,
                      confirmLabel: S.signOut,
                      destructive: false,
                    );
                    if (ok) {
                      await store.signOut();
                      if (context.mounted) {
                        Navigator.of(context)
                            .popUntil((r) => r.isFirst);
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: Icon(Icons.delete_forever_outlined,
                      color: scheme.error),
                  label: Text(S.deleteAccount,
                      style:
                          TextStyle(color: scheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: scheme.error
                            .withValues(alpha: 0.5)),
                  ),
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: S.deleteAccountTitle,
                      body: S.deleteAccountBody,
                    );
                    if (ok) {
                      await store.deleteAccount();
                      if (context.mounted) {
                        Navigator.of(context)
                            .popUntil((r) => r.isFirst);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _languageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ListTile(
              title: Text('English'),
              trailing: Icon(Icons.check_rounded),
              contentPadding: EdgeInsets.zero,
            ),
            Text(S.languageNote),
          ],
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

  void _currencyDialog(BuildContext context, AppStore store) {
    final me = store.currentUser!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.currencyDisplay),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.currencyNote,
                  style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: C.currencies.length,
                  itemBuilder: (ctx, i) {
                    final c = C.currencies[i];
                    final selected =
                        me.currency == c['code'];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                          '${c['symbol']} ${c['label']} (${c['code']})'),
                      trailing: selected
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () {
                        me.currency = c['code']!;
                        store.updateProfile(me);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _timezoneDialog(BuildContext context, AppStore store) {
    final me = store.currentUser!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.timezone),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<String>(
            groupValue: me.timezoneMode == 'fixed'
                ? 'fixed:${me.timezoneOffsetMinutes}'
                : 'device',
            onChanged: (v) {
              if (v == null) return;
              if (v == 'device') {
                me.timezoneMode = 'device';
              } else {
                final offset =
                    int.tryParse(v.split(':').last);
                final tz = C.timezones.firstWhere(
                  (t) => t['offset'] == offset,
                  orElse: () => C.timezones.first,
                );
                me.timezoneMode = 'fixed';
                me.timezoneOffsetMinutes =
                    tz['offset'] as int;
                me.timezoneLabel =
                    tz['label'] as String;
              }
              store.updateProfile(me);
              Navigator.of(ctx).pop();
            },
            child: ListView(
              shrinkWrap: true,
              children: [
                const RadioListTile<String>(
                  value: 'device',
                  title: Text(S.timezoneDevice),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                ...C.timezones.map(
                  (tz) => RadioListTile<String>(
                    value: 'fixed:${tz['offset']}',
                    title: Text(tz['label'] as String,
                        style: const TextStyle(
                            fontSize: 14)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _infoDialog(
      BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.w600)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
