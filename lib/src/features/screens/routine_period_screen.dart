import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/text_utils.dart';
import '../../core/theme.dart';
import '../app_state.dart';
import '../widgets/common.dart';

class RoutinePeriodScreen extends StatelessWidget {
  const RoutinePeriodScreen({super.key, required this.period});

  final String period;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isAm = period == 'AM';
    final accent = isAm ? AppTheme.sage : AppTheme.blush;
    final steps = state.productsForPeriod(period);
    final completed = steps.where((p) => p.completed).length;
    final progress = steps.isEmpty ? 0.0 : completed / steps.length;

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
                  onTap: () => context.canPop() ? context.pop() : context.go('/'),
                ),
                const Spacer(),
                CircleIconButton(
                  icon: Icons.add,
                  background: AppTheme.charcoal,
                  foreground: Colors.white,
                  shadow: false,
                  onTap: () => context.go('/routine'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            SoftCard(
              color: accent,
              shadow: false,
              padding: const EdgeInsets.all(22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ProgressRing(
                    progress: progress,
                    size: 76,
                    strokeWidth: 6,
                    trackColor: Colors.black.withValues(alpha: 0.08),
                    color: AppTheme.charcoal,
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAm ? 'AM' : 'PM',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAm ? 'Morning ritual' : 'Evening ritual',
                          style: const TextStyle(
                            color: AppTheme.charcoal,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completed of ${steps.length} steps complete',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            const SectionLabel('Steps'),
            if (steps.isEmpty)
              SoftCard(
                color: Colors.white,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isAm ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
                      color: AppTheme.textSecondary,
                      size: 26,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No ${isAm ? "morning" : "evening"} steps yet.',
                      style: const TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add a product to start your ritual.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    PillButton(
                      label: 'Add product',
                      icon: Icons.add,
                      onPressed: () => context.go('/routine'),
                    ),
                  ],
                ),
              )
            else
              for (var i = 0; i < steps.length; i++) ...[
                _StepCard(
                  index: i + 1,
                  name: prettyProductName(steps[i].name),
                  completed: steps[i].completed,
                  accent: accent,
                  onTap: steps[i].completed
                      ? null
                      : () => state.completeStep(steps[i].id, period),
                  onOpen: () => context.push('/product/${steps[i].id}'),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.name,
    required this.completed,
    required this.accent,
    required this.onTap,
    required this.onOpen,
  });

  final int index;
  final String name;
  final bool completed;
  final Color accent;
  final VoidCallback? onTap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: completed ? AppTheme.charcoal : accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: completed
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : Text(
                              '$index',
                              style: const TextStyle(
                                color: AppTheme.charcoal,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: AppTheme.charcoal,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 16, 14),
              child: Icon(
                completed ? Icons.check_circle : Icons.arrow_forward,
                color: AppTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
