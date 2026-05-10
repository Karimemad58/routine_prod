import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/text_utils.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../app_state.dart';
import '../widgets/common.dart';

/// Read-only view of which routine steps were completed on a given date.
/// Reachable from the WeekStrip on the home screen.
class RoutineHistoryScreen extends StatefulWidget {
  const RoutineHistoryScreen({super.key, required this.date});

  /// Date in `yyyy-MM-dd` format.
  final String date;

  @override
  State<RoutineHistoryScreen> createState() => _RoutineHistoryScreenState();
}

class _RoutineHistoryScreenState extends State<RoutineHistoryScreen> {
  Set<String> _completions = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final result = await state.completionsForDate(widget.date);
    if (!mounted) return;
    setState(() {
      _completions = result;
      _loading = false;
    });
  }

  DateTime get _parsedDate {
    final parts = widget.date.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    return DateTime.now();
  }

  String get _formatted {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final d = _parsedDate;
    final wd = weekdays[(d.weekday - 1) % 7];
    final mo = months[(d.month - 1) % 12];
    return '$wd, $mo ${d.day}';
  }

  bool _isCompleted(ProductData p, String period) =>
      _completions.contains('${p.id}|$period');

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final am = state.products
        .where((p) => p.timeOfDay == 'AM' || p.timeOfDay == 'both')
        .toList();
    final pm = state.products
        .where((p) => p.timeOfDay == 'PM' || p.timeOfDay == 'both')
        .toList();
    final amDone = am.where((p) => _isCompleted(p, 'AM')).length;
    final pmDone = pm.where((p) => _isCompleted(p, 'PM')).length;
    final total = am.length + pm.length;
    final done = amDone + pmDone;

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
                      context.canPop() ? context.pop() : context.go('/'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _formatted,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              total == 0
                  ? 'No routine on this day yet.'
                  : '$done of $total steps completed',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 22),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.charcoal),
                ),
              )
            else ...[
              _HistoryBlock(
                label: 'Morning',
                accent: AppTheme.sage,
                steps: am,
                completed:
                    am.map((p) => _isCompleted(p, 'AM')).toList(),
              ),
              const SizedBox(height: 18),
              _HistoryBlock(
                label: 'Evening',
                accent: AppTheme.blush,
                steps: pm,
                completed:
                    pm.map((p) => _isCompleted(p, 'PM')).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryBlock extends StatelessWidget {
  const _HistoryBlock({
    required this.label,
    required this.accent,
    required this.steps,
    required this.completed,
  });

  final String label;
  final Color accent;
  final List<ProductData> steps;
  final List<bool> completed;

  @override
  Widget build(BuildContext context) {
    final done = completed.where((c) => c).length;
    return SoftCard(
      color: accent,
      shadow: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$label routine',
                  style: const TextStyle(
                    color: AppTheme.charcoal,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  '$done/${steps.length}',
                  style: const TextStyle(
                    color: AppTheme.charcoal,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (steps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'No products in this routine.',
                style:
                    TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SoftCard(
                  color: Colors.white.withValues(alpha: 0.55),
                  shadow: false,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: completed[i]
                              ? AppTheme.charcoal
                              : Colors.transparent,
                          border: Border.all(
                            color: completed[i]
                                ? AppTheme.charcoal
                                : AppTheme.textMuted
                                    .withValues(alpha: 0.6),
                            width: 1.4,
                          ),
                        ),
                        child: completed[i]
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          prettyProductName(steps[i].name),
                          style: TextStyle(
                            color: AppTheme.charcoal,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: completed[i]
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
          ],
        ],
      ),
    );
  }
}
