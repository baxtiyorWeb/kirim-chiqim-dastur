import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thego_getters/features/auth/screens/auth_screen.dart';
import 'package:thego_getters/data/services/local_storage_service.dart';
import 'package:thego_getters/providers/finance_providers.dart';

void main() {
  testWidgets('AuthScreen renders Step 1 Phone Input and elements properly',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorageService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Brand Logo & Name
    expect(find.text('QarzDaftr'), findsOneWidget);
    expect(find.text('UZ'), findsOneWidget);

    // Verify Title & Subtitle
    expect(find.text('Xush kelibsiz 👋'), findsOneWidget);
    expect(find.textContaining('Telefon raqamingizni kiriting'), findsOneWidget);

    // Verify Country Code & Phone Input
    expect(find.text('+998'), findsOneWidget);
    expect(find.text('Telefon raqamingiz'), findsOneWidget);

    // Verify Continue button
    expect(find.text('Davom etish'), findsOneWidget);

    // Verify Terms RichText
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Maxfiylik siyosati'),
      ),
      findsOneWidget,
    );
  });
}
