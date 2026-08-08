# flutter_sms_intellect

A modern Flutter plugin for accessing the SMS inbox on Android devices.

## Features

- Read SMS messages from the device's message store, newest first.
- Filter by sender address and cap the number of messages returned.
- Request and check the `READ_SMS` runtime permission.
- Queries run off the platform main thread, so large inboxes don't block the UI.

> **Android only.** Reading SMS is not permitted on iOS. Calls on other
> platforms throw a `MissingPluginException`.

## Installation

Add `flutter_sms_intellect` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_sms_intellect: ^0.0.3
```

## Android setup

The plugin's manifest already declares `READ_SMS`, so it is merged into your
app automatically. `READ_SMS` is a runtime permission, so you must still ask
for it before reading messages.

Google Play restricts the `READ_SMS` permission. Apps that are not the user's
default SMS handler need an approved [Permissions Declaration][play-sms] before
they can be published.

[play-sms]: https://support.google.com/googleplay/android-developer/answer/10208820

## Usage

```dart
import 'package:flutter_sms_intellect/flutter_sms_intellect.dart';

// 1. Make sure you have permission.
if (!await SmsInbox.hasPermissions()) {
  final granted = await SmsInbox.requestPermissions();
  if (!granted) return;
}

// 2. Read the 50 most recent messages.
final messages = await SmsInbox.getAllSms(count: 50);

for (final message in messages) {
  print('${message.address} @ ${message.dateTime}: ${message.body}');
}

// 3. Or read only messages from one sender.
final fromBank = await SmsInbox.getAllSms(address: '+15551234567');
```

### `SmsMessage`

| Field      | Type       | Description                                                            |
| ---------- | ---------- | ---------------------------------------------------------------------- |
| `address`  | `String`   | Phone number or sender id the message was exchanged with.               |
| `body`     | `String`   | Message text.                                                           |
| `date`     | `int`      | Milliseconds since epoch. Also available as `dateTime`.                 |
| `read`     | `bool`     | Whether the message is marked read on the device.                       |
| `type`     | `String`   | `inbox`, `sent`, `draft`, `outbox`, `failed`, `queued` or `unknown`.    |

### Errors

`getAllSms` and the permission methods throw a `PlatformException`:

| Code                 | Meaning                                                        |
| -------------------- | -------------------------------------------------------------- |
| `PERMISSION_DENIED`  | `READ_SMS` has not been granted.                                |
| `ACTIVITY_NULL`      | The plugin is not attached to an activity.                      |
| `ALREADY_ACTIVE`     | A permission request is already awaiting the user's answer.     |
| `ACTIVITY_DETACHED`  | The activity went away before the permission dialog was closed. |
| `INVALID_ARGUMENT`   | `count` was not greater than zero.                              |
| `QUERY_ERROR`        | The underlying content provider query failed.                   |

Passing a non-positive `count` throws an `ArgumentError` before reaching the
platform.

## Example

A runnable example lives in [`example/`](example). It builds against the plugin
source in this repository:

```bash
cd example
flutter run
```

## Testing

```bash
flutter test                                                  # Dart unit tests
cd example/android && ./gradlew :flutter_sms_intellect:testDebugUnitTest
cd example && flutter test integration_test                   # on a device
```

## License

[MIT](LICENSE)
