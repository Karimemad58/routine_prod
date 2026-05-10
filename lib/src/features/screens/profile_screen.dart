import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../app_state.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static String _skinSubtitle(AppState state) {
    final type = state.skinType;
    final sens = state.sensitivities.length;
    final goals = state.skinGoals.length;
    if (type.isEmpty && sens == 0 && goals == 0) {
      return 'Type, sensitivities, goals';
    }
    final parts = <String>[];
    if (type.isNotEmpty) parts.add(type[0].toUpperCase() + type.substring(1));
    if (sens > 0) parts.add('$sens sensitivit${sens == 1 ? "y" : "ies"}');
    if (goals > 0) parts.add('$goals goal${goals == 1 ? "" : "s"}');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.lavender,
              ),
              alignment: Alignment.center,
              child: Text(
                state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'R',
                style: const TextStyle(
                  color: AppTheme.charcoal,
                  fontSize: 22,
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
                    state.userName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    'Skin: ${profile['skin_type'] ?? 'Unknown'}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const CircleIconButton(
              icon: Icons.settings_outlined,
              shadow: false,
              background: AppTheme.softGray,
            ),
          ],
        ),
        const SizedBox(height: 22),

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
        SoftCard(
          color: AppTheme.softGray,
          shadow: false,
          onTap: () => context.go('/reminders'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReminderRow(
                icon: Icons.wb_sunny_outlined,
                label: 'Morning routine',
                value: profile['amReminder']?.toString() ?? '07:30',
              ),
              const Divider(height: 22, color: Color(0x14000000)),
              _ReminderRow(
                icon: Icons.nightlight_outlined,
                label: 'Evening routine',
                value: profile['pmReminder']?.toString() ?? '20:30',
              ),
              if (state.customReminders.isNotEmpty) ...[
                const Divider(height: 22, color: Color(0x14000000)),
                _ReminderRow(
                  icon: Icons.alarm_outlined,
                  label: 'Custom reminders',
                  value: '${state.customReminders.length}',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        PillButton(
          label: 'Manage reminders',
          icon: Icons.tune,
          background: Colors.white,
          foreground: AppTheme.charcoal,
          onPressed: () => context.go('/reminders'),
        ),
        const SizedBox(height: 26),

        const SectionLabel('Preferences'),
        _PreferenceTile(
          icon: Icons.spa_outlined,
          title: 'Skin profile',
          subtitle: _skinSubtitle(state),
          tint: AppTheme.sage,
          onTap: () => context.go('/settings/skin'),
        ),
        const SizedBox(height: 10),
        _PreferenceTile(
          icon: Icons.notifications_none_outlined,
          title: 'Notifications',
          subtitle: state.getNotifPref('enabled')
              ? 'Channels, quiet hours, streak nudges'
              : 'Paused — tap to re-enable',
          tint: AppTheme.peach,
          onTap: () => context.go('/settings/notifications'),
        ),
        const SizedBox(height: 10),
        const _PreferenceTile(
          icon: Icons.lock_outline,
          title: 'Privacy',
          subtitle: 'Data, sync, and exports',
          tint: AppTheme.lavender,
        ),
        const SizedBox(height: 26),

        if (state.userEmail != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Signed in as ${state.userEmail}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (state.isSignedIn)
          PillButton(
            label: 'Sign out',
            background: Colors.white,
            foreground: AppTheme.charcoal,
            onPressed: () => state.signOut(),
          )
        else if (state.isGuest && state.supabaseEnabled)
          PillButton(
            label: 'Sign in to sync',
            onPressed: () async {
              await state.signOut();
            },
          ),
      ],
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TintedIconBadge(icon: icon, tint: AppTheme.beige),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.charcoal,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      ],
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: Colors.white,
      shadow: false,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          TintedIconBadge(icon: icon, tint: tint),
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
