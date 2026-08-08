// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_sms_intellect/flutter_sms_intellect.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hasPermissions reaches the platform and returns a bool',
      (WidgetTester tester) async {
    // Whether the permission is actually held depends on the device under
    // test, so only assert that the channel round-trips successfully.
    await expectLater(SmsInbox.hasPermissions(), completion(isA<bool>()));
  });

  testWidgets('getAllSms either returns messages or reports PERMISSION_DENIED',
      (WidgetTester tester) async {
    final bool granted = await SmsInbox.hasPermissions();

    if (granted) {
      final messages = await SmsInbox.getAllSms(count: 1);
      expect(messages, isA<List<SmsMessage>>());
      expect(messages.length, lessThanOrEqualTo(1));
    } else {
      await expectLater(
        SmsInbox.getAllSms(count: 1),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'PERMISSION_DENIED')),
      );
    }
  });

  testWidgets('getAllSms rejects a non-positive count',
      (WidgetTester tester) async {
    expect(() => SmsInbox.getAllSms(count: 0), throwsArgumentError);
  });
}
