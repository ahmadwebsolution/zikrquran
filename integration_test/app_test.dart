import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zikrquran/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ZikrQuran End-to-End Integration Tests', () {
    testWidgets('Complete user flow: Splash -> Guest Login -> Browse Surahs & Paras -> Search -> Surah Detail & Bookmark', (WidgetTester tester) async {
      // 1. Launch the application
      app.main();
      await tester.pumpAndSettle();

      // Wait for 2-second SplashView delay to finish
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // 2. Check if Login Screen or Home Screen is displayed
      final guestButton = find.text('Continue as Guest (Read Quran)');
      if (guestButton.evaluate().isNotEmpty) {
        // Tap "Continue as Guest" to enter the app
        await tester.tap(guestButton);
        await tester.pumpAndSettle();
      }

      // 3. Verify HomeView is visible
      expect(find.text('Surahs (114)'), findsOneWidget);
      expect(find.text('Paras / Juz (30)'), findsOneWidget);

      // Verify Surah Al-Faatiha is present in the list
      expect(find.text('Al-Faatiha'), findsOneWidget);

      // 4. Test Tab Switching: Switch to Paras / Juz tab
      await tester.tap(find.text('Paras / Juz (30)'));
      await tester.pumpAndSettle();

      // Verify Para 1 is displayed
      expect(find.text('Para 1 • Alif-Laam-Meem'), findsOneWidget);

      // Switch back to Surahs tab
      await tester.tap(find.text('Surahs (114)'));
      await tester.pumpAndSettle();

      // 5. Test Search Bar functionality
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Type "Ikhlas" in search
      await tester.enterText(searchField, 'Ikhlas');
      await tester.pumpAndSettle();

      // Surah Al-Ikhlas should appear
      expect(find.text('Al-Ikhlaas'), findsOneWidget);

      // 6. Open Surah Detail View
      await tester.tap(find.text('Al-Ikhlaas'));
      await tester.pumpAndSettle();

      // Verify Surah details screen loaded
      expect(find.text('Al-Ikhlaas'), findsWidgets);
      // Wait for Ayahs to load
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Verify Arabic Bismillah and Ayah texts are displayed
      expect(find.byType(ListView), findsOneWidget);

      // 7. Test Bookmark feature on Ayah
      final bookmarkIcon = find.byIcon(Icons.bookmark_border);
      if (bookmarkIcon.evaluate().isNotEmpty) {
        await tester.tap(bookmarkIcon.first);
        await tester.pumpAndSettle();

        // Icon should change to active bookmark
        expect(find.byIcon(Icons.bookmark), findsWidgets);
      }

      // 8. Navigate back to Home
      final backButton = find.byType(BackButton);
      final backIcon = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      } else if (backIcon.evaluate().isNotEmpty) {
        await tester.tap(backIcon);
      } else {
        await tester.pageBack();
      }
      await tester.pumpAndSettle();

      // 9. Clear Search field
      final clearIcon = find.byIcon(Icons.clear);
      if (clearIcon.evaluate().isNotEmpty) {
        await tester.tap(clearIcon);
      } else {
        await tester.enterText(searchField, '');
      }
      await tester.pumpAndSettle();

      // 10. Open Bookmarks screen from AppBar
      final bookmarksAppBarButton = find.byTooltip('Bookmarks');
      expect(bookmarksAppBarButton, findsOneWidget);
      await tester.tap(bookmarksAppBarButton);
      await tester.pumpAndSettle();

      // Verify Bookmarks Screen loaded
      expect(find.text('Saved Bookmarks'), findsOneWidget);
    });
  });
}
