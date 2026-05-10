import '../data/models.dart';

class AssistantReply {
  const AssistantReply({
    required this.reply,
    required this.warnings,
    this.requiresClarification = false,
  });

  final String reply;
  final List<String> warnings;
  final bool requiresClarification;
}

class LocalAssistant {
  /// Returns a friendly reply tailored to the user's products and latest scan.
  /// This is fully local — no backend needed.
  AssistantReply reply({
    required String message,
    required List<ProductData> products,
    Map<String, dynamic>? latestScan,
    Map<String, dynamic>? profile,
  }) {
    final text = message.toLowerCase();
    final warnings = _detectConflicts(products);

    final concerns =
        (latestScan?['concerns'] as List?)?.map((e) => e.toString()).toList() ??
            const [];
    final concernText = concerns.isEmpty
        ? 'No recent scan concerns logged.'
        : 'Latest scan concerns: ${concerns.join(', ')}.';

    if (text.contains('retinol') && text.contains('aha')) {
      return AssistantReply(
        reply:
            'Keep retinol and AHA on separate nights to protect your barrier. Try retinol on Mon / Wed / Sat and AHA on Tue / Fri.',
        warnings: warnings,
      );
    }

    if (text.contains('vitamin c') && text.contains('niacinamide')) {
      return AssistantReply(
        reply:
            'Modern formulas of vitamin C and niacinamide are usually compatible. If you notice flushing or congestion, separate them: vitamin C in the AM, niacinamide in the PM.',
        warnings: warnings,
      );
    }

    if (text.contains('dry') ||
        text.contains('tight') ||
        text.contains('flak')) {
      return AssistantReply(
        reply:
            'Sounds like a barrier dip. Tonight, skip actives, layer a humectant (hyaluronic or glycerin) onto damp skin, then a richer cream to lock it in. Re-introduce actives slowly after 2–3 calm nights.',
        warnings: warnings,
        requiresClarification: true,
      );
    }

    if (text.contains('breakout') ||
        text.contains('acne') ||
        text.contains('pimple')) {
      return AssistantReply(
        reply:
            'For breakouts, keep cleansing gentle, spot-treat with a BHA or benzoyl peroxide, and never skip SPF in the morning — UV makes post-acne marks worse. Avoid stacking too many actives on the same night.',
        warnings: warnings,
      );
    }

    if (text.contains('routine') || text.contains('schedule')) {
      final am = products
          .where((p) => p.timeOfDay == 'AM' || p.timeOfDay == 'both')
          .map((p) => p.name)
          .toList();
      final pm = products
          .where((p) => p.timeOfDay == 'PM' || p.timeOfDay == 'both')
          .map((p) => p.name)
          .toList();
      return AssistantReply(
        reply:
            'Here\'s a clean order:\n\nAM → ${am.isEmpty ? "(add a morning cleanser, treatment and SPF)" : am.join(' · ')}\nPM → ${pm.isEmpty ? "(add a cleanser, treatment and barrier cream)" : pm.join(' · ')}\n\n$concernText',
        warnings: warnings,
      );
    }

    return AssistantReply(
      reply:
          'You\'re doing great with consistency. $concernText Keep an AM cleanser + vitamin C + SPF, and calm PM barrier steps tonight.',
      warnings: warnings,
    );
  }

  List<String> _detectConflicts(List<ProductData> products) {
    final ingredients = <String>{};
    for (final p in products) {
      ingredients.add(p.name.toLowerCase());
    }
    final blob = ingredients.join(' ');
    final out = <String>[];
    bool has(String s) => blob.contains(s);

    if (has('retinol') && has('aha')) {
      out.add(
          'Retinol + AHA on the same night can irritate skin — alternate nights.');
    }
    if (has('retinol') && has('benzoyl peroxide')) {
      out.add(
          'Retinol + benzoyl peroxide can over-dry the barrier — separate usage.');
    }
    if (has('vitamin c') && has('niacinamide')) {
      out.add(
          'Vitamin C + niacinamide are usually fine, but separate them if you see irritation.');
    }
    return out;
  }
}
