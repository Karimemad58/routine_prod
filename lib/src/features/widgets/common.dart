import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.tint = Colors.white,
    this.tintOpacity = 0.55,
    this.borderOpacity = 0.55,
    this.blur = 18,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color tint;
  final double tintOpacity;
  final double borderOpacity;
  final double blur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: tintOpacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 1,
            ),
            boxShadow: AppTheme.softShadow,
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.tint = Colors.white,
    this.tintOpacity = 0.18,
    this.borderOpacity = 0.45,
    this.blur = 14,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color tint;
  final double tintOpacity;
  final double borderOpacity;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: tintOpacity),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 0.8,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.shadow = true,
    this.onTap,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ? AppTheme.softShadow : null,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 6, bottom: 12, top: 4),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.background = AppTheme.charcoal,
    this.foreground = Colors.white,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: foreground, size: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.background = Colors.white,
    this.foreground = AppTheme.charcoal,
    this.shadow = true,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color background;
  final Color foreground;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            boxShadow: shadow ? AppTheme.microShadow : null,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: size * 0.45, color: foreground),
        ),
      ),
    );
  }
}

class TintedIconBadge extends StatelessWidget {
  const TintedIconBadge({
    super.key,
    required this.icon,
    required this.tint,
    this.size = 40,
  });

  final IconData icon;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(Colors.black.withValues(alpha: 0.04), tint),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: AppTheme.charcoal),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 6,
    this.trackColor = const Color(0x33FFFFFF),
    this.color = Colors.white,
    this.child,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color trackColor;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress.clamp(0, 1),
              strokeWidth: strokeWidth,
              trackColor: trackColor,
              color: color,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.color,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final track = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, this.activeIndex, this.onDayTap});

  final int? activeIndex;

  /// Optional callback invoked when a day in the strip is tapped. Future days
  /// (after today) are ignored automatically.
  final void Function(DateTime date)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: now.weekday % 7));
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final selected = activeIndex ?? now.weekday % 7;

    return SoftCard(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final day = start.add(Duration(days: i));
          final active = i == selected;
          final isFuture = day.isAfter(today);
          final tappable = !isFuture && onDayTap != null;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: tappable ? () => onDayTap!(day) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: isFuture
                            ? AppTheme.textMuted.withValues(alpha: 0.5)
                            : AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? AppTheme.charcoal
                            : Colors.transparent,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: active
                              ? Colors.white
                              : isFuture
                                  ? AppTheme.textMuted
                                  : AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

