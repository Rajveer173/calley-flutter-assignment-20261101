import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:calley_assignment/main.dart';
import 'package:calley_assignment/api.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android demo walkthrough', (t) async {
    await t.pumpWidget(CalleyApp(api: CalleyApi(demo: true)));
    await t.pumpAndSettle();
    // The local recording helper starts Android screenrecord at this marker.
    debugPrint('CAPTURE_READY');
    await Future<void>.delayed(const Duration(seconds: 6));
    await t.tap(find.text('Select')); await t.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 2));
    await t.enterText(find.widgetWithText(TextFormField, 'Name'), 'Alex');
    await t.enterText(find.widgetWithText(TextFormField, 'Email address'), 'alex@example.test');
    await t.enterText(find.widgetWithText(TextFormField, 'Password'), 'demo-password');
    FocusManager.instance.primaryFocus?.unfocus(); await t.pumpAndSettle();
    await t.ensureVisible(find.text('Sign Up')); await t.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 2));
    await t.tap(find.text('Sign Up')); await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), '123456');
    FocusManager.instance.primaryFocus?.unfocus(); await t.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 3));
    await t.ensureVisible(find.text('Verify')); await t.tap(find.text('Verify')); await t.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 3));
    await t.scrollUntilVisible(find.text('Start Calling Now'), 200); await t.pumpAndSettle();
    await t.tap(find.text('Start Calling Now')); await t.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 3));
    await t.tap(find.text('Start Calling Now')); await t.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 2));
    await t.tap(find.text('Test List')); await t.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 5));
    expect(find.text('61 CALLS'), findsOneWidget);
    await t.tap(find.byTooltip('Open navigation menu')); await t.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 4));
    expect(find.text('alex@example.test'), findsOneWidget);
  });
}
