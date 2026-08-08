package com.sanjaymadari.flutter_sms_intellect

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import org.mockito.Mockito

/*
 * Unit tests for the parts of the plugin that don't need a live Android
 * framework. Anything touching the SMS content provider or the permission
 * dialog is covered by the integration test in `example/integration_test`.
 *
 * Once you have built the plugin's example app, you can run these tests from
 * the command line by running `./gradlew :flutter_sms_intellect:testDebugUnitTest`
 * in the `example/android/` directory, or from an IDE that supports JUnit.
 */
internal class FlutterSmsIntellectPluginTest {

  @Test
  fun onMethodCall_unknownMethod_reportsNotImplemented() {
    val plugin = FlutterSmsIntellectPlugin()
    val result = Mockito.mock(MethodChannel.Result::class.java)

    plugin.onMethodCall(MethodCall("someUnsupportedMethod", null), result)

    Mockito.verify(result).notImplemented()
    Mockito.verifyNoMoreInteractions(result)
  }

  @Test
  fun onMethodCall_getPlatformVersion_isNoLongerSupported() {
    // Guards against the pre-0.0.2 API being reintroduced by accident.
    val plugin = FlutterSmsIntellectPlugin()
    val result = Mockito.mock(MethodChannel.Result::class.java)

    plugin.onMethodCall(MethodCall("getPlatformVersion", null), result)

    Mockito.verify(result).notImplemented()
  }

  @Test
  fun onRequestPermissionsResult_ignoresForeignRequestCodes() {
    val plugin = FlutterSmsIntellectPlugin()

    val handled = plugin.onRequestPermissionsResult(
      /* requestCode = */ 999,
      arrayOf("android.permission.READ_SMS"),
      intArrayOf(0)
    )

    assertFalse(handled, "A request code the plugin never issued must not be consumed")
  }

  @Test
  fun onRequestPermissionsResult_consumesItsOwnRequestCode() {
    val plugin = FlutterSmsIntellectPlugin()

    val handled = plugin.onRequestPermissionsResult(
      /* requestCode = */ 123,
      arrayOf("android.permission.READ_SMS"),
      intArrayOf(0)
    )

    assertTrue(handled, "The plugin must consume the result for its own request code")
  }
}
