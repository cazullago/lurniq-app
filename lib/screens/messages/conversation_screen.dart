import 'package:flutter/material.dart';

/// CONTRACT (foundation): the messages feature owner implements the body of
/// this screen. Constructor signature must stay stable — profile screens
/// navigate here via `ConversationScreen(otherUserId: ...)`.
class ConversationScreen extends StatelessWidget {
  const ConversationScreen({super.key, required this.otherUserId});

  final String otherUserId;

  @override
  Widget build(BuildContext context) {
    // Implemented by the messaging feature owner.
    return const Scaffold(
      body: Center(child: Text('Conversation')),
    );
  }
}
