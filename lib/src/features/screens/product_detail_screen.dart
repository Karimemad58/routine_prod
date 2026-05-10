import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../app_state.dart';
import '../widgets/common.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final product = state.productById(productId);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: product == null
            ? _NotFound()
            : _Body(product: product, state: state),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          children: [
            CircleIconButton(
              icon: Icons.arrow_back,
              background: AppTheme.softGray,
              shadow: false,
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/routine'),
            ),
          ],
        ),
        const SizedBox(height: 36),
        const Center(
          child: Text(
            'Product not found.',
            style: TextStyle(color: AppTheme.charcoal, fontSize: 18),
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.product, required this.state});

  final ProductData product;
  final AppState state;

  Color get _accent {
    switch (product.category) {
      case 'hair':
        return AppTheme.blush;
      case 'vitamin':
        return AppTheme.powder;
      case 'medication':
        return AppTheme.lavender;
      default:
        return AppTheme.sage;
    }
  }

  IconData get _icon {
    switch (product.category) {
      case 'hair':
        return Icons.cut_outlined;
      case 'vitamin':
        return Icons.medication_liquid_outlined;
      case 'medication':
        return Icons.local_pharmacy_outlined;
      default:
        return Icons.spa_outlined;
    }
  }

  String get _categoryLabel {
    switch (product.category) {
      case 'hair':
        return 'Hair';
      case 'vitamin':
        return 'Vitamin';
      case 'medication':
        return 'Medication';
      default:
        return 'Skin';
    }
  }

  String get _timeLabel {
    switch (product.timeOfDay) {
      case 'AM':
        return 'Morning';
      case 'PM':
        return 'Evening';
      default:
        return 'AM & PM';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          children: [
            CircleIconButton(
              icon: Icons.arrow_back,
              background: AppTheme.softGray,
              shadow: false,
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/routine'),
            ),
            const Spacer(),
            CircleIconButton(
              icon: Icons.delete_outline,
              background: AppTheme.softGray,
              shadow: false,
              onTap: () => _confirmDelete(context),
            ),
          ],
        ),
        const SizedBox(height: 18),

        SoftCard(
          color: _accent,
          shadow: false,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Hero(imageUrl: product.imageUrl, icon: _icon, accent: _accent),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _categoryLabel.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: AppTheme.charcoal,
                            fontSize: 22,
                            height: 1.15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (product.brand.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            product.brand,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChipPill(icon: Icons.schedule_outlined, label: _timeLabel),
                  _ChipPill(icon: Icons.repeat, label: product.frequency),
                  if (product.completed)
                    const _ChipPill(
                      icon: Icons.check_circle,
                      label: 'Done today',
                      filled: true,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        if (!product.completed)
          PillButton(
            label: 'Mark as done',
            icon: Icons.check,
            onPressed: () {
              final period = product.timeOfDay == 'PM' ? 'PM' : 'AM';
              state.completeStep(product.id, period);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} marked done')),
                );
              }
            },
          ),
        if (!product.completed) const SizedBox(height: 22),

        if (product.notes.isNotEmpty) ...[
          const SectionLabel('Notes'),
          SoftCard(
            color: Colors.white,
            shadow: false,
            child: Text(
              product.notes,
              style: const TextStyle(
                color: AppTheme.charcoal,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 22),
        ],

        if (product.ingredients.isNotEmpty) ...[
          SectionLabel(
            'Ingredients',
            trailing: Text(
              '${product.ingredients.length}',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SoftCard(
            color: Colors.white,
            shadow: false,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ingredient in product.ingredients)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.softGray,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      ingredient,
                      style: const TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],

        const SectionLabel('Details'),
        SoftCard(
          color: Colors.white,
          shadow: false,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.category_outlined,
                label: 'Category',
                value: _categoryLabel,
              ),
              _Divider(),
              _DetailRow(
                icon: Icons.schedule_outlined,
                label: 'Time of day',
                value: _timeLabel,
              ),
              _Divider(),
              _DetailRow(
                icon: Icons.repeat,
                label: 'Frequency',
                value: product.frequency,
              ),
              _Divider(),
              _DetailRow(
                icon: Icons.format_list_numbered,
                label: 'Step order',
                value: '${product.stepOrder}',
              ),
              if (product.externalSource != null &&
                  product.externalSource!.isNotEmpty) ...[
                _Divider(),
                _DetailRow(
                  icon: Icons.link,
                  label: 'Source',
                  value: product.externalSource!,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),

        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.charcoal,
            side: const BorderSide(color: Color(0x22000000)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          onPressed: () => _confirmDelete(context),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text(
            'Remove from routine',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Remove ${product.name}?',
          style: const TextStyle(
            color: AppTheme.charcoal,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        content: const Text(
          'This deletes the product from every routine.',
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
      await state.removeProduct(product.id);
      if (context.mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/routine');
        }
      }
    }
  }
}

class _Hero extends StatelessWidget {
  const _Hero(
      {required this.imageUrl, required this.icon, required this.accent});

  final String? imageUrl;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 88,
        height: 88,
        color: Colors.white.withValues(alpha: 0.55),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Center(child: Icon(icon, color: AppTheme.charcoal, size: 32)),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Center(child: Icon(icon, color: AppTheme.charcoal, size: 32)),
              )
            : Center(child: Icon(icon, color: AppTheme.charcoal, size: 32)),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({
    required this.icon,
    required this.label,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppTheme.charcoal;
    final bg = filled
        ? AppTheme.charcoal
        : Colors.white.withValues(alpha: 0.65);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 18),
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
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Color(0x12000000),
    );
  }
}
