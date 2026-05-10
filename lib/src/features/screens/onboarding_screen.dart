import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../app_state.dart';
import '../widgets/common.dart';

/// One-shot welcome flow shown after sign-in if the user hasn't filled in any
/// part of their skin profile yet. They can answer a few quick questions or
/// skip and configure later in settings.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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
  final Set<String> _sensitivities = {};
  final Set<String> _goals = {};
  bool _saving = false;
  bool _skipping = false;

  @override
  void initState() {
    super.initState();
    // Mark onboarding seen immediately so the user is never redirected here
    // again — even if they background the app or sign out before saving.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().markOnboardingComplete();
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    await state.updateSkinProfile(
      skinType: _skinType,
      sensitivities: _sensitivities.toList(),
      goals: _goals.toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/');
  }

  Future<void> _skip() async {
    if (_skipping) return;
    setState(() => _skipping = true);
    await context.read<AppState>().markOnboardingComplete();
    if (!mounted) return;
    setState(() => _skipping = false);
    context.go('/');
  }

  bool get _hasAnything =>
      _skinType.isNotEmpty || _sensitivities.isNotEmpty || _goals.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: _skipping ? null : _skip,
                  child: Text(
                    _skipping ? 'Skipping…' : 'Skip',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
                    'Welcome.\nLet\'s tune Routine to your skin.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A few quick questions help us flag conflicts and tailor product warnings. You can change everything later in Settings.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionLabel('Your skin type'),
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
                        if (!_sensitivities.add(s)) _sensitivities.remove(s);
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionLabel('Your goals'),
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
            const SizedBox(height: 26),
            PillButton(
              label: _saving
                  ? 'Saving…'
                  : (_hasAnything ? 'Save and continue' : 'Continue'),
              icon: _saving ? null : Icons.arrow_forward,
              onPressed: _hasAnything ? _save : _skip,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _skipping ? null : _skip,
                child: const Text(
                  'I\'ll do this later',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
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
