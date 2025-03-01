import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_sms_intellect_platform_interface.dart';

/// An implementation of [FlutterSmsIntellectPlatform] that uses method channels.
class MethodChannelFlutterSmsIntellect extends FlutterSmsIntellectPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_sms_intellect');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
