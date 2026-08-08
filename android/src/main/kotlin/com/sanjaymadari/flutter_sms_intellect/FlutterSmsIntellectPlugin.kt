package com.sanjaymadari.flutter_sms_intellect

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.Executors

class FlutterSmsIntellectPlugin :
  FlutterPlugin,
  MethodCallHandler,
  ActivityAware,
  PluginRegistry.RequestPermissionsResultListener {

  private lateinit var channel: MethodChannel
  private lateinit var context: Context

  private var activity: Activity? = null
  private var activityBinding: ActivityPluginBinding? = null

  /** Held between [requestSmsPermission] and [onRequestPermissionsResult]. */
  private var pendingPermissionResult: Result? = null

  /** SMS queries hit the content provider, so they must stay off the main thread. */
  private val queryExecutor = Executors.newSingleThreadExecutor()

  // Lazy so that constructing the plugin doesn't touch the Android framework,
  // which keeps it usable from plain JVM unit tests.
  private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

  private companion object {
    const val PERMISSION_REQUEST_CODE = 123
    const val CHANNEL_NAME = "flutter_sms_intellect"
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
    context = flutterPluginBinding.applicationContext
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    queryExecutor.shutdown()
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    attachActivity(binding)
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    attachActivity(binding)
  }

  override fun onDetachedFromActivity() {
    detachActivity()
  }

  override fun onDetachedFromActivityForConfigChanges() {
    detachActivity()
  }

  private fun attachActivity(binding: ActivityPluginBinding) {
    activityBinding = binding
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  private fun detachActivity() {
    activityBinding?.removeRequestPermissionsResultListener(this)
    activityBinding = null
    activity = null
    // The dialog can no longer report back, so don't leave Dart awaiting forever.
    pendingPermissionResult?.error(
      "ACTIVITY_DETACHED",
      "Activity was detached before the permission dialog was answered",
      null
    )
    pendingPermissionResult = null
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "requestPermissions" -> requestSmsPermission(result)
      "hasPermissions" -> result.success(hasReadSmsPermission())
      "getAllSms" -> getAllSms(
        result,
        call.argument<String>("address"),
        call.argument<Int>("count")
      )
      else -> result.notImplemented()
    }
  }

  private fun requestSmsPermission(result: Result) {
    if (hasReadSmsPermission()) {
      result.success(true)
      return
    }

    val currentActivity = activity
    if (currentActivity == null) {
      result.error("ACTIVITY_NULL", "Activity is null", null)
      return
    }

    if (pendingPermissionResult != null) {
      result.error(
        "ALREADY_ACTIVE",
        "A permission request is already in progress",
        null
      )
      return
    }

    pendingPermissionResult = result
    ActivityCompat.requestPermissions(
      currentActivity,
      arrayOf(Manifest.permission.READ_SMS),
      PERMISSION_REQUEST_CODE
    )
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ): Boolean {
    if (requestCode != PERMISSION_REQUEST_CODE) return false

    val granted = grantResults.isNotEmpty() &&
      grantResults[0] == PackageManager.PERMISSION_GRANTED
    pendingPermissionResult?.success(granted)
    pendingPermissionResult = null
    return true
  }

  private fun hasReadSmsPermission(): Boolean {
    return ContextCompat.checkSelfPermission(
      context,
      Manifest.permission.READ_SMS
    ) == PackageManager.PERMISSION_GRANTED
  }

  private fun getAllSms(result: Result, address: String?, count: Int?) {
    if (!hasReadSmsPermission()) {
      result.error("PERMISSION_DENIED", "SMS permission not granted", null)
      return
    }

    if (count != null && count <= 0) {
      result.error("INVALID_ARGUMENT", "count must be greater than zero", null)
      return
    }

    queryExecutor.execute {
      try {
        val messages = querySms(address, count)
        mainHandler.post { result.success(messages) }
      } catch (e: Exception) {
        mainHandler.post { result.error("QUERY_ERROR", e.message, null) }
      }
    }
  }

  private fun querySms(address: String?, count: Int?): List<Map<String, Any>> {
    val projection = arrayOf(
      Telephony.Sms.ADDRESS,
      Telephony.Sms.BODY,
      Telephony.Sms.DATE,
      Telephony.Sms.READ,
      Telephony.Sms.TYPE
    )

    val selection = if (address != null) "${Telephony.Sms.ADDRESS} = ?" else null
    val selectionArgs = if (address != null) arrayOf(address) else null

    // Bound the row count in SQL rather than reading the whole inbox and stopping early.
    val sortOrder = buildString {
      append("${Telephony.Sms.DATE} DESC")
      if (count != null) append(" LIMIT $count")
    }

    val messages = mutableListOf<Map<String, Any>>()

    context.contentResolver.query(
      Telephony.Sms.CONTENT_URI,
      projection,
      selection,
      selectionArgs,
      sortOrder
    )?.use { cursor ->
      val addressIndex = cursor.getColumnIndex(Telephony.Sms.ADDRESS)
      val bodyIndex = cursor.getColumnIndex(Telephony.Sms.BODY)
      val dateIndex = cursor.getColumnIndex(Telephony.Sms.DATE)
      val readIndex = cursor.getColumnIndex(Telephony.Sms.READ)
      val typeIndex = cursor.getColumnIndex(Telephony.Sms.TYPE)

      while (cursor.moveToNext()) {
        messages.add(
          mapOf(
            "address" to if (addressIndex >= 0) cursor.getString(addressIndex).orEmpty() else "",
            "body" to if (bodyIndex >= 0) cursor.getString(bodyIndex).orEmpty() else "",
            "date" to if (dateIndex >= 0) cursor.getLong(dateIndex) else 0L,
            "read" to if (readIndex >= 0) cursor.getInt(readIndex) == 1 else false,
            "type" to if (typeIndex >= 0) smsTypeName(cursor.getInt(typeIndex)) else "unknown"
          )
        )
      }
    }

    return messages
  }

  private fun smsTypeName(type: Int): String {
    return when (type) {
      Telephony.Sms.MESSAGE_TYPE_INBOX -> "inbox"
      Telephony.Sms.MESSAGE_TYPE_SENT -> "sent"
      Telephony.Sms.MESSAGE_TYPE_DRAFT -> "draft"
      Telephony.Sms.MESSAGE_TYPE_OUTBOX -> "outbox"
      Telephony.Sms.MESSAGE_TYPE_FAILED -> "failed"
      Telephony.Sms.MESSAGE_TYPE_QUEUED -> "queued"
      else -> "unknown"
    }
  }
}
