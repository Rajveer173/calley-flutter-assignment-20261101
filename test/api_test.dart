import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:calley_assignment/api.dart';
import 'package:calley_assignment/main.dart';
import 'package:flutter/material.dart';

void main() {
  test('login uses API profile and lists use returned user ID', () async {
    final api = CalleyApi(
      client: MockClient((r) async {
        if (r.url.path.endsWith('/login')) {
          expect(jsonDecode(r.body)['email'], 'a@example.test');
          return http.Response(
            jsonEncode({
              'user': {
                '_id': 'actual-user',
                'username': 'A',
                'email': 'a@example.test',
              },
            }),
            200,
          );
        }
        expect(r.url.queryParameters['userId'], 'actual-user');
        return http.Response('{"_id":"list-1","name":"My List"}', 200);
      }),
    );
    final user = await api.login('a@example.test', 'secret');
    expect((await api.lists(user.id)).single.id, 'list-1');
  });
  test('server and malformed JSON errors are handled', () async {
    final denied = CalleyApi(
      client: MockClient(
        (_) async => http.Response('{"message":"Invalid OTP"}', 400),
      ),
    );
    await expectLater(
      denied.verifyOtp('a@example.test', '111111'),
      throwsA(
        isA<ApiError>().having((e) => e.message, 'message', 'Invalid OTP'),
      ),
    );
    final broken = CalleyApi(
      client: MockClient((_) async => http.Response('<html>', 500)),
    );
    await expectLater(broken.lists('u'), throwsA(isA<ApiError>()));
  });
  test('totals use API counters and handle empty lists', () {
    expect(
      CallSummary.fromJson({
        'pending': 27,
        'called': 23,
        'rescheduled': 11,
        'calls': [],
      }).total,
      61,
    );
    expect(CallSummary.fromJson({}).total, 0);
  });
  testWidgets('demo registration, OTP and calling-list dashboard', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(CalleyApp(api: CalleyApi(demo: true)));
    await t.tap(find.text('Select'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextFormField, 'Name'), 'Alex');
    await t.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'alex@example.test',
    );
    await t.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'test-password',
    );
    await t.ensureVisible(find.text('Sign Up'));
    t.testTextInput.hide();
    await t.pumpAndSettle();
    await t.tap(find.text('Sign Up'));
    await t.pumpAndSettle();
    expect(find.text('OTP Verification'), findsOneWidget);
    await t.enterText(find.byType(TextField), '123456');
    await t.ensureVisible(find.text('Verify'));
    await t.tap(find.text('Verify'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Start Calling Now'), 200);
    await t.tap(find.text('Start Calling Now'));
    await t.pumpAndSettle();
    await t.tap(find.text('Start Calling Now'));
    await t.pumpAndSettle();
    await t.tap(find.text('Test List'));
    await t.pumpAndSettle();
    expect(find.text('61 CALLS'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
