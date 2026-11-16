import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/coach_api.dart';
import '../state/chat_state.dart';
import '../state/planner_state.dart';
import '../state/settings_state.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_widgets.dart';
import 'settings_screen.dart';

const List<String> _suggestions = [
  'How do I do a plank correctly?',
  'What are the best high-protein Filipino foods?',
  'Give me a dumbbell-only chest workout',
  'How do I train for my first 5k run?',
  'How do I get my first pull-up?',
];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// Builds the function that sends a conversation to the coach.
  Future<String> Function(List<ChatTurn>) _asker() {
    final settings = context.read<SettingsState>();
    final planner = context.read<PlannerState>();
    final system = buildCoachSystemPrompt(
      gear: settings.gear,
      days: planner.days,
    );
    return (turns) => askCoach(
          apiKey: settings.apiKey,
          model: settings.model,
          system: system,
          turns: turns,
        );
  }

  Future<void> _send(String text) async {
    final settings = context.read<SettingsState>();
    final chat = context.read<ChatState>();
    if (text.trim().isEmpty || chat.sending) return;
    if (settings.apiKey.trim().isEmpty) {
      showPixelSnack(context, 'Add your API key in Settings first.');
      return;
    }
    _input.clear();
    final future = chat.send(text, ask: _asker());
    _scrollToEnd();
    await future;
    _scrollToEnd();
  }

  Future<void> _retry() async {
    final chat = context.read<ChatState>();
    final future = chat.retry(ask: _asker());
    _scrollToEnd();
    await future;
    _scrollToEnd();
  }

  Future<void> _confirmClear() async {
    final chat = context.read<ChatState>();
    final ok = await showPixelConfirm(
      context,
      title: 'Clear chat?',
      message: 'This deletes your conversation with the coach.',
      confirmLabel: 'Clear',
    );
    if (ok) chat.clear();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatState>();
    final hasKey = context.watch<SettingsState>().apiKey.trim().isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('COACH', style: PX.title(18))),
                if (chat.messages.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear chat',
                    icon: const Icon(Icons.delete_outline, color: PX.ink),
                    onPressed: _confirmClear,
                  ),
              ],
            ),
            Text(
              'Ask anything about training, form, running or food.',
              style: PX.body(14, color: PX.grey),
            ),
            const SizedBox(height: 10),
            if (!hasKey) _keyCard(),
            Expanded(
              child: chat.messages.isEmpty ? _empty() : _messages(chat),
            ),
            if (chat.error != null) _errorCard(chat),
            const SizedBox(height: 6),
            _inputRow(chat),
          ],
        ),
      ),
    );
  }

  Widget _keyCard() {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 10),
      child: PixelCard(
        color: PX.yellow,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Add your API key in Settings to start chatting.',
                style: PX.body(14, weight: FontWeight.w700),
              ),
            ),
            PixelButton(
              label: 'Open',
              small: true,
              color: PX.white,
              onPressed: _openSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      children: [
        Text('TRY ASKING', style: PX.title(9, color: PX.grey)),
        const SizedBox(height: 12),
        for (final s in _suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12, right: 4),
            child: PixelCard(
              onTap: () => _send(s),
              child: SizedBox(
                width: double.infinity,
                child: Text(s, style: PX.body(15, weight: FontWeight.w700)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _messages(ChatState chat) {
    final width = MediaQuery.of(context).size.width * 0.82;
    final count = chat.messages.length + (chat.sending ? 1 : 0);
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      itemCount: count,
      itemBuilder: (context, i) {
        final typing = i >= chat.messages.length;
        final user = !typing && chat.messages[i].isUser;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 4),
          child: Align(
            alignment: user ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width),
              child: PixelCard(
                color: user ? PX.lime : PX.white,
                child: typing
                    ? Text('Coach is thinking...',
                        style: PX.body(15, color: PX.grey, weight: FontWeight.w600))
                    : SelectableText(
                        chat.messages[i].text,
                        style: PX.body(15),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _errorCard(ChatState chat) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, top: 4),
      child: PixelCard(
        color: PX.pink,
        child: Row(
          children: [
            Expanded(
              child: Text(
                chat.error ?? '',
                style: PX.body(14, weight: FontWeight.w700),
              ),
            ),
            PixelButton(
              label: 'Retry',
              small: true,
              color: PX.white,
              onPressed: _retry,
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputRow(ChatState chat) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _input,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: PX.body(16),
            decoration: pixelInputDecoration(hint: 'Ask your coach...'),
          ),
        ),
        const SizedBox(width: 10),
        PixelButton(
          label: '',
          icon: Icons.send,
          onPressed: chat.sending ? null : () => _send(_input.text),
        ),
      ],
    );
  }
}
