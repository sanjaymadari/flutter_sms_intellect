import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sms_intellect/flutter_sms_intellect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_sms_intellect');
  final log = <MethodCall>[];

  /// Answers [channel] with [handler], recording every call in [log].
  void mockChannel(Future<Object?>? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) {
      log.add(call);
      return handler(call);
    });
  }

  setUp(log.clear);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('SmsMessage', () {
    test('fromMap reads every field', () {
      final message = SmsMessage.fromMap(<dynamic, dynamic>{
        'address': '+15551234567',
        'body': 'hello',
        'date': 1740787200000,
        'read': true,
        'type': 'inbox',
      });

      expect(message.address, '+15551234567');
      expect(message.body, 'hello');
      expect(message.date, 1740787200000);
      expect(message.read, isTrue);
      expect(message.type, 'inbox');
    });

    test('fromMap falls back to defaults on missing or null fields', () {
      final message = SmsMessage.fromMap(<dynamic, dynamic>{'address': null});

      expect(message.address, '');
      expect(message.body, '');
      expect(message.date, 0);
      expect(message.read, isFalse);
      expect(message.type, 'unknown');
    });

    test('fromMap accepts a date sent as any num', () {
      expect(
        SmsMessage.fromMap(<dynamic, dynamic>{'date': 1740787200000.0}).date,
        1740787200000,
      );
    });

    test('toMap round-trips through fromMap', () {
      const original = SmsMessage(
        address: '+15551234567',
        body: 'hello',
        date: 1740787200000,
        read: true,
        type: 'sent',
      );

      expect(SmsMessage.fromMap(original.toMap()), original);
    });

    test('dateTime converts the epoch millis', () {
      const message = SmsMessage(
        address: '',
        body: '',
        date: 1740787200000,
        read: false,
        type: 'inbox',
      );

      expect(message.dateTime, DateTime.fromMillisecondsSinceEpoch(1740787200000));
    });
  });

  group('hasPermissions', () {
    test('returns the platform answer', () async {
      mockChannel((_) async => true);
      expect(await SmsInbox.hasPermissions(), isTrue);
      expect(log.single.method, 'hasPermissions');
    });

    test('returns false when the platform replies null', () async {
      mockChannel((_) async => null);
      expect(await SmsInbox.hasPermissions(), isFalse);
    });
  });

  group('requestPermissions', () {
    test('returns the granted result', () async {
      mockChannel((_) async => true);
      expect(await SmsInbox.requestPermissions(), isTrue);
      expect(log.single.method, 'requestPermissions');
    });

    test('returns false when the platform replies null', () async {
      mockChannel((_) async => null);
      expect(await SmsInbox.requestPermissions(), isFalse);
    });

    test('propagates a platform error', () {
      mockChannel((_) async {
        throw PlatformException(code: 'ACTIVITY_NULL');
      });

      expect(SmsInbox.requestPermissions(), throwsA(isA<PlatformException>()));
    });
  });

  group('getAllSms', () {
    final platformMessages = <Map<dynamic, dynamic>>[
      <dynamic, dynamic>{
        'address': '+15551234567',
        'body': 'first',
        'date': 1740787200000,
        'read': true,
        'type': 'inbox',
      },
      <dynamic, dynamic>{
        'address': '+15559876543',
        'body': 'second',
        'date': 1740700800000,
        'read': false,
        'type': 'sent',
      },
    ];

    test('maps the platform list into SmsMessage objects', () async {
      mockChannel((_) async => platformMessages);

      final messages = await SmsInbox.getAllSms();

      expect(messages, hasLength(2));
      expect(messages.first.body, 'first');
      expect(messages.last.type, 'sent');
    });

    test('sends no arguments when address and count are omitted', () async {
      mockChannel((_) async => <dynamic>[]);

      await SmsInbox.getAllSms();

      expect(log.single.arguments, <String, dynamic>{});
    });

    test('forwards address and count', () async {
      mockChannel((_) async => <dynamic>[]);

      await SmsInbox.getAllSms(address: '+15551234567', count: 10);

      expect(log.single.arguments, <String, dynamic>{
        'address': '+15551234567',
        'count': 10,
      });
    });

    test('returns an empty list when the platform replies null', () async {
      mockChannel((_) async => null);
      expect(await SmsInbox.getAllSms(), isEmpty);
    });

    test('rejects a non-positive count without calling the platform', () {
      mockChannel((_) async => <dynamic>[]);

      expect(() => SmsInbox.getAllSms(count: 0), throwsArgumentError);
      expect(() => SmsInbox.getAllSms(count: -1), throwsArgumentError);
      expect(log, isEmpty);
    });

    test('propagates a permission error', () {
      mockChannel((_) async {
        throw PlatformException(code: 'PERMISSION_DENIED');
      });

      expect(
        SmsInbox.getAllSms(),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'PERMISSION_DENIED')),
      );
    });
  });
}
