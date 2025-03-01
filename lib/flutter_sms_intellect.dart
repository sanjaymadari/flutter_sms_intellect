import 'dart:async';
import 'package:flutter/services.dart';

import 'flutter_sms_intellect_platform_interface.dart';

class FlutterSmsIntellect {
  Future<String?> getPlatformVersion() {
    return FlutterSmsIntellectPlatform.instance.getPlatformVersion();
  }
}

class SmsMessage {
  final String address;
  final String body;
  final int date;
  final bool read;
  final String type;

  SmsMessage({
    required this.address,
    required this.body,
    required this.date,
    required this.read,
    required this.type,
  });

  factory SmsMessage.fromMap(Map<dynamic, dynamic> map) {
    return SmsMessage(
      address: map['address'] ?? '',
      body: map['body'] ?? '',
      date: map['date'] ?? 0,
      read: map['read'] ?? false,
      type: map['type'] ?? '',
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
}

class SmsInbox {
  static const MethodChannel _channel = MethodChannel('flutter_sms_intellect');

  /// Request permissions to read SMS
  static Future<bool> requestPermissions() async {
    final bool result = await _channel.invokeMethod('requestPermissions');
    return result;
  }

  /// Check if app has permissions to read SMS
  static Future<bool> hasPermissions() async {
    final bool result = await _channel.invokeMethod('hasPermissions');
    return result;
  }

  /// Get all SMS messages
  static Future<List<SmsMessage>> getAllSms({
    String? address,
    int? count,
  }) async {
    final Map<String, dynamic> arguments = {
      if (address != null) 'address': address,
      if (count != null) 'count': count,
    };

    final List<dynamic> result = await _channel.invokeMethod(
      'getAllSms',
      arguments,
    );
    return result.map((dynamic item) => SmsMessage.fromMap(item)).toList();
  }
}
