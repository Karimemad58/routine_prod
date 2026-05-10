import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/text_utils.dart';
import '../../core/theme.dart';
import '../app_state.dart';
import '../widgets/common.dart';
import 'routine_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.charcoal),
      );
    }

    final hour = DateTime.now().hour;
    final tod = hour < 12
        ? 'morning'
        : hour < 18
            ? 'afternoon'
            : 'evening';

    if (!state.hasAnyProducts) {
      return RefreshIndicator(
        color: AppTheme.charcoal,
        onRefresh: () => state.refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _Header(name: state.userName, partOfDay: tod),
            const SizedBox(height: 18),
            if (state.offline) const _OfflineBanner(),
            if (state.offline) const SizedBox(height: 16),
            _EmptyRoutineHero(
              onAdd: () => showAddProductSheet(context),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.charcoal,
      onRefresh: () => state.refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _Header(name: state.userName, partOfDay: tod),
          const SizedBox(height: 18),
          if (state.offline) const _OfflineBanner(),
          if (state.offline) const SizedBox(height: 16),
          const SectionLabel('Today'),
          WeekStrip(
            onDayTap: (date) {
              final today = DateTime.now();
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              if (isToday) {
                context.go('/routine');
              } else {
                final iso = '${date.year.toString().padLeft(4, '0')}-'
                    '${date.month.toString().padLeft(2, '0')}-'
                    '${date.day.toString().padLeft(2, '0')}';
                context.push('/history/$iso');
              }
            },
          ),
          const SizedBox(height: 24),
          _ScorePanel(
            score: state.dashboard.dailyScore,
            streak: state.dashboard.streakDays,
            amDone: state.amCompleted,
            amTotal: state.amRoutine.length,
            pmDone: state.pmCompleted,
            pmTotal: state.pmRoutine.length,
            onView: () => context.go('/routine'),
          ),
          const SizedBox(height: 28),
          const SectionLabel('Today\'s routine'),
          _RoutineTimeline(
            label: 'AM',
            color: AppTheme.sage,
            progress: state.amProgress,
            steps: state.amRoutine.map((p) => p.name).toList(),
            onTap: () => context.go('/routine/AM'),
          ),
          const SizedBox(height: 14),
          _RoutineTimeline(
            label: 'PM',
            color: AppTheme.blush,
            progress: state.pmProgress,
            steps: state.pmRoutine.map((p) => p.name).toList(),
            onTap: () => context.go('/routine/PM'),
          ),
          const SizedBox(height: 28),
          const SectionLabel('Categories'),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.95,
            children: [
              _CategoryCard(
                title: 'Skin',
                subtitle: '${state.dashboard.categories['skin'] ?? 0} products',
                tag: 'AM • PM',
                color: AppTheme.sage,
                icon: Icons.spa_outlined,
                onTap: () => context.go('/category/skin'),
              ),
              _CategoryCard(
                title: 'Hair',
                subtitle: '${state.dashboard.categories['hair'] ?? 0} products',
                tag: 'Weekly',
                color: AppTheme.blush,
                icon: Icons.cut_outlined,
                onTap: () => context.go('/category/hair'),
              ),
              _CategoryCard(
                title: 'Vitamins',
                subtitle: '${state.dashboard.categories['vitamin'] ?? 0} items',
                tag: 'AM',
                color: AppTheme.powder,
                icon: Icons.medication_outlined,
                onTap: () => context.go('/category/vitamin'),
              ),
              _CategoryCard(
                title: 'Medications',
                subtitle:
                    '${state.dashboard.categories['medication'] ?? 0} items',
                tag: 'PM',
                color: AppTheme.lavender,
                icon: Icons.local_pharmacy_outlined,
                onTap: () => context.go('/category/medication'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const SectionLabel('Streak & upcoming'),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  color: AppTheme.beige,
                  icon: Icons.local_fire_department_outlined,
                  label: 'Streak',
                  value: '${state.dashboard.streakDays}',
                  unit: 'days',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: _UpcomingTile(state: state)),
            ],
          ),
          const SizedBox(height: 28),
          SectionLabel(
            'Reminders',
            trailing: TextButton.icon(
              onPressed: () => context.go('/reminders'),
              icon: const Icon(Icons.tune, size: 14, color: AppTheme.charcoal),
              label: const Text(
                'Manage',
                style: TextStyle(color: AppTheme.charcoal, fontSize: 12),
              ),
            ),
          ),
          ..._buildReminderTiles(context, state),
          const SizedBox(height: 12),
          PillButton(
            label: state.customReminders.isEmpty
                ? 'Add a reminder'
                : 'Manage reminders',
            icon: state.customReminders.isEmpty ? Icons.add : Icons.tune,
            background: Colors.white,
            foreground: AppTheme.charcoal,
            onPressed: () => context.go('/reminders'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildReminderTiles(BuildContext context, AppState state) {
    final am = state.profile['amReminder']?.toString() ?? '07:30';
    final pm = state.profile['pmReminder']?.toString() ?? '20:30';

    final tiles = <Widget>[
      _ReminderTile(
        icon: Icons.wb_sunny_outlined,
        title: 'Morning routine',
        subtitle: '$am · ${state.amRoutine.length} steps',
        tone: AppTheme.softGray,
        onTap: () => context.go('/reminders'),
      ),
      const SizedBox(height: 10),
      _ReminderTile(
        icon: Icons.nightlight_outlined,
        title: 'Evening routine',
        subtitle: '$pm · ${state.pmRoutine.length} steps',
        tone: AppTheme.softGray,
        onTap: () => context.go('/reminders'),
      ),
    ];

    for (final r in state.customReminders.take(3)) {
      tiles.add(const SizedBox(height: 10));
      tiles.add(_CustomReminderRow(
        reminder: r,
        onTap: () => context.go('/reminders'),
      ));
    }

    return tiles;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.partOfDay});

  final String name;
  final String partOfDay;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.beige,
          ),
          alignment: Alignment.center,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'R',
            style: const TextStyle(
              color: AppTheme.charcoal,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good $partOfDay,',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        const CircleIconButton(
            icon: Icons.search, shadow: false, background: AppTheme.softGray),
        const SizedBox(width: 10),
        const CircleIconButton(
            icon: Icons.notifications_none_outlined,
            shadow: false,
            background: AppTheme.softGray),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: AppTheme.softGray,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shadow: false,
      child: Row(
        children: const [
          Icon(Icons.cloud_off_outlined,
              size: 18, color: AppTheme.textSecondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline preview · changes save locally',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({
    required this.score,
    required this.streak,
    required this.amDone,
    required this.amTotal,
    required this.pmDone,
    required this.pmTotal,
    required this.onView,
  });

  final int score;
  final int streak;
  final int amDone;
  final int amTotal;
  final int pmDone;
  final int pmTotal;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: AppTheme.charcoal,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OVERALL WELLNESS',
                      style: TextStyle(
                        color: Color(0xFFB5AFA8),
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'out of 100',
                      style: TextStyle(color: Color(0xFFB5AFA8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              ProgressRing(
                progress: score / 100,
                size: 96,
                strokeWidth: 7,
                child: const Icon(Icons.favorite_outline,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _MiniStat(label: 'AM', value: '$amDone/$amTotal')),
              const SizedBox(width: 10),
              Expanded(
                  child: _MiniStat(label: 'PM', value: '$pmDone/$pmTotal')),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(label: 'Streak', value: '${streak}d')),
            ],
          ),
          const SizedBox(height: 18),
          PillButton(
            label: 'View today\'s plan',
            icon: Icons.arrow_forward,
            background: Colors.white,
            foreground: AppTheme.charcoal,
            onPressed: onView,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFB5AFA8),
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineTimeline extends StatelessWidget {
  const _RoutineTimeline({
    required this.label,
    required this.color,
    required this.progress,
    required this.steps,
    this.onTap,
  });

  final String label;
  final Color color;
  final double progress;
  final List<String> steps;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: color,
      shadow: false,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProgressRing(
                progress: progress,
                size: 56,
                strokeWidth: 5,
                trackColor: Colors.black.withValues(alpha: 0.08),
                color: AppTheme.charcoal,
                child: Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: AppTheme.charcoal,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$label routine',
                      style: const TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${steps.length} steps',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              CircleIconButton(
                icon: Icons.arrow_forward,
                size: 36,
                shadow: false,
                background: Colors.white,
                onTap: onTap,
              ),
            ],
          ),
          if (steps.isNotEmpty) const SizedBox(height: 14),
          if (steps.isNotEmpty)
            Builder(builder: (context) {
              const maxVisible = 4;
              final visible = steps.take(maxVisible).toList();
              final overflow = steps.length - visible.length;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final step in visible)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        prettyProductName(step, maxLength: 22),
                        style: const TextStyle(
                          color: AppTheme.charcoal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (overflow > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.charcoal,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        '+$overflow more',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String tag;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: color,
      shadow: false,
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TintedIconBadge(icon: icon, tint: color),
              const Spacer(),
              CircleIconButton(
                icon: Icons.arrow_forward,
                size: 32,
                background: Colors.white,
                onTap: onTap,
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: AppTheme.charcoal,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.charcoal,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: color,
      shadow: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TintedIconBadge(icon: icon, tint: color, size: 36),
          const SizedBox(height: 14),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.charcoal,
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: tone,
      shadow: false,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          TintedIconBadge(icon: icon, tint: tone, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.charcoal,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

class _CustomReminderRow extends StatelessWidget {
  const _CustomReminderRow({required this.reminder, required this.onTap});

  final Map<String, dynamic> reminder;
  final VoidCallback onTap;

  IconData _iconFor(String? key) {
    switch (key) {
      case 'spa':
        return Icons.spa_outlined;
      case 'hair':
        return Icons.cut_outlined;
      case 'water':
        return Icons.water_drop_outlined;
      case 'supplement':
        return Icons.medication_liquid_outlined;
      case 'sun':
        return Icons.wb_sunny_outlined;
      case 'moon':
        return Icons.nightlight_outlined;
      default:
        return Icons.medication_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ReminderTile(
      icon: _iconFor(reminder['icon']?.toString()),
      title: reminder['label']?.toString() ?? 'Reminder',
      subtitle: 'Daily · ${reminder['time'] ?? ''}',
      tone: AppTheme.softGray,
      onTap: onTap,
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final next = state.nextUpcomingStep;
    final period = state.nextUpcomingPeriod;

    String value;
    String unit;
    if (next == null) {
      // Fall back to the closest custom reminder if any.
      final reminder =
          state.customReminders.isNotEmpty ? state.customReminders.first : null;
      if (reminder != null) {
        value = reminder['label']?.toString() ?? 'Reminder';
        unit = 'at ${reminder['time'] ?? ''}';
      } else {
        value = 'All clear';
        unit = 'no upcoming step';
      }
    } else {
      value = prettyProductName(next.name, maxLength: 22);
      unit = period == 'AM' ? 'in your AM routine' : 'in your PM routine';
    }

    return _StatTile(
      color: AppTheme.peach,
      icon: Icons.calendar_today_outlined,
      label: 'Upcoming',
      value: value,
      unit: unit,
    );
  }
}

class _EmptyRoutineHero extends StatelessWidget {
  const _EmptyRoutineHero({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        SoftCard(
          color: AppTheme.charcoal,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.spa_outlined,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(height: 18),
              const Text(
                'Build your\ndaily ritual.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  height: 1.05,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Add the products you use and we will build your morning and evening routine, track streaks, and warn about ingredient conflicts.',
                style: TextStyle(
                  color: Color(0xFFB5AFA8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              PillButton(
                label: 'Add your first product',
                icon: Icons.add,
                background: Colors.white,
                foreground: AppTheme.charcoal,
                onPressed: onAdd,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StarterTip(
                icon: Icons.spa_outlined,
                label: 'Skin',
                tone: AppTheme.sage,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StarterTip(
                icon: Icons.cut_outlined,
                label: 'Hair',
                tone: AppTheme.blush,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StarterTip(
                icon: Icons.medication_outlined,
                label: 'Vitamins',
                tone: AppTheme.powder,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StarterTip(
                icon: Icons.local_pharmacy_outlined,
                label: 'Meds',
                tone: AppTheme.lavender,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Add your products to your routine to start.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _StarterTip extends StatelessWidget {
  const _StarterTip(
      {required this.icon, required this.label, required this.tone});

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.charcoal, size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.charcoal,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
