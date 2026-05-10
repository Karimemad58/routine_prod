import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../app_state.dart';
import '../widgets/common.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _amCtrl = TextEditingController();
  final _pmCtrl = TextEditingController();
  bool _initialized = false;

  void _hydrate(AppState state) {
    if (_initialized) return;
    _amCtrl.text = state.profile['amReminder']?.toString() ?? '07:30';
    _pmCtrl.text = state.profile['pmReminder']?.toString() ?? '20:30';
    _initialized = true;
  }

  @override
  void dispose() {
    _amCtrl.dispose();
    _pmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    _hydrate(state);
    final customs = state.customReminders;

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
                  onTap: () => _openAddSheet(context, state),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Reminders',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Set when you want gentle nudges for your routine and any custom tasks.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),

            const SectionLabel('Routine reminders'),
            SoftCard(
              color: AppTheme.softGray,
              shadow: false,
              child: Column(
                children: [
                  _TimeRow(
                    icon: Icons.wb_sunny_outlined,
                    tone: AppTheme.peach,
                    label: 'Morning routine',
                    controller: _amCtrl,
                  ),
                  const Divider(height: 22, color: Color(0x14000000)),
                  _TimeRow(
                    icon: Icons.nightlight_outlined,
                    tone: AppTheme.lavender,
                    label: 'Evening routine',
                    controller: _pmCtrl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PillButton(
              label: 'Save routine times',
              onPressed: () async {
                await state.updateReminders(_amCtrl.text, _pmCtrl.text);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Routine reminder times saved')),
                );
              },
            ),
            const SizedBox(height: 26),

            SectionLabel(
              'Custom reminders',
              trailing: TextButton.icon(
                onPressed: () => _openAddSheet(context, state),
                icon: const Icon(Icons.add, size: 16, color: AppTheme.charcoal),
                label: const Text(
                  'Add',
                  style: TextStyle(color: AppTheme.charcoal, fontSize: 12),
                ),
              ),
            ),
            if (customs.isEmpty)
              SoftCard(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.alarm_off_outlined,
                        color: AppTheme.textSecondary, size: 24),
                    const SizedBox(height: 12),
                    const Text(
                      'No custom reminders yet.',
                      style: TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add nudges for medications, hair masks, supplements — anything outside your AM / PM routine.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    PillButton(
                      label: 'Add a reminder',
                      icon: Icons.add,
                      onPressed: () => _openAddSheet(context, state),
                    ),
                  ],
                ),
              )
            else
              for (final r in customs) ...[
                _CustomReminderTile(
                  reminder: r,
                  onDelete: () => _confirmDelete(context, state, r),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context, AppState state) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: const _AddReminderSheet(),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppState state,
    Map<String, dynamic> reminder,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Remove "${reminder['label']}"?',
          style: const TextStyle(
            color: AppTheme.charcoal,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        content: const Text(
          'You can always add it back later.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.charcoal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await state.removeCustomReminder(reminder['id']?.toString() ?? '');
    }
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.icon,
    required this.tone,
    required this.label,
    required this.controller,
  });

  final IconData icon;
  final Color tone;
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TintedIconBadge(icon: icon, tint: tone, size: 40),
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
              const SizedBox(height: 4),
              SizedBox(
                height: 24,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.datetime,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'HH:mm',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.access_time,
              size: 18, color: AppTheme.textSecondary),
          onPressed: () async {
            final picked = await _pickTime(context, controller.text);
            if (picked != null) controller.text = picked;
          },
        ),
      ],
    );
  }
}

class _CustomReminderTile extends StatelessWidget {
  const _CustomReminderTile({required this.reminder, required this.onDelete});

  final Map<String, dynamic> reminder;
  final VoidCallback onDelete;

  IconData get _icon {
    switch (reminder['icon']?.toString()) {
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

  Color get _tone {
    switch (reminder['icon']?.toString()) {
      case 'spa':
        return AppTheme.sage;
      case 'hair':
        return AppTheme.blush;
      case 'water':
        return AppTheme.powder;
      case 'sun':
        return AppTheme.peach;
      case 'moon':
        return AppTheme.lavender;
      default:
        return AppTheme.beige;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: Colors.white,
      shadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          TintedIconBadge(icon: _icon, tint: _tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder['label']?.toString() ?? 'Reminder',
                  style: const TextStyle(
                    color: AppTheme.charcoal,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Daily · ${reminder['time'] ?? ''}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppTheme.textSecondary),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _label = TextEditingController();
  String _time = '09:00';
  String _icon = 'medication';
  bool _saving = false;

  static const _icons = <Map<String, String>>[
    {'key': 'medication', 'label': 'Medication'},
    {'key': 'supplement', 'label': 'Supplement'},
    {'key': 'water', 'label': 'Water'},
    {'key': 'spa', 'label': 'Skincare'},
    {'key': 'hair', 'label': 'Hair'},
    {'key': 'sun', 'label': 'Morning'},
    {'key': 'moon', 'label': 'Evening'},
  ];

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _label.text.trim();
    if (label.isEmpty || _saving) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    await state.addCustomReminder(label: label, time: _time, icon: _icon);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Text(
              'New reminder',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            const Text(
              'Set what to remember and when.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _label,
                style: const TextStyle(color: AppTheme.charcoal, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Allergy tablet, scalp oil, water…',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        final picked = await _pickTime(context, _time);
                        if (picked != null) setState(() => _time = picked);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 18, color: AppTheme.textSecondary),
                            const SizedBox(width: 10),
                            Text(
                              _time,
                              style: const TextStyle(
                                color: AppTheme.charcoal,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'CATEGORY',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in _icons)
                  GestureDetector(
                    onTap: () => setState(() => _icon = option['key']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: option['key'] == _icon
                            ? AppTheme.charcoal
                            : Colors.white,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        option['label']!,
                        style: TextStyle(
                          color: option['key'] == _icon
                              ? Colors.white
                              : AppTheme.charcoal,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            PillButton(
              label: _saving ? 'Saving…' : 'Add reminder',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _pickTime(BuildContext context, String current) async {
  TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
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
