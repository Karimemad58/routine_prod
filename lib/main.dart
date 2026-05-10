import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/core/bootstrap.dart';
import 'src/features/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..initialize(),
      child: const RoutineApp(),
    ),
  );
}
