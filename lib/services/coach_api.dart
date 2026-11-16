import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/log_models.dart';
import '../models/models.dart';

/// An error with a message that is safe to show to the person.
class CoachException implements Exception {
  CoachException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One message in the conversation. [role] is 'user' or 'assistant'.
class ChatTurn {
  const ChatTurn(this.role, this.text);

  final String role;
  final String text;
}

/// Prepares the messages for the API: empty ones are dropped, neighbours with
/// the same role are merged, and the first message is always the user's.
List<Map<String, String>> buildApiMessages(List<ChatTurn> turns) {
  final out = <Map<String, String>>[];
  for (final t in turns) {
    final text = t.text.trim();
    if (text.isEmpty) continue;
    if (out.isEmpty && t.role != 'user') continue;
    if (out.isNotEmpty && out.last['role'] == t.role) {
      out.last['content'] = '${out.last['content']}\n\n$text';
    } else {
      out.add({'role': t.role, 'content': text});
    }
  }
  return out;
}

/// The coach's instructions, plus what it needs to know about you.
String buildCoachSystemPrompt({
  required Set<Equip> gear,
  required List<DayPlan> days,
}) {
  final owned = gear
      .where((g) => g != Equip.bodyweight)
      .map((g) => kEquipLabel[g] ?? g.name)
      .toList();

  final plan = StringBuffer();
  for (var i = 0; i < 7 && i < days.length; i++) {
    final d = days[i];
    final parts = <String>[];
    if (d.title.isNotEmpty) parts.add(d.title);
    if (d.exercises.isNotEmpty) {
      parts.add(d.exercises.map((e) => e.name).join(', '));
    }
    if (d.hasRun) parts.add('run ${fmtNum(d.runKm)} km');
    plan.writeln(
      '${kDayNames[i]}: ${parts.isEmpty ? 'nothing planned' : parts.join(' | ')}',
    );
  }

  return '''
You are Coach MM, the friendly fitness coach inside the Muscle Memory app.

You help with everything fitness related: exercise technique and form cues, building and adjusting workout plans, home and dumbbell-only training, bodyweight skills such as pull-ups and push-ups, running and endurance, stretching and mobility, recovery and sleep, motivation and habits, and nutrition (meal ideas, calories, protein, supplements in general). When you suggest food, prefer foods that are easy to find in the Philippines and keep it affordable. Calorie and protein numbers are estimates, so say so.

If a question is not about fitness, health, food or training, say in one short sentence that you only help with fitness, then offer a fitness angle.

Style rules:
- Plain text only. Do not use markdown symbols such as asterisks or # headings.
- Keep answers practical and short, about 120 words unless the person asks for more detail.
- For how-to questions, give numbered steps with the most important form cues.
- Reply in the same language the person writes in (English, Filipino or Taglish).
- You are not a doctor. For pain, injuries, medical conditions or pregnancy, give general safe advice and suggest seeing a doctor or physiotherapist.

About this person:
Equipment they own: ${owned.isEmpty ? 'bodyweight only' : '${owned.join(', ')} (plus bodyweight)'}.
Prefer exercises they can do with that equipment, and say so when something needs a gym.
Their weekly plan in the app:
$plan''';
}

/// Sends the conversation to the Anthropic Messages API and returns the reply.
/// Throws a [CoachException] with a readable message when something fails.
Future<String> askCoach({
  required String apiKey,
  required String model,
  required String system,
  required List<ChatTurn> turns,
  http.Client? client,
}) async {
  if (apiKey.trim().isEmpty) {
    throw CoachException('Add your API key in Settings first.');
  }
  final messages = buildApiMessages(turns);
  if (messages.isEmpty) {
    throw CoachException('There is nothing to send yet.');
  }

  final c = client ?? http.Client();
  try {
    final response = await c
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'x-api-key': apiKey.trim(),
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'model': model.trim(),
            'max_tokens': 800,
            'system': system,
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 60));

    // Decode the bytes as UTF-8 ourselves so accents and emoji survive.
    final text = utf8.decode(response.bodyBytes);
    Map<String, dynamic> data;
    try {
      data = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      data = <String, dynamic>{};
    }

    if (response.statusCode == 200) {
      final content = data['content'];
      final out = StringBuffer();
      if (content is List) {
        for (final block in content) {
          if (block is Map && block['type'] == 'text') {
            out.write(block['text'] ?? '');
          }
        }
      }
      final reply = out.toString().trim();
      if (reply.isEmpty) {
        throw CoachException('The coach sent an empty answer. Try again.');
      }
      return reply;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw CoachException('The API key was rejected. Check it in Settings.');
    }
    if (response.statusCode == 429) {
      throw CoachException(
        'Too many requests, or the account is out of credit. Try again soon.',
      );
    }
    final error = data['error'];
    final detail = error is Map ? (error['message'] ?? '') : '';
    throw CoachException(
      'The coach could not answer (error ${response.statusCode}). $detail'
          .trim(),
    );
  } on CoachException {
    rethrow;
  } on TimeoutException {
    throw CoachException('The coach took too long. Try again.');
  } catch (_) {
    throw CoachException('Could not reach the coach. Check your internet.');
  } finally {
    if (client == null) c.close();
  }
}
