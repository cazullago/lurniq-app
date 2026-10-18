import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';
import '../../widgets/ui.dart';
import 'conversation_screen.dart';

/// The conversation list, reached from the Profile tab.
///
/// CONTRACT (foundation): the constructor signature must stay stable —
/// the Profile tab navigates here.
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  /// The other participant of a 1:1 conversation (never the current user).
  String _peerId(Conversation c, String? myId) {
    if (myId == null) return c.participantIds.isEmpty ? '' : c.participantIds.first;
    return c.participantIds.firstWhere(
      (id) => id != myId,
      orElse: () => c.participantIds.isEmpty ? '' : c.participantIds.first,
    );
  }

  String _preview(List<ChatMessage> messages) {
    if (messages.isEmpty) return '';
    final last = messages.last;
    if (last.body.isNotEmpty) return last.body;
    if (last.imagePath != null && last.imagePath!.isNotEmpty) {
      return '[Photo]';
    }
    return '';
  }

  Future<void> _delete(
      BuildContext context, AppStore store, Conversation c, String peerName) async {
    // Local labels: strings.dart currently defines `blockUser` twice, so we
    // don't reference S.blockUser / S.deleteConversation here.
    final ok = await confirmDialog(
      context,
      title: 'Delete conversation?',
      body: 'Delete your conversation with $peerName? This cannot be undone.',
    );
    if (ok) {
      await store.deleteConversation(c.id);
      if (context.mounted) showSnack(context, 'Conversation deleted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    final conversations = store.myConversations();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(S.messages)),
      body: Column(
        children: [
          // Honest demo-mode label: these chats live on this device only.
          Container(
            width: double.infinity,
            color: scheme.tertiaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: scheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    S.messagesDemoNote,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: conversations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.forum_outlined,
                              size: 64, color: scheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            S.noConversations,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            S.noConversationsBody,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) {
                      final c = conversations[i];
                      final peerId = _peerId(c, me?.id);
                      final peerName = store.displayNameFor(peerId);
                      final messages = store.messagesFor(c.id);
                      final preview = _preview(messages);
                      return InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ConversationScreen(otherUserId: peerId),
                          ),
                        ),
                        onLongPress: () => _delete(context, store, c, peerName),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              UserAvatar(
                                name: peerName,
                                avatarPath: store.avatarFor(peerId),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            peerName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          timeAgo(c.lastMessageAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      preview.isEmpty
                                          ? S.newMessage
                                          : preview,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: preview.isEmpty
                                            ? scheme.onSurfaceVariant
                                                .withValues(alpha: 0.7)
                                            : scheme.onSurfaceVariant,
                                        fontStyle: preview.isEmpty
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: S.delete,
                                icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20),
                                onPressed: () =>
                                    _delete(context, store, c, peerName),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
