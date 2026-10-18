import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lurniq/core/strings.dart';
import 'package:lurniq/models/models.dart';
import 'package:lurniq/screens/messages/conversation_screen.dart';
import 'package:lurniq/screens/messages/conversations_screen.dart';
import 'package:lurniq/store/app_store.dart';
import 'package:provider/provider.dart';

/// Messaging widget tests (v2). Widget tests use [AppStore.loadForTest]:
/// real async file IO deadlocks inside testWidgets' FakeAsync zone, so the
/// disk is never touched here.

AppUser _addUser(AppStore store, String name, String username) {
  final user = AppUser(
    id: 'u_${username}_${DateTime.now().microsecondsSinceEpoch}',
    displayName: name,
    username: username,
  );
  store.users.add(user);
  return user;
}

Future<AppStore> _twoUserStore() async {
  final store = await AppStore.loadForTest();
  final me = _addUser(store, 'Me Test', 'me_test');
  _addUser(store, 'Peer One', 'peer_one');
  _addUser(store, 'Peer Two', 'peer_two');
  store.currentUser = me;
  return store;
}

AppUser _user(AppStore store, String username) =>
    store.users.firstWhere((u) => u.username == username);

Widget _app(AppStore store, Widget home) {
  return ChangeNotifierProvider<AppStore>.value(
    value: store,
    child: MaterialApp(home: home),
  );
}

void main() {
  // The store schedules a debounced save timer on every mutation. flush()
  // cancels it so FakeAsync's end-of-test timer check stays happy; dispose()
  // then tears the store down.
  testWidgets('send message appears in the thread', (tester) async {
    final store = await _twoUserStore();
    addTearDown(store.dispose);
    final peer = _user(store, 'peer_one');
    await tester.pumpWidget(
        _app(store, ConversationScreen(otherUserId: peer.id)));
    await tester.pumpAndSettle();

    expect(find.text(S.typeMessage), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hello from test');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Hello from test'), findsOneWidget);
    // The input clears after sending.
    expect(find.text(S.typeMessage), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    await store.flush();
  });

  testWidgets('conversation list shows latest conversation first',
      (tester) async {
    final store = await _twoUserStore();
    addTearDown(store.dispose);
    final peerOne = _user(store, 'peer_one');
    final peerTwo = _user(store, 'peer_two');

    // Older conversation first, newer conversation second.
    final c1 = store.conversationWith(peerOne.id);
    await store.sendMessage(c1.id, body: 'older thread');
    c1.lastMessageAt =
        DateTime.now().subtract(const Duration(minutes: 30));
    final c2 = store.conversationWith(peerTwo.id);
    await store.sendMessage(c2.id, body: 'newer thread');

    await tester.pumpWidget(_app(store, const ConversationsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Peer One'), findsOneWidget);
    expect(find.text('Peer Two'), findsOneWidget);
    expect(find.text('older thread'), findsOneWidget);
    expect(find.text('newer thread'), findsOneWidget);

    // Newest first: Peer Two's row sits above Peer One's row.
    final topTwo = tester.getTopLeft(find.text('Peer Two')).dy;
    final topOne = tester.getTopLeft(find.text('Peer One')).dy;
    expect(topTwo, lessThan(topOne));
    await store.flush();
  });

  testWidgets('blocking a user disables the message input', (tester) async {
    final store = await _twoUserStore();
    addTearDown(store.dispose);
    final peer = _user(store, 'peer_one');
    store.conversationWith(peer.id);
    store.block(peer.id);

    await tester.pumpWidget(
        _app(store, ConversationScreen(otherUserId: peer.id)));
    await tester.pumpAndSettle();

    // No composer: the blocked notice + Unblock button replace it.
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.send), findsNothing);
    expect(find.widgetWithText(OutlinedButton, S.unblockUser),
        findsOneWidget);

    // Unblocking restores the input.
    await tester.tap(
        find.widgetWithText(OutlinedButton, S.unblockUser));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await store.flush();
  });

  testWidgets('conversation list empty state renders', (tester) async {
    final store = await _twoUserStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(_app(store, const ConversationsScreen()));
    await tester.pumpAndSettle();

    expect(find.text(S.messages), findsOneWidget);
    expect(find.text(S.noConversations), findsOneWidget);
    expect(find.text(S.messagesDemoNote), findsOneWidget);
    await store.flush();
  });
}
