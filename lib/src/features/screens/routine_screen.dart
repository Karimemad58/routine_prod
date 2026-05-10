import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/text_utils.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../app_state.dart';
import '../widgets/common.dart';

Future<void> showAddProductSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: const _AddProductSheet(),
      );
    },
  );
}

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasAny = state.amRoutine.isNotEmpty || state.pmRoutine.isNotEmpty;
    if (!hasAny && _editing) _editing = false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    'Your routine',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            if (hasAny) ...[
              _EditToggle(
                editing: _editing,
                onTap: () => setState(() => _editing = !_editing),
              ),
              const SizedBox(width: 8),
            ],
            CircleIconButton(
              icon: Icons.add,
              background: AppTheme.charcoal,
              foreground: Colors.white,
              shadow: false,
              onTap: () => _showAddDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (state.offline)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SoftCard(
              color: AppTheme.softGray,
              shadow: false,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: const Text(
                'Offline preview · changes save locally',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        if (_editing)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SoftCard(
              color: AppTheme.peach.withValues(alpha: 0.55),
              shadow: false,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.edit_outlined, size: 14, color: AppTheme.charcoal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap the minus to remove · drag the handle to reorder.',
                      style: TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SectionLabel('Morning'),
        _RoutineBlock(
          period: 'AM',
          accent: AppTheme.sage,
          steps: state.amRoutine,
          editing: _editing,
        ),
        const SizedBox(height: 22),

        const SectionLabel('Evening'),
        _RoutineBlock(
          period: 'PM',
          accent: AppTheme.blush,
          steps: state.pmRoutine,
          editing: _editing,
        ),
        const SizedBox(height: 24),

        PillButton(
          label: 'Add product',
          icon: Icons.add,
          onPressed: () => _showAddDialog(context),
        ),
      ],
    );
  }

  Future<void> _showAddDialog(BuildContext context) => showAddProductSheet(context);
}

class _EditToggle extends StatelessWidget {
  const _EditToggle({required this.editing, required this.onTap});

