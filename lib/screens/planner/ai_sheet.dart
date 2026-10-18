import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ai_service.dart';
import '../../core/strings.dart';
import '../../store/app_store.dart';

/// "Ask AI" bottom sheet used by task detail and lesson detail.
///
/// Shows the "Demo AI" badge and [S.aiDemoNote] when no API key is set so
/// demo output is never presented as real AI. Sends the prompt through
/// [AiService] and renders the answer.
class AiSheet {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String contextText,
    String initialPrompt = '',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AiSheet(
        title: title,
        contextText: contextText,
        initialPrompt: initialPrompt,
      ),
    );
  }
}

class _AiSheet extends StatefulWidget {
  const _AiSheet({
    required this.title,
    required this.contextText,
    required this.initialPrompt,
  });

  final String title;
  final String contextText;
  final String initialPrompt;

  @override
  State<_AiSheet> createState() => _AiSheetState();
}

class _AiSheetState extends State<_AiSheet> {
  late final TextEditingController _prompt;
  String? _answer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _prompt = TextEditingController(text: widget.initialPrompt);
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final q = _prompt.text.trim();
    if (q.isEmpty || _busy) return;
    final store = context.read<AppStore>();
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _answer = null;
    });
    final answer =
        await AiService.ask(store, q, context: widget.contextText);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _answer = answer;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final isDemo = store.aiApiKey == null || store.aiApiKey!.isEmpty;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                  ),
                  if (isDemo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.science_outlined,
                              size: 14,
                              color: scheme.onTertiaryContainer),
                          const SizedBox(width: 4),
                          Text(S.aiDemoBadge,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: scheme.onTertiaryContainer,
                              )),
                        ],
                      ),
                    ),
                ],
              ),
              if (isDemo) ...[
                const SizedBox(height: 8),
                Text(S.aiDemoNote,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _prompt,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: S.aiPlaceholder,
                  alignLabelWithHint: true,
                ),
                onSubmitted: (_) => _send(),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _busy ? null : _send,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_busy ? S.aiThinking : S.askAi),
              ),
              if (_answer != null) ...[
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 320),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _answer!,
                      style:
                          Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
