import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/coach_api.dart';

class ChatMessage {
  ChatMessage({required this.role, required this.text});

  /// 'user' or 'assistant'.
  final String role;
  final String text;

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() => {'role': role, 'text': text};

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: (json['role'] as String?) == 'user' ? 'user' : 'assistant',
        text: (json['text'] as String?) ?? '',
      );
}

/// The conversation with the coach. The last messages are kept on the phone.
class ChatState extends ChangeNotifier {
  ChatState({this.persist = true});

  static const String _storageKey = 'mm_chat_v1';
  static const int _keep = 60; // messages saved
  static const int _sendCount = 20; // messages sent with each question

  final bool persist;
  bool loaded = false;

  final List<ChatMessage> messages = [];

  bool sending = false;

  /// Shown under the chat after a failed question.
  String? error;

  Future<void> _pending = Future<void>.value();

  /// Completes when the latest save has finished (handy in tests).
  Future<void> flush() => _pending;

  Future<void> load() async {
    if (persist) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_storageKey);
        if (raw != null) {
          final list = jsonDecode(raw) as List;
          for (final m in list) {
            messages.add(
              ChatMessage.fromJson(Map<String, dynamic>.from(m as Map)),
            );
          }
        }
      } catch (_) {
        // Unreadable saved chat: start empty.
      }
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    if (!persist) return;
    try {
      final start = messages.length > _keep ? messages.length - _keep : 0;
      final json = jsonEncode(
        messages.skip(start).map((m) => m.toJson()).toList(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json);
    } catch (_) {
      // Best effort.
    }
  }

  void _changed() {
    notifyListeners();
    _pending = _save();
  }

  /// Adds the question and asks the coach. [ask] does the actual request, so
  /// the screen decides which key and model to use.
  Future<void> send(
    String text, {
    required Future<String> Function(List<ChatTurn> turns) ask,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty || sending) return;
    messages.add(ChatMessage(role: 'user', text: clean));
    await _run(ask);
  }

  /// Asks again after an error, without adding the question a second time.
  Future<void> retry({
    required Future<String> Function(List<ChatTurn> turns) ask,
  }) async {
    if (sending || messages.isEmpty || !messages.last.isUser) return;
    await _run(ask);
  }

  Future<void> _run(
    Future<String> Function(List<ChatTurn> turns) ask,
  ) async {
    error = null;
    sending = true;
    notifyListeners();

    try {
      final start =
          messages.length > _sendCount ? messages.length - _sendCount : 0;
      final turns = messages
          .skip(start)
          .map((m) => ChatTurn(m.role, m.text))
          .toList();
      final reply = await ask(turns);
      messages.add(ChatMessage(role: 'assistant', text: reply));
    } on CoachException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Something went wrong. Try again.';
    }

    sending = false;
    _changed();
  }

  void clear() {
    messages.clear();
    error = null;
    _changed();
  }
}
