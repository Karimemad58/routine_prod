import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../app_state.dart';
import '../widgets/common.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  static const _suggestions = [
    "How's my routine?",
    'I have a pimple',
    'Ingredient check',
    "Today's tips",
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(BuildContext context, String message) async {
    if (message.trim().isEmpty) return;
    _controller.clear();
    await context.read<AppState>().sendMessage(message);
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isEmpty = state.chat.isEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0E8F5), Color(0xFFF0E8F5)],
                  ),
                  boxShadow: AppTheme.microShadow,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_awesome_outlined, size: 20, color: AppTheme.charcoal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI assistant',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      'Routine companion',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const CircleIconButton(
                icon: Icons.tune,
                shadow: false,
                background: AppTheme.softGray,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            children: [
              if (isEmpty) const _EmptyAssistantState(),
              for (final m in state.chat) _Bubble(role: m.role, text: m.content),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _suggestions)
                GestureDetector(
                  onTap: () => _send(context, s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.softGray,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: AppTheme.microShadow,
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: AppTheme.charcoal),
                    onSubmitted: (v) => _send(context, v),
                    decoration: const InputDecoration(
                      hintText: 'Ask about your skin…',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.mic_none_outlined, color: AppTheme.textSecondary),
                ),
                Material(
                  color: AppTheme.charcoal,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _send(context, _controller.text),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.role, required this.text});

  final String role;
  final String text;

  @override
  Widget build(BuildContext context) {
    final fromUser = role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!fromUser)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFE0E8F5), Color(0xFFF0E8F5)],
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.auto_awesome_outlined, size: 14, color: AppTheme.charcoal),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: fromUser ? AppTheme.charcoal : AppTheme.beige,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(fromUser ? 20 : 6),
                  bottomRight: Radius.circular(fromUser ? 6 : 20),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: fromUser ? Colors.white : AppTheme.charcoal,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAssistantState extends StatelessWidget {
  const _EmptyAssistantState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFE0E8F5), Color(0xFFF0E8F5)],
              ),
              boxShadow: AppTheme.softShadow,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.auto_awesome_outlined, color: AppTheme.charcoal),
          ),
          const SizedBox(height: 14),
          Text('How can I help today?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Ask about products, ingredients, or your scan results.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
