import 'dart:async';

import 'package:flutter/services.dart';

/// A single SMS message read from the device's message store.
class SmsMessage {
  /// The phone number or alphanumeric sender id the message was exchanged with.
  final String address;

  /// The message text.
  final String body;

  /// Time the message was received or sent, in milliseconds since epoch.
  ///
  /// Convert with [DateTime.fromMillisecondsSinceEpoch].
  final int date;

  /// Whether the message has been marked as read on the device.
  final bool read;

  /// The message box this message lives in.
  ///
  /// One of `inbox`, `sent`, `draft`, `outbox`, `failed`, `queued` or
  /// `unknown`.
  final String type;

  const SmsMessage({
    required this.address,
    required this.body,
    required this.date,
    required this.read,
    required this.type,
  });

  /// Builds an [SmsMessage] from the map sent by the platform channel.
  factory SmsMessage.fromMap(Map<dynamic, dynamic> map) {
    return SmsMessage(
      address: map['address'] as String? ?? '',
      body: map['body'] as String? ?? '',
      date: (map['date'] as num?)?.toInt() ?? 0,
      read: map['read'] as bool? ?? false,
      type: map['type'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'body': body,
      'date': date,
      'read': read,
      'type': type,
    };
  }

  /// The [date] as a [DateTime].
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(date);

  @override
  String toString() =>
      'SmsMessage(address: $address, date: $date, read: $read, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsMessage &&
          other.address == address &&
          other.body == body &&
          other.date == date &&
          other.read == read &&
          other.type == type;

  @override
  int get hashCode => Object.hash(address, body, date, read, type);
}

/// Reads SMS messages from the device inbox.
///
/// Android only. Every method throws a [MissingPluginException] on other
/// platforms, so guard calls with a `Platform.isAndroid` check if your app is
/// multi-platform.
class SmsInbox {
  SmsInbox._();

  static const MethodChannel _channel = MethodChannel('flutter_sms_intellect');

  /// Shows the system `READ_SMS` permission dialog and resolves once the user
  /// answers it.
  ///
  /// Returns `true` if the permission is granted. Resolves immediately with
  /// `true` when the permission was already granted.
  ///
  /// Throws a [PlatformException] with code `ACTIVITY_NULL` if the plugin is
  /// not currently attached to an activity, `ALREADY_ACTIVE` if another request
  /// is still awaiting an answer, or `ACTIVITY_DETACHED` if the activity goes
  /// away before the user responds.
  static Future<bool> requestPermissions() async {
    final bool? result = await _channel.invokeMethod<bool>('requestPermissions');
    return result ?? false;
  }

  /// Whether the app currently holds the `READ_SMS` permission.
  static Future<bool> hasPermissions() async {
    final bool? result = await _channel.invokeMethod<bool>('hasPermissions');
    return result ?? false;
  }

  /// Reads messages from the device, newest first.
  ///
  /// Pass [address] to return only messages exchanged with that number, and
  /// [count] to cap how many are returned. Omitting [count] reads the entire
  /// message store, which can be slow on devices with large histories.
  ///
  /// Throws a [PlatformException] with code `PERMISSION_DENIED` if the
  /// `READ_SMS` permission has not been granted.
  static Future<List<SmsMessage>> getAllSms({String? address, int? count}) async {
    if (count != null && count <= 0) {
      throw ArgumentError.value(count, 'count', 'must be greater than zero');
    }

    final List<dynamic>? result = await _channel.invokeMethod<List<dynamic>>(
      'getAllSms',
      <String, dynamic>{
        if (address != null) 'address': address,
        if (count != null) 'count': count,
      },
    );

    return result
            ?.map((dynamic item) =>
                SmsMessage.fromMap(item as Map<dynamic, dynamic>))
            .toList() ??
        <SmsMessage>[];
  }
}
