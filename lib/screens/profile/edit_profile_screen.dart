import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';

/// Edit own profile: all fields + per-field privacy controls.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _country = TextEditingController();
  final _school = TextEditingController();
  final _interests = TextEditingController();
  final _goals = TextEditingController();
  String? _level;
  String? _language;
  final Map<String, String> _privacy = {};
  bool _loaded = false;
  bool _busy = false;

  static const _fields = [
    'bio',
    'country',
    'educationLevel',
    'school',
    'interests',
    'learningGoals',
  ];

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _country.dispose();
    _school.dispose();
    _interests.dispose();
    _goals.dispose();
    super.dispose();
  }

  void _load(AppUser me) {
    if (_loaded) return;
    _name.text = me.displayName;
    _bio.text = me.bio;
    _country.text = me.country;
    _school.text = me.school;
    _interests.text = me.interests.join(', ');
    _goals.text = me.learningGoals.join(', ');
    _level = me.educationLevel.isEmpty ? null : me.educationLevel;
    _language = me.language;
    for (final f in _fields) {
      _privacy[f] = me.privacyFor(f);
    }
    _loaded = true;
  }

  List<String> _csv(TextEditingController c) => c.text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _save() async {
    final store = context.read<AppStore>();
    final me = store.currentUser;
    if (me == null) return;
    if (_name.text.trim().isEmpty) {
      showSnack(context, S.nameRequired);
      return;
    }
    setState(() => _busy = true);
    me.displayName = _name.text.trim();
    me.bio = _bio.text.trim();
    me.country = _country.text.trim();
    me.school = _school.text.trim();
    me.interests = _csv(_interests);
    me.learningGoals = _csv(_goals);
    me.educationLevel = _level ?? '';
    me.language = _language ?? 'en';
    me.fieldPrivacy.addAll(_privacy);
    await store.updateProfile(me);
    if (mounted) {
      Navigator.of(context).pop();
      showSnack(context, S.profileSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    if (me == null) return const Scaffold();
    _load(me);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.editProfile),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: const Text(S.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: UserAvatar(
                  name: me.displayName,
                  avatarPath: me.avatarPath,
                  radius: 40),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(S.profilePhoto,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                          color: scheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: S.displayName),
            ),
            const SizedBox(height: 12),
            _PrivacyField(
              label: S.bio,
              privacy: _privacy['bio']!,
              onPrivacy: (v) =>
                  setState(() => _privacy['bio'] = v),
              child: TextField(
                controller: _bio,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: S.bioHint,
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PrivacyField(
                    label: S.country,
                    privacy: _privacy['country']!,
                    onPrivacy: (v) => setState(
                        () => _privacy['country'] = v),
                    child: TextField(
                      controller: _country,
                      decoration:
                          const InputDecoration(
                              hintText: S.countryHint),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PrivacyField(
                    label: S.educationLevel,
                    privacy:
                        _privacy['educationLevel']!,
                    onPrivacy: (v) => setState(() =>
                        _privacy['educationLevel'] =
                            v),
                    child: LurniqDropdown<String>(
                      value: _level,
                      items:
                          stringMenuItems(C.educationLevels),
                      onChanged: (v) =>
                          setState(() => _level = v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PrivacyField(
              label: S.schoolOptional,
              privacy: _privacy['school']!,
              onPrivacy: (v) => setState(
                  () => _privacy['school'] = v),
              child: TextField(
                controller: _school,
                decoration: const InputDecoration(),
              ),
            ),
            const SizedBox(height: 12),
            _PrivacyField(
              label: S.interests,
              privacy: _privacy['interests']!,
              onPrivacy: (v) => setState(
                  () => _privacy['interests'] = v),
              child: TextField(
                controller: _interests,
                decoration: const InputDecoration(
                    hintText: S.interestsHint),
              ),
            ),
            const SizedBox(height: 12),
            _PrivacyField(
              label: S.learningGoals,
              privacy: _privacy['learningGoals']!,
              onPrivacy: (v) => setState(
                  () => _privacy['learningGoals'] = v),
              child: TextField(
                controller: _goals,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: S.learningGoalsHint),
              ),
            ),
            const SizedBox(height: 12),
            LurniqDropdown<String>(
              label: S.preferredLanguage,
              value: _language,
              items: const [
                DropdownMenuItem(
                    value: 'en',
                    child: Text('English')),
              ],
              onChanged: (v) =>
                  setState(() => _language = v),
            ),
            const SizedBox(height: 4),
            Text(S.languageNote,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                        color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  const Expanded(
                      child: Text(S.privacyHint,
                          style:
                              TextStyle(fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                                strokeWidth: 2),
                      )
                    : const Text(S.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyField extends StatelessWidget {
  const _PrivacyField({
    required this.label,
    required this.privacy,
    required this.onPrivacy,
    required this.child,
  });

  final String label;
  final String privacy;
  final ValueChanged<String> onPrivacy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            DropdownButton<String>(
              value: privacy,
              underline: const SizedBox.shrink(),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                      fontWeight: FontWeight.w700),
              items: const [
                DropdownMenuItem(
                    value: 'public',
                    child: Text(S.privacyPublic)),
                DropdownMenuItem(
                    value: 'followers',
                    child: Text(S.privacyFollowers)),
                DropdownMenuItem(
                    value: 'private',
                    child: Text(S.privacyPrivate)),
              ],
              onChanged: (v) {
                if (v != null) onPrivacy(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
