import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:bajatelo/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Download Video and Audio Integration Test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Enter URL (Short test video)
    final urlField = find.byType(TextField);
    expect(urlField, findsOneWidget);
    await tester.enterText(urlField, 'https://www.youtube.com/watch?v=BB49x_uMlGA');
    await tester.pumpAndSettle();

    // 2. Click Search (Buscar)
    // The button has a search_rounded icon or specific text. We can find by icon.
    final searchButton = find.byIcon(Icons.search_rounded);
    expect(searchButton, findsOneWidget);
    await tester.tap(searchButton);
    await tester.pump(); // Start fetching

    // Scroll down slowly after clicking search (for video tutorials)
    final scrollView = find.byType(SingleChildScrollView);
    if (scrollView.evaluate().isNotEmpty) {
      for (int i = 0; i < 50; i++) {
        await tester.drag(scrollView, const Offset(0, -10));
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();
    }

    // Wait until metadata appears. Check for Download Video button.
    final videoButton = find.byIcon(Icons.videocam_outlined);
    
    // We will wait up to 30 seconds for the button to appear.
    bool buttonFound = false;
    for (int i = 0; i < 30; i++) {
      if (videoButton.evaluate().isNotEmpty) {
        buttonFound = true;
        break;
      }
      await Future.delayed(const Duration(seconds: 1));
      await tester.pump();
    }
    
    if (!buttonFound) {
      fail('Download Video (MP4) button did not appear within 30s timeout. (Check logcat for 16KB crash)');
    }

    // Scroll if needed (ensure button is visible)
    await tester.ensureVisible(videoButton);

    // 4. Tap Download Video
    await tester.tap(videoButton);
    await tester.pump();

    // 5. Wait 1 min for video download
    await Future.delayed(const Duration(seconds: 60));
    await tester.pump();
    
    // The test finishes successfully if no exceptions were thrown
  });
}
