import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for Indonesian date formatting.
  await initializeDateFormatting('id_ID', null);

  // Initialize local notifications.
  await NotificationService.instance.initialize();

  runApp(
    // Wrap with ProviderScope to enable Riverpod.
    const ProviderScope(
      child: CampusTaskApp(),
    ),
  );
}

class CampusTaskApp extends StatelessWidget {
  const CampusTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusTask',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