  final bool editing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: editing ? AppTheme.charcoal : AppTheme.softGray,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                editing ? Icons.check : Icons.edit_outlined,
                size: 14,
                color: editing ? Colors.white : AppTheme.charcoal,
              ),
              const SizedBox(width: 6),
              Text(
                editing ? 'Done' : 'Edit',
                style: TextStyle(
                  color: editing ? Colors.white : AppTheme.charcoal,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddProductSheet extends StatefulWidget {
  const _AddProductSheet();

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  final SuggestionsController<Map<String, dynamic>> _suggestionsCtrl =
      SuggestionsController<Map<String, dynamic>>();
  bool _saving = false;
  Map<String, dynamic>? _selected;
  String _category = 'skin';
  String _period = 'AM';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focus.dispose();
    _suggestionsCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchSuggestions(String pattern) async {
    return context.read<AppState>().searchCatalogProducts(pattern);
  }

  void _onSelected(Map<String, dynamic> product) {
    final name = _trimProductName(product['name']?.toString() ?? '');
    setState(() {
      _selected = product;
      if (name.isNotEmpty) {
        _searchCtrl.text = name;
        _searchCtrl.selection = TextSelection.collapsed(offset: name.length);
      }
      final c = product['category']?.toString();
      if (c == 'skin' || c == 'hair' || c == 'vitamin' || c == 'medication') {
        _category = c!;
      }
    });
    _focus.unfocus();
  }

  String _trimProductName(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return clean;
    final commaIndex = clean.indexOf(',');
    if (commaIndex <= 0) return clean;
    return clean.substring(0, commaIndex).trim();
  }

  Future<void> _save() async {
    final name = _searchCtrl.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    await state.addProduct(
      name,
      _category,
      _period,
      brand: _selected?['brand']?.toString(),
      imageUrl: _selected?['image_url']?.toString(),
      externalSource: _selected == null ? null : 'catalog',
    );
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
              'Add product',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            const Text(
              'Search your Supabase catalog or add manually',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TypeAheadField<Map<String, dynamic>>(
              controller: _searchCtrl,
              focusNode: _focus,
              suggestionsController: _suggestionsCtrl,
              debounceDuration: const Duration(milliseconds: 220),
              hideOnEmpty: false,
              hideOnLoading: false,
              hideOnError: false,
              constraints: const BoxConstraints(maxHeight: 300),
              decorationBuilder: (context, child) {
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 6,
                  shadowColor: Colors.black.withValues(alpha: 0.08),
                  child: child,
                );
              },
              builder: (context, controller, focusNode) {
                return _InputField(
                  controller: controller,
                  focusNode: focusNode,
                  hintText: 'Search product name',
                );
              },
              suggestionsCallback: _fetchSuggestions,
              itemBuilder: (context, product) => _SuggestionTile(product: product),
              emptyBuilder: (context) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Text(
                  _searchCtrl.text.trim().length < 3
                      ? 'Type at least 3 characters to search.'
                      : 'No match found — tap Add to create "${_searchCtrl.text}".',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              errorBuilder: (context, error) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Text(
                  'Could not search catalog right now.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              onSelected: _onSelected,
            ),
            const SizedBox(height: 14),
            _PillChips(
              label: 'Category',
              options: const ['skin', 'hair', 'vitamin', 'medication'],
              selected: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            _PillChips(
              label: 'Time',
              options: const ['AM', 'PM', 'both'],
              selected: _period,
              onChanged: (v) => setState(() => _period = v),
            ),
            const SizedBox(height: 18),
            PillButton(
              label: _saving ? 'Saving…' : 'Save',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.product});

  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final name = _trimProductName(product['name']?.toString() ?? '');
    final brand = product['brand']?.toString() ?? '';
    final category = product['category']?.toString() ?? 'skin';
    final imageUrl = product['image_url']?.toString();
    final subtitle =
        brand.isNotEmpty ? '$brand · ${category.toUpperCase()}' : category.toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 34,
              height: 34,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.softGray,
                        alignment: Alignment.center,
                        child: const Icon(Icons.search,
                            size: 16, color: AppTheme.textSecondary),
                      ),
                    )
                  : Container(
                      color: AppTheme.softGray,
                      alignment: Alignment.center,
                      child: const Icon(Icons.search,
                          size: 16, color: AppTheme.textSecondary),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _trimProductName(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return clean;
    final commaIndex = clean.indexOf(',');
    if (commaIndex <= 0) return clean;
    return clean.substring(0, commaIndex).trim();
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    this.focusNode,
  });

  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(
          color: AppTheme.charcoal,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

class _PillChips extends StatelessWidget {
  const _PillChips({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
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
            for (final option in options)
              GestureDetector(
                onTap: () => onChanged(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: option == selected ? AppTheme.charcoal : Colors.white,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: option == selected ? Colors.white : AppTheme.charcoal,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RoutineBlock extends StatelessWidget {
  const _RoutineBlock({
    required this.period,
    required this.accent,
    required this.steps,
    this.editing = false,
  });

  final String period;
  final Color accent;
  final List<ProductData> steps;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final completed = steps.where((s) => s.completed).length;
    final progress = steps.isEmpty ? 0.0 : completed / steps.length;

    return SoftCard(
      color: accent,
      shadow: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProgressRing(
                progress: progress,
                size: 56,
                strokeWidth: 5,
                trackColor: Colors.black.withValues(alpha: 0.08),
                color: AppTheme.charcoal,
                child: Text(
                  '$completed/${steps.length}',
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
                      period == 'AM' ? 'Morning routine' : 'Evening routine',
                      style: const TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
            ],
          ),
          const SizedBox(height: 14),
          if (editing && steps.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                child: child,
              ),
              itemCount: steps.length,
              onReorder: (oldIndex, newIndex) {
                final adjusted =
                    newIndex > oldIndex ? newIndex - 1 : newIndex;
                state.reorderRoutine(period, oldIndex, adjusted);
              },
              itemBuilder: (ctx, i) {
                final step = steps[i];
                return _StepRow(
                  key: ValueKey('${period}_${step.id}'),
                  productId: step.id,
                  name: prettyProductName(step.name),
                  completed: step.completed,
                  editing: true,
                  reorderIndex: i,
                  onTap: () => state.completeStep(step.id, period),
                  onDelete: () => _confirmDelete(context, state, step),
                );
              },
            )
          else
            for (final step in steps)
              _StepRow(
                key: ValueKey('${period}_${step.id}'),
                productId: step.id,
                name: prettyProductName(step.name),
                completed: step.completed,
                editing: false,
                onTap: () => state.completeStep(step.id, period),
                onDelete: () => _confirmDelete(context, state, step),
              ),
          if (steps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'No steps yet — add your first product.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppState state,
    ProductData step,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Remove ${step.name}?',
          style: const TextStyle(
            color: AppTheme.charcoal,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        content: const Text(
          'This will remove the product from every routine and delete it from your account.',
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
      await state.removeProduct(step.id);
    }
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.productId,
    required this.name,
    required this.completed,
    required this.onTap,
    required this.onDelete,
    this.editing = false,
    this.reorderIndex,
  });

  final String productId;
  final String name;
  final bool completed;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool editing;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            if (editing)
              InkWell(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.charcoal,
                    ),
                    child: const Icon(Icons.remove,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            Expanded(
              child: InkWell(
                onTap: editing ? null : onTap,
                child: Padding(
                  padding: editing
                      ? const EdgeInsets.fromLTRB(6, 12, 8, 12)
                      : const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Row(
                    children: [
                      if (!editing)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: completed
                                ? AppTheme.charcoal
                                : Colors.transparent,
                            border: Border.all(
                              color: completed
                                  ? AppTheme.charcoal
                                  : AppTheme.textMuted
                                      .withValues(alpha: 0.6),
                              width: 1.4,
                            ),
                          ),
                          child: completed
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                      if (!editing) const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: AppTheme.charcoal,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: completed && !editing
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
            if (editing && reorderIndex != null)
              ReorderableDragStartListener(
                index: reorderIndex!,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(8, 12, 14, 12),
                  child: Icon(
                    Icons.drag_handle,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
              )
            else if (!editing)
              InkWell(
                onTap: () => context.push('/product/$productId'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 14, 12),
                  child: Icon(
                    completed
                        ? Icons.check_circle_outline
                        : Icons.arrow_forward,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                ),
              )
            else
              const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}
