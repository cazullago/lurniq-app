import 'package:flutter/material.dart';

/// CONTRACT (foundation): the messages feature owner implements the body of
/// this screen. Constructor signature must stay stable — the Profile tab
/// navigates here.
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Implemented by the messaging feature owner.
    return const Scaffold(
      body: Center(child: Text('Messages')),
    );
  }
}
