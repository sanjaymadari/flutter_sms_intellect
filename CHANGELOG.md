# Changelog

All notable changes to `flutter_sms_intellect` will be documented in this file.

## [0.0.3] - 2026-08-09

### Fixed

- `requestPermissions()` now waits for the user's answer instead of returning
  before the system dialog is dismissed. Previously it returned `false` on
  every first request regardless of what the user tapped.
- SMS queries moved off the platform main thread, preventing ANRs on devices
  with large message stores.
- `count` is now applied as a SQL `LIMIT` instead of reading the entire message
  store and stopping early.
- Platform replies of `null` no longer throw a type error; `getAllSms()`
  returns an empty list and the permission methods return `false`.

### Changed

- Android toolchain updated to Android Gradle Plugin 8.11.1, Kotlin 2.2.20,
  Gradle 8.14.0 and JVM target 17.
- Removed the unused `plugin_platform_interface` dependency.
- `getAllSms()` throws an `ArgumentError` for a non-positive `count`.
- New `PlatformException` codes: `ALREADY_ACTIVE` when a permission request is
  already awaiting an answer, `ACTIVITY_DETACHED` when the activity goes away
  before the user responds, and `INVALID_ARGUMENT` for a bad `count`.

### Added

- Dart unit test suite and rewritten Android unit / integration tests.
- `SmsMessage.dateTime`, `toString()`, `==` and `hashCode`.
- Dartdoc comments across the public API.

## [0.0.2] - 2025-03-01

- Added: Example usage in the example/ directory to demonstrate SMS inbox access on Android.
- No breaking changes: Core functionality remains unchanged from v0.0.1.

## [0.0.1] - 2025-03-01

### Initial Release

- Added core functionality to access the SMS inbox on Android.
- Implemented method channels for communication between Dart and native Kotlin code.
- Basic SMS retrieval support with plugin platform interface.
