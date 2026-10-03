import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/local_storage_service.dart';
import 'providers/finance_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Status Bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize offline storage service
  final storageService = await LocalStorageService.init();

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storageService),
      ],
      child: FinanceTrackerApp(
        hasSeenOnboarding: storageService.hasSeenOnboarding,
      ),
    ),
  );
}

class FinanceTrackerApp extends ConsumerStatefulWidget {
  final bool hasSeenOnboarding;

  const FinanceTrackerApp({
    super.key,
    required this.hasSeenOnboarding,
  });

  @override
  ConsumerState<FinanceTrackerApp> createState() => _FinanceTrackerAppState();
}

class _FinanceTrackerAppState extends ConsumerState<FinanceTrackerApp> {
  late final _router = AppRouter.createRouter(
    hasSeenOnboarding: widget.hasSeenOnboarding,
  );

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Moliya - Shaxsiy Xarajatlar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
