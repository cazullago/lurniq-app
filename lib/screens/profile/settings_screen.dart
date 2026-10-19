import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../store/app_store.dart';
import 'subscription_screen.dart';
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
          _WashSection(
            title: S.account,
            children: [
              _Tile(
                icon: Icons.language_outlined,
                title: S.language,
                subtitle: 'English',
                onTap: () => _languageDialog(context),
              ),
              _Tile(
                icon: Icons.attach_money_rounded,
                title: S.currencyDisplay,
                subtitle:
                    '${me.currency} — ${S.currencyNote}',
                onTap: () =>
                    _currencyDialog(context, store),
              ),
              _Tile(
                icon: Icons.schedule_outlined,
                title: S.timezone,
                subtitle: me.timezoneMode == 'device'
                    ? '${S.timezoneDevice} (${offsetLabel(viewerOffsetMinutes(me))})'
                    : me.timezoneLabel,
                onTap: () =>
                    _timezoneDialog(context, store),
              ),
              _Tile(
                icon: Icons.workspace_premium_outlined,
                title: S.subscription,
                subtitle:
                    store.isPlus ? S.plusTitle : S.freeTier,
                badge: store.isPlus ? 'PLUS' : null,
                onTap: () =>
                    Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          const SubscriptionScreen()),
                ),
              ),
            ],
          ),
          _WashSection(
            title: S.appearance,
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 2, 16, 0),
                child: Text(
                  S.themeMode,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                          fontWeight: FontWeight.w700),
                ),
              ),
              const Padding(
                padding:
                    EdgeInsets.fromLTRB(8, 10, 8, 2),
                child: _ThemeModeSelector(),
              ),
            ],
          ),
          const _WashSection(
            title: 'AI',
            children: [
              _AiKeySection(),
            ],
          ),
          _WashSection(
            title: S.notifications,
            children: [
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
                padding:
                    const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  S.notifPhase2Note,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                          color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          _WashSection(
            title: S.blockedUsers,
            children: [
              if (me.blockedIds.isEmpty)
                const Padding(
                  padding:
                      EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(S.noBlockedUsers),
                ),
              ...me.blockedIds.map((id) {
                final u = store.userById(id);
                return ListTile(
                  leading: UserAvatar(
                      name: u?.displayName ?? '?',
                      radius: 18),
                  title: Text(u?.displayName ?? id),
                  trailing: TextButton(
                    onPressed: () => store.unblock(id),
                    child: const Text(S.unblock),
                  ),
                );
              }),
            ],
          ),
          _WashSection(
            title: S.helpSupport,
            children: [
              _Tile(
                icon: Icons.help_outline_rounded,
                title: S.helpSupport,
                onTap: () => _infoDialog(
                    context, S.helpSupport, S.helpBody),
              ),
              _Tile(
                icon: Icons.description_outlined,
                title: S.termsOfService,
                onTap: () => _infoDialog(context,
                    S.termsOfService, S.legalPlaceholder),
              ),
              _Tile(
                icon: Icons.privacy_tip_outlined,
                title: S.privacyPolicy,
                onTap: () => _infoDialog(context,
                    S.privacyPolicy, S.legalPlaceholder),
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
            ],
          ),
          _WashSection(
            title: S.dangerZone,
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      icon:
                          const Icon(Icons.logout_rounded),
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
                            Navigator.of(context).popUntil(
                                (r) => r.isFirst);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: Icon(
                          Icons.delete_forever_outlined,
                          color: scheme.error),
                      label: Text(S.deleteAccount,
                          style: TextStyle(
                              color: scheme.error)),
                      style:
                          OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: scheme.error.withValues(
                                alpha: 0.5)),
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
                            Navigator.of(context).popUntil(
                                (r) => r.isFirst);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
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

/// A settings section grouped on a warm gradient wash: the section's rows
/// sit together as warm cards instead of a flat generic form.
class _WashSection extends StatelessWidget {
  const _WashSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      decoration: BoxDecoration(
        gradient: AppTheme.washGradient(brightness),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient:
                        AppTheme.heroGradient(brightness),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// Visual Day / Night / System selector: three preview chips that show the
/// actual look (gradient for system, light paper, dark charcoal).
class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final current = store.themeModeSetting;
    return Row(
      children: [
        for (final mode in ThemeModeSetting.values)
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4),
              child: _ThemeChip(
                mode: mode,
                selected: mode == current,
                onTap: () => store.setThemeMode(mode),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeModeSetting mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final label = switch (mode) {
      ThemeModeSetting.system => S.themeSystem,
      ThemeModeSetting.light => S.themeLight,
      ThemeModeSetting.dark => S.themeDark,
    };
    final icon = switch (mode) {
      ThemeModeSetting.system => Icons.brightness_auto_rounded,
      ThemeModeSetting.light => Icons.light_mode_rounded,
      ThemeModeSetting.dark => Icons.dark_mode_rounded,
    };
    // The preview swatch shows the real thing: the signature gradient for
    // "system", the actual light paper, the actual dark charcoal.
    final swatchGradient = mode == ThemeModeSetting.system
        ? AppTheme.heroGradient(brightness)
        : null;
    final swatchColor = mode == ThemeModeSetting.light
        ? const Color(0xFFFFFBF4)
        : mode == ThemeModeSetting.dark
            ? const Color(0xFF1C1512)
            : null;
    final iconColor = mode == ThemeModeSetting.system
        ? Colors.white
        : mode == ThemeModeSetting.light
            ? const Color(0xFFB45309)
            : const Color(0xFFF5B04C);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: swatchGradient,
                  color: swatchColor,
                  border: Border.all(
                    color: selected
                        ? scheme.primary
                        : scheme.outlineVariant
                            .withValues(alpha: 0.6),
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: Center(
                  child:
                      Icon(icon, color: iconColor, size: 28),
                ),
              ),
              if (selected)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// AI helper API key: entered here, stored on-device via the store.
/// A Google AI Studio (Gemini) API key works here.
class _AiKeySection extends StatefulWidget {
  const _AiKeySection();

  @override
  State<_AiKeySection> createState() => _AiKeySectionState();
}

class _AiKeySectionState extends State<_AiKeySection> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final scheme = Theme.of(context).colorScheme;
    final hasKey = store.aiApiKey != null &&
        store.aiApiKey!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasKey)
          Card(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: ListTile(
              leading: const Icon(Icons.key_rounded),
              title: const Text(S.aiApiKey),
              subtitle: const Text('Key saved on this device'),
              trailing: TextButton(
                onPressed: () async {
                  await store.setAiApiKey(null);
                },
                child: const Text('Clear'),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _ctrl,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: S.aiApiKey,
                    hintText: S.aiApiKeyHint,
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: _saving
                        ? null
                        : () async {
                            final v = _ctrl.text.trim();
                            if (v.isEmpty) {
                              showSnack(
                                  context, S.aiApiKeyHint);
                              return;
                            }
                            setState(() => _saving = true);
                            await store.setAiApiKey(v);
                            if (!mounted) return;
                            setState(() => _saving = false);
                            _ctrl.clear();
                            showSnack(context, S.aiApiKeySaved);
                          },
                    child: const Text(S.save),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'A Google AI Studio (Gemini) API key works here.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
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
