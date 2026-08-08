// Widget tests for the example app.
//
// The plugin's platform channel is mocked, so these run on the host machine
// without a device.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_sms_intellect_example/main.dart';

void main() {
  const channel = MethodChannel('flutter_sms_intellect');

  /// Serves [hasPermissions] and [messages] to the example app.
  void mockPlugin({
    required bool hasPermissions,
    List<Map<String, Object?>> messages = const [],
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'hasPermissions':
        case 'requestPermissions':
          return hasPermissions;
        case 'getAllSms':
          return messages;
        default:
          return null;
      }
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('prompts for permission when it has not been granted',
      (WidgetTester tester) async {
    mockPlugin(hasPermissions: false);

    await tester.pumpWidget(const MyApp());
    await tester.pump(); // resolve hasPermissions()
    await tester.pump(); // rebuild with the result

    expect(find.text('SMS permissions required to read messages'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Request Permissions'),
        findsOneWidget);
  });

  testWidgets('lists messages once permission is granted',
      (WidgetTester tester) async {
    mockPlugin(
      hasPermissions: true,
      messages: <Map<String, Object?>>[
        <String, Object?>{
          'address': '+15551234567',
          'body': 'Your OTP is 123456',
          'date': 1740787200000,
          'read': false,
          'type': 'inbox',
        },
      ],
    );

    await tester.pumpWidget(const MyApp());
    await tester.pump(); // resolve hasPermissions()
    await tester.pump(); // show SmsInboxPage, which starts loadMessages()
    await tester.pump(); // resolve getAllSms()
    await tester.pump(); // rebuild with the messages

    expect(find.text('+15551234567'), findsOneWidget);
    expect(find.text('Your OTP is 123456'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no messages',
      (WidgetTester tester) async {
    mockPlugin(hasPermissions: true);

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('No messages found'), findsOneWidget);
  });
}
