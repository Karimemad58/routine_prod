import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../app_state.dart';
import '../widgets/common.dart';

class SkinProfileScreen extends StatefulWidget {
  const SkinProfileScreen({super.key});

  @override
  State<SkinProfileScreen> createState() => _SkinProfileScreenState();
}

class _SkinProfileScreenState extends State<SkinProfileScreen> {
  static const _skinTypes = [
    'oily',
    'dry',
    'combination',
    'sensitive',
    'normal',
  ];

  static const _sensitivityChoices = [
    'fragrance',
    'alcohol',
    'essential oils',
    'sulfates',
    'silicones',
    'retinol',
    'acids',
    'nuts',
  ];

  static const _goalChoices = [
    'hydration',
    'anti-aging',
    'brightening',
    'pore care',
    'acne control',
    'redness',
    'hyperpigmentation',
    'barrier repair',
  ];

  String _skinType = '';
  Set<String> _sensitivities = {};
  Set<String> _goals = {};
  final _notes = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  void _hydrate(AppState state) {
    if (_initialized) return;
    _skinType = state.skinType;
    _sensitivities = state.sensitivities.toSet();
    _goals = state.skinGoals.toSet();
    _notes.text = state.skinNotes;
    _initialized = true;
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    await state.updateSkinProfile(
      skinType: _skinType,
      sensitivities: _sensitivities.toList(),
      goals: _goals.toList(),
      notes: _notes.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Skin profile saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    _hydrate(state);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                CircleIconButton(
                  icon: Icons.arrow_back,
                  background: AppTheme.softGray,
                  shadow: false,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/profile'),
                ),
                const Spacer(),
                if (state.isSignedIn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.softGray,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done_outlined,
                            size: 12, color: AppTheme.textSecondary),
                        SizedBox(width: 6),
                        Text(
                          'Synced',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            SoftCard(
              color: AppTheme.sage,
              shadow: false,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TintedIconBadge(
                    icon: Icons.spa_outlined,
                    tint: AppTheme.sage,
                    size: 48,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Skin profile',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tell the assistant about your skin so it tailors product warnings and routine suggestions.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            const SectionLabel('Skin type'),
            SoftCard(
              color: Colors.white,
              shadow: false,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in _skinTypes)
                    _ChipChoice(
                      label: t,
                      selected: _skinType == t,
                      onTap: () => setState(
                        () => _skinType = _skinType == t ? '' : t,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            const SectionLabel('Sensitivities'),
            SoftCard(
              color: Colors.white,
              shadow: false,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _sensitivityChoices)
                    _ChipChoice(
                      label: s,
                      selected: _sensitivities.contains(s),
                      onTap: () => setState(() {
                        if (!_sensitivities.add(s)) {
                          _sensitivities.remove(s);
                        }
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            const SectionLabel('Goals'),
            SoftCard(
              color: Colors.white,
              shadow: false,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in _goalChoices)
                    _ChipChoice(
                      label: g,
                      selected: _goals.contains(g),
                      onTap: () => setState(() {
                        if (!_goals.add(g)) _goals.remove(g);
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            const SectionLabel('Notes'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: TextField(
                controller: _notes,
                minLines: 3,
                maxLines: 6,
                style: const TextStyle(
                  color: AppTheme.charcoal,
                  fontSize: 14,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText:
                      'Anything else? Allergies, derm advice, products that worked, products that didn\'t…',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 22),

            PillButton(
              label: _saving ? 'Saving…' : 'Save skin profile',
              icon: _saving ? null : Icons.check,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipChoice extends StatelessWidget {
  const _ChipChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.charcoal : AppTheme.softGray,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.check, size: 13, color: Colors.white),
              ),
            Text(
              label[0].toUpperCase() + label.substring(1),
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.charcoal,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
