import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../screens/profile/user_profile_screen.dart';
import '../../store/app_store.dart';
import '../../widgets/tappable_name.dart';

/// One 1:1 conversation thread.
///
/// [BACKEND] Wiring point for real messaging: replace the on-device
/// [AppStore.sendMessage]/[AppStore.messagesFor] calls with a Firestore
/// `conversations/{id}/messages` subcollection plus FCM push delivery, and
/// swap the local block gate for server-side enforcement. The UI contract
/// (conversation id, message ordering, blocked state) stays the same.
///
/// CONTRACT (foundation): the constructor signature must stay stable —
/// profile screens navigate here via `ConversationScreen(otherUserId: ...)`.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.otherUserId});

  final String otherUserId;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  String? _convId;
  final _text = TextEditingController();
  final _scroll = ScrollController();
  int _lastCount = 0;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    // Creates the conversation on demand (store API) after the first frame:
    // calling it synchronously here would notifyListeners() while the
    // provider's dependents are still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final conv =
          context.read<AppStore>().conversationWith(widget.otherUserId);
      setState(() => _convId = conv.id);
    });
    _text.addListener(() {
      final can = _text.text.trim().isNotEmpty;
      if (can != _canSend) setState(() => _canSend = can);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send(AppStore store) async {
    final body = _text.text.trim();
    if (body.isEmpty) return;
    _text.clear();
    await store.sendMessage(_convId!, body: body);
    // Auto-scroll happens in build via the message-count watcher.
  }

  Future<void> _attach(AppStore store) async {
    final path = await pickAndSaveImage(
      context,
      store.appDir,
      camera: false,
    );
    if (path == null || !mounted) return;
    await store.sendMessage(_convId!, imagePath: path);
  }

  void _reportDialog(BuildContext context, AppStore store, String peerName) {
    String reason = C.reportReasons.first;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text(S.reportUser),
          content: RadioGroup<String>(
            groupValue: reason,
            onChanged: (v) => setState(() => reason = v ?? reason),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.reportReason,
                  style: Theme.of(ctx)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...C.reportReasons.map(
                  (r) => RadioListTile<String>(
                    value: r,
                    title: Text(r, style: const TextStyle(fontSize: 14)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(S.cancel),
            ),
            FilledButton(
              onPressed: () {
                store.addReport(
                  targetType: 'user',
                  targetId: widget.otherUserId,
                  targetSummary: peerName,
                  reason: reason,
                );
                Navigator.of(ctx).pop();
                showSnack(context, S.reportThanks);
              },
              child: const Text(S.report),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    final peerName = store.displayNameFor(widget.otherUserId);
    final scheme = Theme.of(context).colorScheme;

    final convId = _convId;
    if (convId == null) {
      return Scaffold(
        appBar: AppBar(
          title: TappableName(
            userId: widget.otherUserId,
            name: peerName,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final blocked = store.isBlocked(widget.otherUserId);
    final messages = store.messagesFor(convId);

    // Auto-scroll to the newest message whenever one arrives.
    if (messages.length != _lastCount) {
      _lastCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      appBar: AppBar(
        title: TappableName(
          userId: widget.otherUserId,
          name: peerName,
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          UserProfileScreen(userId: widget.otherUserId),
                    ),
                  );
                case 'block':
                  if (blocked) {
                    store.unblock(widget.otherUserId);
                    showSnack(context, S.unblockUser);
                  } else {
                    store.block(widget.otherUserId);
                    showSnack(context, S.userBlocked);
                  }
                case 'report':
                  _reportDialog(context, store, peerName);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text(S.viewProfile),
              ),
              PopupMenuItem(
                value: 'block',
                child: Text(blocked ? S.unblockUser : S.blockUser),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text(S.reportUser),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        'Say hello to $peerName.',
                        style:
                            TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final m = messages[i];
                        final mine = m.senderId == me?.id;
                        return _Bubble(message: m, mine: mine);
                      },
                    ),
            ),
            if (blocked)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: scheme.outlineVariant, width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'You blocked $peerName. They can’t message you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => store.unblock(widget.otherUserId),
                      child: const Text(S.unblockUser),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: scheme.outlineVariant, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Attach photo',
                      icon: const Icon(Icons.photo_outlined),
                      onPressed: () => _attach(store),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _text,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(store),
                        decoration: InputDecoration(
                          hintText: S.typeMessage,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filled(
                      tooltip: 'Send',
                      icon: const Icon(Icons.send),
                      onPressed: _canSend ? () => _send(store) : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single chat bubble: mine right-aligned, theirs left-aligned.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage =
        message.imagePath != null && message.imagePath!.isNotEmpty;
    final imageFile = hasImage ? File(message.imagePath!) : null;
    final showImage =
        hasImage && imageFile != null && imageFile.existsSync();

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: mine ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(imageFile, fit: BoxFit.cover),
              ),
            if (showImage && message.body.isNotEmpty)
              const SizedBox(height: 6),
            if (message.body.isNotEmpty)
              Text(
                message.body,
                style: TextStyle(
                  fontSize: 15,
                  color: mine
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              fmtTime(message.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: (mine
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface)
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
