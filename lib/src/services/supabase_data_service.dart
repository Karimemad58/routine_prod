import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';

class SupabaseDataService {
  bool get enabled =>
      AppConfig.hasSupabase && RuntimeFlags.supabaseInitialized;

  void _logError(String where, Object error) {
    debugPrint('[SupabaseDataService] $where failed: $error');
  }

  Future<void> saveChatMessage({
    required String role,
    required String content,
  }) async {
    if (!enabled) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    await client.from('chat_history').insert({
      'user_id': user.id,
      'role': role,
      'content': content,
    });
  }

  Future<List<Map<String, dynamic>>> fetchChatHistory({int limit = 50}) async {
    if (!enabled) return const [];
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .from('chat_history')
        .select('role, content, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: true)
        .limit(limit);

    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> saveRoutineCompletion({
    required String productId,
    required String period,
  }) async {
    if (!enabled) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    if (productId.startsWith('local_')) {
      debugPrint(
          '[SupabaseDataService] saveRoutineCompletion skipped: local-only id $productId.');
      return;
    }

    // productId may be either a user_products.id (custom item) or a
    // products.id (catalog item). Look up the matching active routine_step.
    Map<String, dynamic>? step;
    try {
      final rows = await client
          .from('routine_steps')
          .select('id, user_product_id, product_id')
          .eq('user_id', user.id)
          .eq('time_of_day', period)
          .eq('is_active', true)
          .or('user_product_id.eq.$productId,product_id.eq.$productId');
      final list = (rows as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (list.isNotEmpty) step = list.first;
    } catch (e) {
      _logError('saveRoutineCompletion (lookup step)', e);
      rethrow;
    }
    if (step == null) {
      debugPrint(
          '[SupabaseDataService] saveRoutineCompletion: no active routine_step '
          'for source=$productId period=$period');
      return;
    }
    final stepId = step['id']?.toString();
    if (stepId == null || stepId.isEmpty) return;

    try {
      await client.from('routine_logs').upsert({
        'user_id': user.id,
        'routine_step_id': stepId,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      }, onConflict: 'user_id,routine_step_id,date');
    } catch (e) {
      _logError('saveRoutineCompletion (upsert)', e);
      rethrow;
    }
  }

  /// Updates the `step_order` for the routine_step that matches the given
  /// product+period. Best-effort — silently no-ops for local-only ids or when
  /// no matching step exists.
  Future<void> updateStepOrder({
    required String productId,
    required String period,
    required int stepOrder,
  }) async {
    if (!enabled) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    if (productId.startsWith('local_')) return;

    try {
      await client
          .from('routine_steps')
          .update({'step_order': stepOrder})
          .eq('user_id', user.id)
          .eq('time_of_day', period)
          .eq('is_active', true)
          .or('user_product_id.eq.$productId,product_id.eq.$productId');
    } catch (e) {
      _logError('updateStepOrder', e);
    }
  }

  /// Removes today's completion for a given product+period. Used when the
  /// user un-checks a step in the UI.
  Future<void> clearRoutineCompletion({
    required String productId,
    required String period,
  }) async {
    if (!enabled) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    if (productId.startsWith('local_')) return;

    Map<String, dynamic>? step;
    try {
      final rows = await client
          .from('routine_steps')
          .select('id')
          .eq('user_id', user.id)
          .eq('time_of_day', period)
          .eq('is_active', true)
          .or('user_product_id.eq.$productId,product_id.eq.$productId');
      final list = (rows as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (list.isNotEmpty) step = list.first;
    } catch (e) {
      _logError('clearRoutineCompletion (lookup step)', e);
      return;
    }
    final stepId = step?['id']?.toString();
    if (stepId == null || stepId.isEmpty) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    try {
      await client
          .from('routine_logs')
          .delete()
          .eq('user_id', user.id)
          .eq('routine_step_id', stepId)
          .eq('date', today);
    } catch (e) {
      _logError('clearRoutineCompletion (delete)', e);
    }
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    if (!enabled) return null;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    final row = await client
        .from('profiles')
        .select(
            'full_name, skin_type, am_reminder, pm_reminder, reminders, sensitivities, goals, skin_notes, notification_prefs')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return null;
    final reminders = _toListOfMap(row['reminders']);
    final sensitivities = _toStringList(row['sensitivities']);
    final goals = _toStringList(row['goals']);
    final notifPrefs = row['notification_prefs'] is Map
        ? Map<String, dynamic>.from(row['notification_prefs'] as Map)
        : <String, dynamic>{};
    return {
      'id': user.id,
      'name': row['full_name'] ?? '',
      'skin_type': row['skin_type'] ?? '',
      'amReminder': row['am_reminder'] ?? '07:30',
      'pmReminder': row['pm_reminder'] ?? '20:30',
      'reminders': reminders,
      'sensitivities': sensitivities,
      'goals': goals,
      'skin_notes': row['skin_notes']?.toString() ?? '',
      'notification_prefs': notifPrefs,
    };
  }

  List<Map<String, dynamic>> _toListOfMap(dynamic raw) {
    if (raw is List) {
      return List<Map<String, dynamic>>.from(
        raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
      );
    }
    return <Map<String, dynamic>>[];
  }

  List<String> _toStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  Future<void> _ensureProfileRow(SupabaseClient client, User user) async {
    // Only create a profile row if it does not already exist. Avoid upserting
    // full_name so we never overwrite a name the user has set later.
    final existing = await client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) return;
    await client.from('profiles').insert({
      'id': user.id,
      'full_name': user.userMetadata?['full_name']?.toString() ??
          (user.email?.split('@').first ?? ''),
    });
  }

  Future<void> updateSkinProfile({
    String? skinType,
    List<String>? sensitivities,
    List<String>? goals,
    String? notes,
  }) async {
    if (!enabled) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    await _ensureProfileRow(client, user);

    final patch = <String, dynamic>{};
    if (skinType != null) patch['skin_type'] = skinType.isEmpty ? null : skinType;
    if (sensitivities != null) patch['sensitivities'] = sensitivities;
    if (goals != null) patch['goals'] = goals;
    if (notes != null) patch['skin_notes'] = notes.isEmpty ? null : notes;
    if (patch.isEmpty) return;

    await client.from('profiles').update(patch).eq('id', user.id);
  }

  Future<void> updateNotificationPrefs(Map<String, dynamic> prefs) async {
    if (!enabled) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    await _ensureProfileRow(client, user);
    await client.from('profiles').update({
      'notification_prefs': prefs,
    }).eq('id', user.id);
  }

  Future<void> updateReminders(List<Map<String, dynamic>> reminders) async {
    if (!enabled) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    await _ensureProfileRow(client, user);

    await client.from('profiles').update({
      'reminders': reminders,
    }).eq('id', user.id);
  }

  Future<void> updateProfileReminders({
    required String am,
    required String pm,
  }) async {
    if (!enabled) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    await _ensureProfileRow(client, user);

    await client.from('profiles').update({
      'am_reminder': am,
      'pm_reminder': pm,
    }).eq('id', user.id);
  }

  Future<void> saveScanResult({
    required String skinType,
    required List<String> concerns,
    required Map<String, dynamic> zoneMap,
    String? imageUrl,
  }) async {
    if (!enabled) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    await client.from('scan_results').insert({
      'user_id': user.id,
      'skin_type': skinType,
      'concerns': concerns,
      'zone_map': zoneMap,
      if (imageUrl != null) 'image_url': imageUrl,
    });
  }

  Future<Map<String, dynamic>?> fetchLatestScan() async {
    if (!enabled) return null;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    final row = await client
        .from('scan_results')
        .select('skin_type, concerns, zone_map, scan_date, image_url')
        .eq('user_id', user.id)
        .order('scan_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;
    return Map<String, dynamic>.from(row as Map);
  }

  // ----- Products ----------------------------------------------------------

  Future<List<Map<String, dynamic>>> searchCatalogProducts(
    String query, {
    int limit = 12,
  }) async {
    if (!enabled) return const [];
    final q = query.trim();
    if (q.length < 3) return const [];
    final client = Supabase.instance.client;
    final rows = await client
        .from('products')
        .select('id, name, brand, category, image_url')
        .or('name.ilike.%$q%,brand.ilike.%$q%')
        .order('name', ascending: true)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    if (!enabled) return const [];
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return const [];

    // 1) routine_steps is the source of truth for the user's routine.
    final List<Map<String, dynamic>> steps;
    try {
      final rows = await client
          .from('routine_steps')
          .select(
              'id, user_product_id, product_id, time_of_day, category, step_order, frequency, is_active')
          .eq('user_id', user.id)
          .eq('is_active', true);
      steps = List<Map<String, dynamic>>.from(
        (rows as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (e) {
      _logError('fetchProducts (routine_steps)', e);
      return const [];
    }
    if (steps.isEmpty) return const [];

    final userProductIds = steps
        .map((s) => s['user_product_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final catalogIds = steps
        .map((s) => s['product_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    // 2) Custom items.
    final userProductsById = <String, Map<String, dynamic>>{};
    if (userProductIds.isNotEmpty) {
      try {
        final rows = await client
            .from('user_products')
            .select('id, custom_name, personal_notes')
            .eq('user_id', user.id)
            .inFilter('id', userProductIds);
        for (final r in rows as List) {
          final m = Map<String, dynamic>.from(r as Map);
          final id = m['id']?.toString();
          if (id != null) userProductsById[id] = m;
        }
      } catch (e) {
        _logError('fetchProducts (user_products)', e);
      }
    }

    // 3) Catalog items.
    final catalogById = <String, Map<String, dynamic>>{};
    if (catalogIds.isNotEmpty) {
      try {
        final rows = await client
            .from('products')
            .select('id, name, brand, category, image_url, external_source')
            .inFilter('id', catalogIds);
        for (final r in rows as List) {
          final m = Map<String, dynamic>.from(r as Map);
          final id = m['id']?.toString();
          if (id != null) catalogById[id] = m;
        }
      } catch (e) {
        _logError('fetchProducts (catalog)', e);
      }
    }

    // 4) Group steps by their source id (user_product_id OR product_id) so AM
    //    and PM rows for the same product collapse into one entry.
    final stepsBySource = <String, List<Map<String, dynamic>>>{};
    for (final s in steps) {
      final upid = s['user_product_id']?.toString();
      final pid = s['product_id']?.toString();
      final source = (upid != null && upid.isNotEmpty) ? upid : pid;
      if (source == null || source.isEmpty) continue;
      (stepsBySource[source] ??= []).add(s);
    }

    final out = <Map<String, dynamic>>[];
    for (final entry in stepsBySource.entries) {
      final source = entry.key;
      final group = List<Map<String, dynamic>>.from(entry.value)
        ..sort((a, b) => ((a['step_order'] as num?)?.toInt() ?? 1)
            .compareTo((b['step_order'] as num?)?.toInt() ?? 1));
      final hasAm = group.any((s) => s['time_of_day'] == 'AM');
      final hasPm = group.any((s) => s['time_of_day'] == 'PM');
      String period = 'both';
      if (hasAm && !hasPm) period = 'AM';
      if (hasPm && !hasAm) period = 'PM';
      final first = group.first;

      final isCustom = userProductsById.containsKey(source);
      final custom = isCustom ? userProductsById[source] : null;
      final catalog = isCustom ? null : catalogById[source];

      out.add({
        'id': source,
        'name': isCustom
            ? (custom?['custom_name']?.toString() ?? '')
            : (catalog?['name']?.toString() ?? ''),
        'brand': isCustom ? '' : (catalog?['brand']?.toString() ?? ''),
        'category': first['category']?.toString() ??
            catalog?['category']?.toString() ??
            'skin',
        'time_of_day': period,
        'frequency': first['frequency']?.toString() ?? 'daily',
        'step_order': (first['step_order'] as num?)?.toInt() ?? 1,
        'notes': isCustom ? (custom?['personal_notes']?.toString() ?? '') : '',
        'ingredients': const <String>[],
        'image_url': isCustom ? null : catalog?['image_url']?.toString(),
        'external_source':
            isCustom ? null : catalog?['external_source']?.toString(),
      });
    }
    out.sort((a, b) => ((a['step_order'] as num?)?.toInt() ?? 1)
        .compareTo((b['step_order'] as num?)?.toInt() ?? 1));
    return out;
  }

  Future<Map<String, dynamic>?> saveProduct({
    required String name,
    required String category,
    required String timeOfDay,
    String? brand,
    String? notes,
    int stepOrder = 1,
    String frequency = 'daily',
    List<String> ingredients = const [],
    String? imageUrl,
    String? externalSource,
  }) async {
    if (!enabled) return null;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      await _ensureProfileRow(client, user);
    } catch (e) {
      _logError('saveProduct (ensureProfileRow)', e);
      rethrow;
    }

    final cleanName = name.trim();
    if (cleanName.isEmpty) return null;
    final cleanBrand = brand?.trim();

    // 1) Resolve an existing catalog entry. We never insert into public.products
    //    here — if the user typed a product that is not in the catalog, it goes
    //    into public.user_products as a custom item.
    Map<String, dynamic>? catalog;
    try {
      catalog =
          await _resolveCatalogProduct(client, cleanName, category, cleanBrand);
    } catch (e) {
      _logError('saveProduct (resolveCatalog)', e);
      catalog = null;
    }

    // 2) Decide source. Catalog matches go straight into routine_steps without
    //    a user_products row. Custom items get a user_products row whose id is
    //    referenced by routine_steps.
    String? userProductId;
    String? catalogId = catalog?['id']?.toString();

    if (catalogId == null || catalogId.isEmpty) {
      Map<String, dynamic>? userProduct;
      try {
        userProduct = await client
            .from('user_products')
            .insert({
              'user_id': user.id,
              'custom_name': cleanName,
              if (notes != null && notes.isNotEmpty) 'personal_notes': notes,
            })
            .select('id')
            .maybeSingle();
      } catch (e) {
        _logError('saveProduct (user_products insert)', e);
        rethrow;
      }
      if (userProduct == null) return null;
      userProductId = userProduct['id']?.toString();
      if (userProductId == null || userProductId.isEmpty) return null;
    }

    // 3) Insert routine_steps so completion toggles can write to routine_logs.
    Map<String, dynamic> stepPayload(String tod) => {
          'user_id': user.id,
          'time_of_day': tod,
          'category': category,
          'step_order': stepOrder,
          'frequency': frequency,
          'is_active': true,
          if (userProductId != null) 'user_product_id': userProductId,
          if (catalogId != null) 'product_id': catalogId,
        };

    final stepPayloads = <Map<String, dynamic>>[];
    if (timeOfDay == 'AM' || timeOfDay == 'both') stepPayloads.add(stepPayload('AM'));
    if (timeOfDay == 'PM' || timeOfDay == 'both') stepPayloads.add(stepPayload('PM'));

    if (stepPayloads.isNotEmpty) {
      try {
        await client.from('routine_steps').insert(stepPayloads);
      } catch (e) {
        _logError('saveProduct (routine_steps insert)', e);
        // If the user already has this catalog item in their routine, swallow
        // the unique-violation so the UI does not flip to the local fallback.
        final es = e.toString().toLowerCase();
        if (catalogId != null && (es.contains('23505') || es.contains('duplicate'))) {
          // fall through and return the existing source as success
        } else {
          rethrow;
        }
      }
    }

    final synthesizedId = userProductId ?? catalogId!;
    return {
      'id': synthesizedId,
      'name': cleanName,
      'brand': (catalog?['brand']?.toString() ?? cleanBrand ?? ''),
      'category': category,
      'time_of_day': timeOfDay,
      'frequency': frequency,
      'step_order': stepOrder,
      'notes': notes ?? '',
      'ingredients': const <String>[],
      'image_url': catalog?['image_url']?.toString() ?? imageUrl,
      'external_source':
          catalog?['external_source']?.toString() ?? externalSource,
    };
  }

  /// Resolves an existing catalog product by fuzzy name + category match
  /// (preferring the same brand). Returns null when the typed product is
  /// not in the catalog so the caller can store it as a custom user_product
  /// instead. Note: the live `public.products` table has no `barcode` column,
  /// so we never look one up.
  Future<Map<String, dynamic>?> _resolveCatalogProduct(
    SupabaseClient client,
    String name,
    String category,
    String? brand,
  ) async {
    final escaped =
        name.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
    final rows = await client
        .from('products')
        .select('id, name, brand, category, image_url, external_source')
        .eq('category', category)
        .ilike('name', '$escaped%')
        .limit(10);

    final candidates = List<Map<String, dynamic>>.from(
      (rows as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    if (candidates.isEmpty) return null;

    final wantBrand = brand?.toLowerCase();
    if (wantBrand != null && wantBrand.isNotEmpty) {
      for (final c in candidates) {
        final b = (c['brand']?.toString().trim().toLowerCase() ?? '');
        if (b == wantBrand) return c;
      }
    }
    if (candidates.length == 1) return candidates.first;
    return null;
  }

  Future<void> deleteProduct(String productId) async {
    if (!enabled) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    // Try as a custom item first. user_products cascades to routine_steps and
    // routine_logs.
    try {
      final result = await client
          .from('user_products')
          .delete()
          .eq('id', productId)
          .eq('user_id', user.id)
          .select('id');
      if (result.isNotEmpty) return;
    } catch (e) {
      _logError('deleteProduct (user_products)', e);
    }

    // Fall through: it must be a catalog product. Drop the user's routine_steps
    // for that catalog id (logs cascade).
    try {
      await client
          .from('routine_steps')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', productId);
    } catch (e) {
      _logError('deleteProduct (routine_steps)', e);
      rethrow;
    }
  }

  // ----- Routine completions ----------------------------------------------

  /// Returns the set of `productId|period` keys completed today, where
  /// `productId` is either a user_products.id (custom) or a products.id
  /// (catalog) — matching the `id` returned from [fetchProducts].
  Future<Set<String>> fetchTodayCompletions() {
    return fetchCompletionsForDate(
        DateTime.now().toIso8601String().substring(0, 10));
  }

  /// Returns the set of `<sourceId>|<period>` keys completed on [date]
  /// (yyyy-MM-dd). Used for both today's checks and the history viewer.
  Future<Set<String>> fetchCompletionsForDate(String date) async {
    if (!enabled) return <String>{};
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return <String>{};

    final List<dynamic> logs;
    try {
      logs = await client
          .from('routine_logs')
          .select('routine_step_id')
          .eq('user_id', user.id)
          .eq('date', date) as List<dynamic>;
    } catch (e) {
      _logError('fetchCompletionsForDate (routine_logs)', e);
      return <String>{};
    }

    final stepIds = logs
        .map((r) => (r as Map)['routine_step_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (stepIds.isEmpty) return <String>{};

    final List<dynamic> steps;
    try {
      steps = await client
          .from('routine_steps')
          .select('id, user_product_id, product_id, time_of_day')
          .inFilter('id', stepIds) as List<dynamic>;
    } catch (e) {
      _logError('fetchCompletionsForDate (routine_steps)', e);
      return <String>{};
    }

    final out = <String>{};
    for (final r in steps) {
      final m = Map<String, dynamic>.from(r as Map);
      final upid = m['user_product_id']?.toString();
      final pid = m['product_id']?.toString();
      final period = m['time_of_day']?.toString();
      final source = (upid != null && upid.isNotEmpty) ? upid : pid;
      if (source != null && source.isNotEmpty && period != null) {
        out.add('$source|$period');
      }
    }
    return out;
  }

  /// Returns distinct days with at least one completion (descending) for the
  /// past `lookback` days. Used for streak math.
  Future<List<String>> fetchRecentLogDates({int lookback = 60}) async {
    if (!enabled) return const [];
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final since =
        DateTime.now().subtract(Duration(days: lookback)).toIso8601String().substring(0, 10);
    final rows = await client
        .from('routine_logs')
        .select('date')
        .eq('user_id', user.id)
        .gte('date', since)
        .order('date', ascending: false);

    final dates = <String>{};
    for (final r in rows as List) {
      dates.add((r as Map)['date'].toString());
    }
    return dates.toList();
  }
}
