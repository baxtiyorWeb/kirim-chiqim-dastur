import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thego_getters/core/constants/app_strings.dart';
import 'package:thego_getters/data/services/local_storage_service.dart';
import 'package:thego_getters/main.dart';
import 'package:thego_getters/providers/finance_providers.dart';

void main() {
  testWidgets('App smoke test - verifies onboarding launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = LocalStorageService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storageService),
        ],
        child: const FinanceTrackerApp(hasSeenOnboarding: false),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(AppStrings.getStarted), findsOneWidget);
    expect(find.text(AppStrings.signIn), findsOneWidget);
  });
}
