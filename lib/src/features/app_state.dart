import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../core/text_utils.dart';
import '../data/models.dart';
import '../services/local_assistant.dart';
import '../services/notification_service.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_data_service.dart';

enum AuthStatus { unknown, signedOut, signedIn, guest }

class AppState extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final SupabaseDataService _data = SupabaseDataService();
  final LocalAssistant _assistant = LocalAssistant();

  StreamSubscription<AuthState>? _authSub;

  bool loading = true;
  String error = '';

  /// True after the first profile fetch attempt for the current session has
  /// completed. The router uses this to avoid redirecting to onboarding
  /// before the user's `notification_prefs` (and therefore the
  /// `onboardingCompleted` flag) have come back from Supabase.
  bool profileFetched = false;

  AuthStatus authStatus = AuthStatus.unknown;
  bool get supabaseEnabled => RuntimeFlags.supabaseInitialized;
  bool get isSignedIn => authStatus == AuthStatus.signedIn;
  bool get isGuest => authStatus == AuthStatus.guest;
  String? get userEmail => _authService.currentUser?.email;

  // The app is "online" when Supabase is configured and the user is signed in.
  // Guests run fully in-memory.
  bool get offline => !isSignedIn;

  DashboardData dashboard = const DashboardData(
    greeting: 'Welcome',
    dailyScore: 0,
    streakDays: 0,
    categories: {'skin': 0, 'hair': 0, 'vitamin': 0, 'medication': 0},
  );

  List<ProductData> products = const [];
  List<ProductData> amRoutine = const [];
  List<ProductData> pmRoutine = const [];

  List<ChatMessageData> chat = const [
    ChatMessageData(
      role: 'assistant',
      content:
          'Welcome. Add your first product and I will help you build a clean routine.',
    ),
  ];

  Map<String, dynamic> profile = const {
    'name': '',
    'skin_type': '',
    'amReminder': '07:30',
    'pmReminder': '20:30',
    'reminders': <Map<String, dynamic>>[],
    'sensitivities': <String>[],
    'goals': <String>[],
    'skin_notes': '',
    'notification_prefs': <String, dynamic>{},
  };

  Map<String, dynamic>? latestScan;

  List<Map<String, dynamic>> get customReminders {
    final raw = profile['reminders'];
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  List<String> get sensitivities {
    final raw = profile['sensitivities'];
    return raw is List ? raw.map((e) => e.toString()).toList() : const [];
  }

  List<String> get skinGoals {
    final raw = profile['goals'];
    return raw is List ? raw.map((e) => e.toString()).toList() : const [];
  }

  String get skinType => profile['skin_type']?.toString() ?? '';
  String get skinNotes => profile['skin_notes']?.toString() ?? '';

  Map<String, dynamic> get notificationPrefs {
    final raw = profile['notification_prefs'];
    return raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
  }

  bool getNotifPref(String key, {bool defaultValue = true}) {
    final v = notificationPrefs[key];
    if (v is bool) return v;
    return defaultValue;
  }

  String getNotifPrefString(String key, {String defaultValue = ''}) {
    final v = notificationPrefs[key];
    if (v is String) return v;
    return defaultValue;
  }

  /// The next upcoming routine step (AM in the morning, PM in the afternoon
  /// onwards), or null if no products exist.
  ProductData? get nextUpcomingStep {
    final hour = DateTime.now().hour;
    final preferAm = hour < 14;
    final primary = preferAm ? amRoutine : pmRoutine;
    final secondary = preferAm ? pmRoutine : amRoutine;
    for (final p in primary) {
      if (!p.completed) return p;
    }
    for (final p in secondary) {
      if (!p.completed) return p;
    }
    return null;
  }

  /// "AM" if next upcoming is from the AM list, "PM" otherwise.
  String? get nextUpcomingPeriod {
    final next = nextUpcomingStep;
    if (next == null) return null;
    return amRoutine.any((p) => p.id == next.id) ? 'AM' : 'PM';
  }

  String get userName {
    final n = profile['name']?.toString().trim() ?? '';
    if (n.isNotEmpty) return toTitleCase(n);
    final email = userEmail ?? '';
    if (email.contains('@')) return toTitleCase(email.split('@').first);
    return 'there';
  }

  bool get hasAnyProducts => products.isNotEmpty;

  /// True if the user has been through onboarding once already, or their
  /// account already carries a skin profile from before the flag existed.
  /// The flag is set the first time the onboarding screen is shown so the
  /// user never sees it twice — no matter how they leave the screen.
  bool get hasOnboarded {
    final prefs = notificationPrefs;
    if (prefs['onboardingCompleted'] == true) return true;
    // Backwards compat with the older skip-only flag.
    if (prefs['onboardingSkipped'] == true) return true;
    // Legacy users who pre-date the flag but already have a skin profile.
    if (skinType.isNotEmpty) return true;
    if (sensitivities.isNotEmpty) return true;
    if (skinGoals.isNotEmpty) return true;
    if (skinNotes.isNotEmpty) return true;
    return false;
  }

  int get amCompleted => amRoutine.where((p) => p.completed).length;
  int get pmCompleted => pmRoutine.where((p) => p.completed).length;
  double get amProgress =>
      amRoutine.isEmpty ? 0 : amCompleted / amRoutine.length;
  double get pmProgress =>
      pmRoutine.isEmpty ? 0 : pmCompleted / pmRoutine.length;

  List<ProductData> productsForCategory(String category) =>
      products.where((p) => p.category == category).toList();

  List<ProductData> productsForPeriod(String period) {
    if (period == 'AM') return amRoutine;
    if (period == 'PM') return pmRoutine;
    return [...amRoutine, ...pmRoutine];
  }

  // --------------------------------------------------------------------------
  // Lifecycle
  // --------------------------------------------------------------------------

  Future<void> initialize() async {
    if (!supabaseEnabled) {
      authStatus = AuthStatus.guest;
    } else if (_authService.isSignedIn) {
      authStatus = AuthStatus.signedIn;
    } else {
      authStatus = AuthStatus.signedOut;
    }

    final stream = _authService.authStateChanges();
    if (stream != null) {
      _authSub = stream.listen((event) {
        final hasSession = event.session != null;
        authStatus = hasSession ? AuthStatus.signedIn : AuthStatus.signedOut;
        notifyListeners();
        if (hasSession) {
          // Pull data for the new session.
          unawaited(refresh(silent: true));
        }
      });
    }

    await refresh(silent: true);
    try {
      await scheduleRoutineNotifications();
    } catch (_) {
      // Notifications are optional on web/desktop.
    }
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Auth
  // --------------------------------------------------------------------------

  Future<void> signIn(String email, String password) async {
    await _authService.signIn(email: email, password: password);
    authStatus = AuthStatus.signedIn;
    notifyListeners();
    await refresh(silent: true);
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _authService.signUp(
      email: email,
      password: password,
      name: name,
    );
    if (response.session != null) {
      authStatus = AuthStatus.signedIn;
    }
    if (name != null && name.isNotEmpty) {
      profile = {...profile, 'name': name};
    }
    notifyListeners();
    if (authStatus == AuthStatus.signedIn) {
      await refresh(silent: true);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    authStatus = supabaseEnabled ? AuthStatus.signedOut : AuthStatus.guest;
    _resetSessionData();
    notifyListeners();
  }

  void continueAsGuest() {
    authStatus = AuthStatus.guest;
    notifyListeners();
  }

  void _resetSessionData() {
    products = const [];
    amRoutine = const [];
    pmRoutine = const [];
    latestScan = null;
    profileFetched = false;
    profile = const {
      'name': '',
      'skin_type': '',
      'amReminder': '07:30',
      'pmReminder': '20:30',
      'reminders': <Map<String, dynamic>>[],
      'sensitivities': <String>[],
      'goals': <String>[],
      'skin_notes': '',
      'notification_prefs': <String, dynamic>{},
    };
    dashboard = const DashboardData(
      greeting: 'Welcome',
      dailyScore: 0,
      streakDays: 0,
      categories: {'skin': 0, 'hair': 0, 'vitamin': 0, 'medication': 0},
    );
    chat = const [
      ChatMessageData(
        role: 'assistant',
        content:
            'Welcome. Add your first product and I will help you build a clean routine.',
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // Refresh — pulls everything from Supabase. Guests skip this.
  // --------------------------------------------------------------------------

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    error = '';

    if (!isSignedIn) {
      // Guest mode: keep whatever's in-memory.
      loading = false;
      notifyListeners();
      return;
    }

    try {
      final remoteProfile = await _data.fetchProfile();
      if (remoteProfile != null) {
        profile = {...profile, ...remoteProfile};
      }
      profileFetched = true;

      final remoteProducts = await _data.fetchProducts();
      products = remoteProducts.map(_productFromSupabase).toList();

      final completions = await _data.fetchTodayCompletions();
      amRoutine = _filterRoutine('AM', completions);
      pmRoutine = _filterRoutine('PM', completions);

      final logDates = await _data.fetchRecentLogDates();
      final streak = _calculateStreak(logDates);

      dashboard = DashboardData(
        greeting: 'Good morning, ${userName.isNotEmpty ? userName : "there"}',
        dailyScore: _calculateDailyScore(),
        streakDays: streak,
        categories: _categoryCounts(),
      );

      final remoteChat = await _data.fetchChatHistory();
      if (remoteChat.isNotEmpty) {
        chat = remoteChat.map((e) => ChatMessageData.fromJson(e)).toList();
      }

      final remoteScan = await _data.fetchLatestScan();
      if (remoteScan != null) {
        latestScan = remoteScan;
      }
    } catch (e) {
      error = 'Could not load your data: $e';
      // Even on failure, mark as fetched so the redirect can proceed once
      // and we don't keep blocking the router behind a transient error.
      profileFetched = true;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  ProductData _productFromSupabase(Map<String, dynamic> row) {
    return ProductData.fromJson(row);
  }

  List<ProductData> _filterRoutine(String period, Set<String> completions) {
    return products
        .where((p) => p.timeOfDay == period || p.timeOfDay == 'both')
        .map((p) => p.copyWith(
              completed: completions.contains('${p.id}|$period'),
            ))
        .toList();
  }

  ProductData? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Map<String, dynamic> _categoryCounts() {
    final out = {'skin': 0, 'hair': 0, 'vitamin': 0, 'medication': 0};
    for (final p in products) {
      if (out.containsKey(p.category)) {
        out[p.category] = (out[p.category] ?? 0) + 1;
      }
    }
    return out;
  }

  int _calculateDailyScore() {
    final total = amRoutine.length + pmRoutine.length;
    if (total == 0) return 0;
    final done = amCompleted + pmCompleted;
    return ((done / total) * 100).round();
  }

  int _calculateStreak(List<String> sortedDescDates) {
    if (sortedDescDates.isEmpty) return 0;
    final dateSet = sortedDescDates.toSet();
    var streak = 0;
    var cursor = DateTime.now();
    while (true) {
      final key = cursor.toIso8601String().substring(0, 10);
      if (!dateSet.contains(key)) break;
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // --------------------------------------------------------------------------
  // Routine completion
  // --------------------------------------------------------------------------

  /// Toggles the completion state for [productId] on [period].
  /// If the step is already completed, it un-checks it and removes today's
  /// `routine_logs` row; otherwise it marks it complete.
  Future<void> completeStep(String productId, String period) async {
    final list = period == 'AM' ? amRoutine : pmRoutine;
    final current = list.firstWhere(
      (p) => p.id == productId,
      orElse: () => ProductData(
        id: productId,
        name: '',
        category: 'skin',
        timeOfDay: period,
        completed: false,
      ),
    );
    final next = !current.completed;

    _toggleLocalStep(productId, period, next);
    notifyListeners();

    if (!isSignedIn) return;

    try {
      if (next) {
        await _data.saveRoutineCompletion(
          productId: productId,
          period: period,
        );
      } else {
        await _data.clearRoutineCompletion(
          productId: productId,
          period: period,
        );
      }
      await refresh(silent: true);
    } catch (_) {
      // Local state already reflects the change.
    }
  }

  /// Reorders the routine for [period]. Indices are list positions in the
  /// currently displayed list. New step orders are persisted optimistically.
  Future<void> reorderRoutine(
      String period, int oldIndex, int newIndex) async {
    final source = period == 'AM' ? amRoutine : pmRoutine;
    if (oldIndex < 0 ||
        oldIndex >= source.length ||
        newIndex < 0 ||
        newIndex >= source.length ||
        oldIndex == newIndex) {
      return;
    }
    final reordered = [...source];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    if (period == 'AM') {
      amRoutine = reordered;
    } else {
      pmRoutine = reordered;
    }
    notifyListeners();

    if (!isSignedIn) return;

    try {
      // Persist the new positions sequentially. `step_order` is 1-based.
      for (var i = 0; i < reordered.length; i++) {
        await _data.updateStepOrder(
          productId: reordered[i].id,
          period: period,
          stepOrder: i + 1,
        );
      }
    } catch (_) {
      // Local order is already correct; a future refresh will reconcile.
    }
  }

  void _toggleLocalStep(String productId, String period, bool completed) {
    if (period == 'AM') {
      amRoutine = amRoutine
          .map((p) => p.id == productId ? p.copyWith(completed: completed) : p)
          .toList();
    } else {
      pmRoutine = pmRoutine
          .map((p) => p.id == productId ? p.copyWith(completed: completed) : p)
          .toList();
    }
    dashboard = DashboardData(
      greeting: dashboard.greeting,
      dailyScore: _calculateDailyScore(),
      streakDays: dashboard.streakDays,
      categories: dashboard.categories,
    );
  }

  // --------------------------------------------------------------------------
  // Chat — local heuristic assistant + Supabase persistence
  // --------------------------------------------------------------------------

  Future<void> sendMessage(String message) async {
    final content = message.trim();
    if (content.isEmpty) return;

    chat = [...chat, ChatMessageData(role: 'user', content: content)];
    notifyListeners();

    if (isSignedIn) {
      try {
        await _data.saveChatMessage(role: 'user', content: content);
      } catch (_) {
        // Persistence is best-effort.
      }
    }

    final reply = _assistant.reply(
      message: content,
      products: products,
      latestScan: latestScan,
      profile: profile,
    );

    chat = [
      ...chat,
      ChatMessageData(role: 'assistant', content: reply.reply),
    ];
    notifyListeners();

    if (isSignedIn) {
      try {
        await _data.saveChatMessage(role: 'assistant', content: reply.reply);
      } catch (_) {
        // Persistence is best-effort.
      }
    }
  }

  // --------------------------------------------------------------------------
  // Reminders
  // --------------------------------------------------------------------------

  Future<void> updateReminders(String am, String pm) async {
    profile = {
      ...profile,
      'amReminder': am,
      'pmReminder': pm,
    };
    notifyListeners();

    if (isSignedIn) {
      try {
        await _data.updateProfileReminders(am: am, pm: pm);
      } catch (_) {
        // Best-effort.
      }
    }
    try {
      await scheduleRoutineNotifications();
    } catch (_) {
      // Notifications optional on some platforms.
    }
  }

  Future<void> addCustomReminder({
    required String label,
    required String time,
    String icon = 'medication',
  }) async {
    final next = {
      'id': 'rem_${DateTime.now().millisecondsSinceEpoch}',
      'label': toTitleCase(label),
      'time': time,
      'icon': icon,
    };
    final updated = [...customReminders, next];
    await _persistCustomReminders(updated);
  }

  Future<void> removeCustomReminder(String id) async {
    final updated = customReminders.where((r) => r['id'] != id).toList();
    await _persistCustomReminders(updated);
  }

  Future<void> _persistCustomReminders(List<Map<String, dynamic>> list) async {
    profile = {...profile, 'reminders': list};
    notifyListeners();
    if (!isSignedIn) return;
    try {
      await _data.updateReminders(list);
    } catch (_) {
      // Best-effort: in-memory state already reflects the change.
    }
  }

  Future<void> updateSkinProfile({
    String? skinType,
    List<String>? sensitivities,
    List<String>? goals,
    String? notes,
  }) async {
    profile = {
      ...profile,
      if (skinType != null) 'skin_type': skinType,
      if (sensitivities != null) 'sensitivities': sensitivities,
      if (goals != null) 'goals': goals,
      if (notes != null) 'skin_notes': notes,
    };
    notifyListeners();

    if (!isSignedIn) return;
    try {
      await _data.updateSkinProfile(
        skinType: skinType,
        sensitivities: sensitivities,
        goals: goals,
        notes: notes,
      );
    } catch (_) {
      // Best-effort: local state already reflects the change.
    }
  }

  /// Persist a flag indicating the user has been through onboarding at least
  /// once. Called when the onboarding screen is first shown so the user never
  /// sees it again, regardless of whether they save or skip.
  Future<void> markOnboardingComplete() async {
    if (hasOnboarded) return;
    await updateNotificationPrefs({'onboardingCompleted': true});
  }

  /// Fetches the set of `<sourceId>|<period>` keys completed on [date]
  /// (yyyy-MM-dd). Returns an empty set for guests or signed-out users.
  Future<Set<String>> completionsForDate(String date) async {
    if (!isSignedIn) return <String>{};
    try {
      return await _data.fetchCompletionsForDate(date);
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> updateNotificationPrefs(Map<String, dynamic> prefs) async {
    final merged = {...notificationPrefs, ...prefs};
    profile = {...profile, 'notification_prefs': merged};
    notifyListeners();

    if (isSignedIn) {
      try {
        await _data.updateNotificationPrefs(merged);
      } catch (_) {
        // Best-effort.
      }
    }
    try {
      await scheduleRoutineNotifications();
    } catch (_) {
      // Notifications optional.
    }
  }

  // --------------------------------------------------------------------------
  // Add / remove products
  // --------------------------------------------------------------------------

  Future<void> addProduct(
    String name,
    String category,
    String timeOfDay, {
    String? brand,
    String? notes,
    String? imageUrl,
    String? externalSource,
    List<String> ingredients = const [],
  }) async {
    final clean = toTitleCase(name);
    if (clean.isEmpty) return;
    final cleanBrand = brand == null ? null : toTitleCase(brand);

    if (isSignedIn) {
      try {
        final stepOrder = products.length + 1;
        final inserted = await _data.saveProduct(
          name: clean,
          category: category,
          timeOfDay: timeOfDay,
          brand: cleanBrand,
          notes: notes,
          stepOrder: stepOrder,
          ingredients: ingredients,
          imageUrl: imageUrl,
          externalSource: externalSource,
        );
        if (inserted != null) {
          await refresh(silent: true);
          return;
        }
      } catch (_) {
        // Fall through to local insert so the user always sees their product.
      }
    }

    // Guest / fallback: in-memory only.
    final next = ProductData(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      name: clean,
      category: category,
      timeOfDay: timeOfDay,
      completed: false,
      brand: cleanBrand ?? '',
      notes: notes ?? '',
      ingredients: ingredients,
      imageUrl: imageUrl,
      externalSource: externalSource,
    );
    products = [...products, next];
    if (timeOfDay == 'AM' || timeOfDay == 'both') {
      amRoutine = [...amRoutine, next];
    }
    if (timeOfDay == 'PM' || timeOfDay == 'both') {
      pmRoutine = [...pmRoutine, next];
    }
    dashboard = DashboardData(
      greeting: dashboard.greeting,
      dailyScore: _calculateDailyScore(),
      streakDays: dashboard.streakDays,
      categories: _categoryCounts(),
    );
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> searchCatalogProducts(String query) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    try {
      return await _data.searchCatalogProducts(q);
    } catch (_) {
      return const [];
    }
  }

  Future<void> removeProduct(String productId) async {
    if (isSignedIn && !productId.startsWith('local_')) {
      try {
        await _data.deleteProduct(productId);
        await refresh(silent: true);
        return;
      } catch (_) {
        // Fall through to local removal.
      }
    }
    products = products.where((p) => p.id != productId).toList();
    amRoutine = amRoutine.where((p) => p.id != productId).toList();
    pmRoutine = pmRoutine.where((p) => p.id != productId).toList();
    dashboard = DashboardData(
      greeting: dashboard.greeting,
      dailyScore: _calculateDailyScore(),
      streakDays: dashboard.streakDays,
      categories: _categoryCounts(),
    );
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // Scans
  // --------------------------------------------------------------------------

  Future<void> runScan({
    String skinType = 'combination',
    List<String> concerns = const ['blackheads', 'mild redness'],
    Map<String, dynamic> zoneMap = const {
      'tZone': ['blackheads'],
      'cheeks': ['redness'],
    },
  }) async {
    latestScan = {
      'skin_type': skinType,
      'concerns': concerns,
      'scan_date': DateTime.now().toIso8601String(),
      'zone_map': zoneMap,
    };
    notifyListeners();

    if (!isSignedIn) return;
    try {
      await _data.saveScanResult(
        skinType: skinType,
        concerns: concerns,
        zoneMap: zoneMap,
      );
    } catch (_) {
      // Best-effort.
    }
  }

  // --------------------------------------------------------------------------
  // Notifications
  // --------------------------------------------------------------------------

  Future<void> scheduleRoutineNotifications() async {
    final am = profile['amReminder']?.toString() ?? '07:30';
    final pm = profile['pmReminder']?.toString() ?? '20:30';
    final amParts = am.split(':');
    final pmParts = pm.split(':');
    final amHour = int.tryParse(amParts.first) ?? 7;
    final amMinute = int.tryParse(amParts.last) ?? 30;
    final pmHour = int.tryParse(pmParts.first) ?? 20;
    final pmMinute = int.tryParse(pmParts.last) ?? 30;

    final allEnabled = getNotifPref('enabled');
    final amEnabled = getNotifPref('am');
    final pmEnabled = getNotifPref('pm');

    await NotificationService.instance.cancelAll();
    if (!allEnabled) return;

    if (amEnabled) {
      await NotificationService.instance.scheduleDailyRoutineReminder(
        id: 1,
        title: 'Morning routine reminder',
        body: 'Your AM routine is waiting.',
        hour: amHour,
        minute: amMinute,
      );
    }
    if (pmEnabled) {
      await NotificationService.instance.scheduleDailyRoutineReminder(
        id: 2,
        title: 'Evening routine reminder',
        body: 'Your PM routine is waiting.',
        hour: pmHour,
        minute: pmMinute,
      );
    }
  }
}
