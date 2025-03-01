import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_sms_intellect_method_channel.dart';

abstract class FlutterSmsIntellectPlatform extends PlatformInterface {
  /// Constructs a FlutterSmsIntellectPlatform.
  FlutterSmsIntellectPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSmsIntellectPlatform _instance = MethodChannelFlutterSmsIntellect();

  /// The default instance of [FlutterSmsIntellectPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSmsIntellect].
  static FlutterSmsIntellectPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterSmsIntellectPlatform] when
  /// they register themselves.
  static set instance(FlutterSmsIntellectPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
