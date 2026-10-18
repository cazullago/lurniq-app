import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/profile/user_profile_screen.dart';
import '../store/app_store.dart';

/// A person's name that navigates to their profile when tapped.
/// Used in feed cards, comments, tutor cards, member lists, chat headers —
/// the user asked that every name in the app be tappable.
class TappableName extends StatelessWidget {
  const TappableName({
    super.key,
    required this.userId,
    required this.name,
    this.style,
    this.maxLines = 1,
  });

  final String userId;
  final String name;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final me = context.read<AppStore>().currentUser;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        if (userId.isEmpty) return;
        if (me != null && userId == me.id) {
          // Own profile lives under the Profile tab; still show the sheet
          // for consistency.
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(userId: userId),
          ),
        );
      },
      child: Text(
        name,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: (style ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
