import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../app_state.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _initialized = false;

  bool _enabled = true;
  bool _am = true;
  bool _pm = true;
  bool _customs = true;
  bool _streak = true;
  bool _quiet = false;
  String _quietStart = '22:00';
  String _quietEnd = '07:00';

  void _hydrate(AppState state) {
    if (_initialized) return;
    _enabled = state.getNotifPref('enabled');
    _am = state.getNotifPref('am');
    _pm = state.getNotifPref('pm');
    _customs = state.getNotifPref('customs');
    _streak = state.getNotifPref('streak');
    _quiet = state.getNotifPref('quiet', defaultValue: false);
    _quietStart = state.getNotifPrefString('quietStart', defaultValue: '22:00');
    _quietEnd = state.getNotifPrefString('quietEnd', defaultValue: '07:00');
    _initialized = true;
  }

  Future<void> _persist({
    bool? enabled,
    bool? am,
    bool? pm,
    bool? customs,
    bool? streak,
    bool? quiet,
    String? quietStart,
    String? quietEnd,
  }) async {
    final state = context.read<AppState>();
    await state.updateNotificationPrefs({
      if (enabled != null) 'enabled': enabled,
      if (am != null) 'am': am,
      if (pm != null) 'pm': pm,
      if (customs != null) 'customs': customs,
      if (streak != null) 'streak': streak,
      if (quiet != null) 'quiet': quiet,
      if (quietStart != null) 'quietStart': quietStart,
      if (quietEnd != null) 'quietEnd': quietEnd,
    });
  }

  Future<String?> _pickTime(String current) async {
    TimeOfDay initial = const TimeOfDay(hour: 22, minute: 0);
    final parts = current.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) initial = TimeOfDay(hour: h, minute: m);
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
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
              ],
            ),
            const SizedBox(height: 18),

            SoftCard(
              color: AppTheme.peach,
              shadow: false,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TintedIconBadge(
                    icon: Icons.notifications_none_outlined,
                    tint: AppTheme.peach,
                    size: 48,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose how Routine nudges you. Daily reminders use the times you set in Reminders.',
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

            const SectionLabel('Channels'),
            _ToggleCard(
              icon: Icons.notifications_active_outlined,
              tone: AppTheme.softGray,
              title: 'All notifications',
              subtitle:
                  'Master switch — turn this off to silence everything below.',
              value: _enabled,
              onChanged: (v) {
                setState(() => _enabled = v);
                _persist(enabled: v);
              },
            ),
            const SizedBox(height: 10),
            _ToggleCard(
              icon: Icons.wb_sunny_outlined,
              tone: AppTheme.peach,
              title: 'Morning routine',
              subtitle: 'Daily at ${state.profile['amReminder'] ?? '07:30'}',
              value: _am && _enabled,
              enabled: _enabled,
              onChanged: (v) {
                setState(() => _am = v);
                _persist(am: v);
              },
            ),
            const SizedBox(height: 10),
            _ToggleCard(
              icon: Icons.nightlight_outlined,
              tone: AppTheme.lavender,
              title: 'Evening routine',
              subtitle: 'Daily at ${state.profile['pmReminder'] ?? '20:30'}',
              value: _pm && _enabled,
              enabled: _enabled,
              onChanged: (v) {
                setState(() => _pm = v);
                _persist(pm: v);
              },
            ),
            const SizedBox(height: 10),
            _ToggleCard(
              icon: Icons.alarm_outlined,
              tone: AppTheme.sage,
              title: 'Custom reminders',
              subtitle:
                  '${state.customReminders.length} configured',
              value: _customs && _enabled,
              enabled: _enabled,
              onChanged: (v) {
                setState(() => _customs = v);
                _persist(customs: v);
              },
            ),
            const SizedBox(height: 10),
            _ToggleCard(
              icon: Icons.local_fire_department_outlined,
              tone: AppTheme.beige,
              title: 'Streak nudges',
              subtitle: 'A gentle ping if you skip a day.',
              value: _streak && _enabled,
              enabled: _enabled,
              onChanged: (v) {
                setState(() => _streak = v);
                _persist(streak: v);
              },
            ),
            const SizedBox(height: 26),

            const SectionLabel('Quiet hours'),
            _ToggleCard(
              icon: Icons.bedtime_outlined,
              tone: AppTheme.powder,
              title: 'Pause notifications overnight',
              subtitle:
                  'Skip pings between $_quietStart and $_quietEnd.',
              value: _quiet && _enabled,
              enabled: _enabled,
              onChanged: (v) {
                setState(() => _quiet = v);
                _persist(quiet: v);
              },
            ),
            if (_quiet) ...[
              const SizedBox(height: 12),
              SoftCard(
                color: Colors.white,
                shadow: false,
                child: Column(
                  children: [
                    _TimeFieldRow(
                      label: 'Quiet starts',
                      value: _quietStart,
                      onTap: () async {
                        final picked = await _pickTime(_quietStart);
                        if (picked != null) {
                          setState(() => _quietStart = picked);
                          _persist(quietStart: picked);
                        }
                      },
                    ),
                    const Divider(height: 22, color: Color(0x14000000)),
                    _TimeFieldRow(
                      label: 'Quiet ends',
                      value: _quietEnd,
                      onTap: () async {
                        final picked = await _pickTime(_quietEnd);
                        if (picked != null) {
                          setState(() => _quietEnd = picked);
                          _persist(quietEnd: picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 26),

            PillButton(
              label: 'Manage reminder times',
              icon: Icons.tune,
              background: Colors.white,
              foreground: AppTheme.charcoal,
              onPressed: () => context.go('/reminders'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: SoftCard(
        color: Colors.white,
        shadow: false,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: AppTheme.charcoal,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeFieldRow extends StatelessWidget {
  const _TimeFieldRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.access_time,
                size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.charcoal,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
