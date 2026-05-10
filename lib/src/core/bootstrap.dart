import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/notification_service.dart';
import 'config.dart';

Future<void> bootstrap() async {
  try {
    await dotenv.load(fileName: '.env');
    RuntimeFlags.dotenvLoaded = true;
  } catch (_) {
    // .env not bundled — continue with defaults.
    RuntimeFlags.dotenvLoaded = false;
  }

  if (AppConfig.hasSupabase) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      RuntimeFlags.supabaseInitialized = true;
    } catch (_) {
      RuntimeFlags.supabaseInitialized = false;
    }
  }

  if (!kIsWeb) {
    try {
      await NotificationService.instance.init(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
    } catch (_) {
      // Notifications optional on web/desktop.
    }
  }
}
