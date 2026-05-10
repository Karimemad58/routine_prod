import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/text_utils.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../app_state.dart';
import '../widgets/common.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.category});

  final String category;

  static const _config = <String, _CategoryStyle>{
    'skin': _CategoryStyle(
      title: 'Skin',
      subtitle: 'Daily cleansing, treatment and protection.',
      color: AppTheme.sage,
      icon: Icons.spa_outlined,
    ),
    'hair': _CategoryStyle(
      title: 'Hair',
      subtitle: 'Wash days, masks and scalp care.',
      color: AppTheme.blush,
      icon: Icons.cut_outlined,
    ),
    'vitamin': _CategoryStyle(
      title: 'Vitamins',
      subtitle: 'Supplements timed with your day.',
      color: AppTheme.powder,
      icon: Icons.medication_outlined,
    ),
    'medication': _CategoryStyle(
      title: 'Medications',
      subtitle: 'Prescriptions and reminders.',
      color: AppTheme.lavender,
      icon: Icons.local_pharmacy_outlined,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final style = _config[category] ?? _config['skin']!;
    final items = state.productsForCategory(category);

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
              color: style.color,
              shadow: false,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TintedIconBadge(icon: style.icon, tint: style.color, size: 48),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Text(
                          '${items.length} item${items.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppTheme.charcoal,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    style.title,
                    style: const TextStyle(
                      color: AppTheme.charcoal,
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    style.subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionLabel('All products'),
            if (items.isEmpty)
              SoftCard(
                color: Colors.white,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(style.icon, color: AppTheme.textSecondary, size: 26),
                    const SizedBox(height: 12),
                    const Text(
                      'Nothing here yet.',
                      style: TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add your first ${style.title.toLowerCase()} product to start tracking.',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
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
              for (final p in items) ...[
                _ProductRow(product: p, accent: style.color),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _CategoryStyle {
  const _CategoryStyle({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.accent,
  });

  final ProductData product;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: Colors.white,
      shadow: false,
      onTap: () => context.push('/product/${product.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 18,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prettyProductName(product.name, maxLength: 36),
                  style: const TextStyle(
                    color: AppTheme.charcoal,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.timeOfDay} · ${product.completed ? "Done today" : "Pending"}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: product.completed ? 'View details' : 'View details',
            onPressed: () => context.push('/product/${product.id}'),
            icon: Icon(
              product.completed
                  ? Icons.check_circle
                  : Icons.arrow_forward,
              color: product.completed
                  ? AppTheme.charcoal
                  : AppTheme.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
