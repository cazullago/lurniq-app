import 'dart:convert';
import 'dart:io';

import '../store/app_store.dart';

/// AI help for tasks and lessons.
///
/// Demo mode (no API key): template-based study guidance that is always
/// labeled as demo — it never pretends to be a live AI answer. Real mode
/// (key set in Settings): calls the Gemini OpenAI-compatible endpoint with
/// dart:io HttpClient (no extra pubspec dependencies). The key is passed
/// only in the Authorization header; it is never logged or persisted here.
class AiService {
  static Future<String> ask(
    AppStore store,
    String prompt, {
    String? context,
  }) async {
    final p = prompt.trim();
    if (p.isEmpty) return _demoGuidance('your task', context);
    final key = store.aiApiKey;
    if (key == null || key.isEmpty) {
      return _demoGuidance(p, context);
    }
    try {
      return await _gemini(key, p, context);
    } catch (_) {
      return 'The AI could not be reached right now. '
          'Check your connection and your API key in Settings, then try again.';
    }
  }

  // ── Demo mode ──────────────────────────────────────────

  /// Practical, template-based guidance. Clearly marked as demo and
  /// personalized with the task/lesson the user asked about.
  static String _demoGuidance(String prompt, String? context) {
    final ctx = (context ?? '').trim();
    final buf = StringBuffer()
      ..writeln('🧪 Demo AI — guided, template-based help.')
      ..writeln('Add your own API key in Settings for full AI answers.')
      ..writeln();
    if (ctx.isNotEmpty) {
      buf
        ..writeln('Concept: $ctx')
        ..writeln()
        ..writeln('A practical way to master it:')
        ..writeln('1. Read your lesson notes once, slowly — don\'t rush.')
        ..writeln(
            '2. Close the notes and explain the idea out loud in your own words.')
        ..writeln(
            '3. Write down 2–3 questions the idea answers, and 1 it doesn\'t.')
        ..writeln(
            '4. Test yourself tomorrow from memory, not from the page.');
    } else {
      buf
        ..writeln('A practical way to tackle: "$prompt"')
        ..writeln()
        ..writeln('1. Restate the goal in one sentence in your own words.')
        ..writeln(
            '2. Split it into the smallest steps you can — each under 25 minutes.')
        ..writeln('3. Do the hardest step first, while your focus is fresh.')
        ..writeln(
            '4. After each step, write one line about what you learned.')
        ..writeln('5. Finish by reviewing: what would you do differently?');
    }
    buf
      ..writeln()
      ..writeln('Your question: "$prompt"');
    return buf.toString();
  }

  // ── Real mode ──────────────────────────────────────────

  static Future<String> _gemini(
      String key, String prompt, String? context) async {
    final client = HttpClient();
    try {
      final full = context == null || context.trim().isEmpty
          ? prompt
          : 'Context:\n${context.trim()}\n\nQuestion:\n$prompt';
      final req = await client.postUrl(Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions'));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $key');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'model': 'gemini-2.0-flash',
        'messages': [
          {'role': 'user', 'content': full}
        ],
      }));
      final res = await req.close().timeout(const Duration(seconds: 30));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return 'The AI returned an error (status ${res.statusCode}). '
            'Check your API key in Settings and try again.';
      }
      final data = jsonDecode(body);
      final answer = _extractContent(data);
      if (answer == null || answer.isEmpty) {
        return 'The AI sent back an empty answer. Try rephrasing your question.';
      }
      return answer;
    } finally {
      client.close(force: true);
    }
  }

  static String? _extractContent(dynamic data) {
    if (data is! Map) return null;
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final message = first['message'];
    if (message is! Map) return null;
    return message['content']?.toString().trim();
  }
}
