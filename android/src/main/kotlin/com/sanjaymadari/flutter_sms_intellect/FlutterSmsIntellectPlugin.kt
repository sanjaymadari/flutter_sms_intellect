// package com.sanjaymadari.flutter_sms_intellect

// import io.flutter.embedding.engine.plugins.FlutterPlugin
// import io.flutter.plugin.common.MethodCall
// import io.flutter.plugin.common.MethodChannel
// import io.flutter.plugin.common.MethodChannel.MethodCallHandler
// import io.flutter.plugin.common.MethodChannel.Result

// /** FlutterSmsIntellectPlugin */
// class FlutterSmsIntellectPlugin: FlutterPlugin, MethodCallHandler {
//   /// The MethodChannel that will the communication between Flutter and native Android
//   ///
//   /// This local reference serves to register the plugin with the Flutter Engine and unregister it
//   /// when the Flutter Engine is detached from the Activity
//   private lateinit var channel : MethodChannel

//   override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
//     channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_sms_intellect")
//     channel.setMethodCallHandler(this)
//   }

//   override fun onMethodCall(call: MethodCall, result: Result) {
//     if (call.method == "getPlatformVersion") {
//       result.success("Android ${android.os.Build.VERSION.RELEASE}")
//     } else {
//       result.notImplemented()
//     }
//   }

//   override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
//     channel.setMethodCallHandler(null)
//   }
// }

package com.sanjaymadari.flutter_sms_intellect

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
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
import java.util.*

class FlutterSmsIntellectPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null

  private val PERMISSION_REQUEST_CODE = 123

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_sms_intellect")
    context = flutterPluginBinding.applicationContext
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "requestPermissions" -> {
        requestSmsPermission(result)
      }
      "hasPermissions" -> {
        result.success(hasReadSmsPermission())
      }
      "getAllSms" -> {
        val address = call.argument<String>("address")
        val count = call.argument<Int>("count")
        getAllSms(result, address, count)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun requestSmsPermission(result: Result) {
    if (hasReadSmsPermission()) {
      result.success(true)
      return
    }

    activity?.let {
      ActivityCompat.requestPermissions(
        it,
        arrayOf(Manifest.permission.READ_SMS),
        PERMISSION_REQUEST_CODE
      )
      result.success(hasReadSmsPermission())
    } ?: run {
      result.error("ACTIVITY_NULL", "Activity is null", null)
    }
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

    val messages = mutableListOf<Map<String, Any>>()
    val uri = Telephony.Sms.CONTENT_URI
    val projection = arrayOf(
      Telephony.Sms._ID,
      Telephony.Sms.ADDRESS,
      Telephony.Sms.BODY,
      Telephony.Sms.DATE,
      Telephony.Sms.READ,
      Telephony.Sms.TYPE
    )

    val selection = if (address != null) "${Telephony.Sms.ADDRESS} = ?" else null
    val selectionArgs = if (address != null) arrayOf(address) else null
    
    val sortOrder = "${Telephony.Sms.DATE} DESC"

    var cursor: Cursor? = null
    try {
      cursor = context.contentResolver.query(
        uri,
        projection,
        selection,
        selectionArgs,
        sortOrder
      )

      cursor?.let {
        val addressIndex = it.getColumnIndex(Telephony.Sms.ADDRESS)
        val bodyIndex = it.getColumnIndex(Telephony.Sms.BODY)
        val dateIndex = it.getColumnIndex(Telephony.Sms.DATE)
        val readIndex = it.getColumnIndex(Telephony.Sms.READ)
        val typeIndex = it.getColumnIndex(Telephony.Sms.TYPE)

        val utcFormat = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
        utcFormat.timeZone = java.util.TimeZone.getTimeZone("UTC")

        var counter = 0
        while (it.moveToNext()) {
          if (count != null && counter >= count) break

          val dateMillis = if (dateIndex >= 0) it.getLong(dateIndex) else 0
          val dateUtc = utcFormat.format(java.util.Date(dateMillis))
          
          val message = mapOf(
            "address" to (if (addressIndex >= 0) it.getString(addressIndex) else ""),
            "body" to (if (bodyIndex >= 0) it.getString(bodyIndex) else ""),
            "date" to dateUtc,  // Now in UTC string format
            "read" to (if (readIndex >= 0) it.getInt(readIndex) == 1 else false),
            "type" to (if (typeIndex >= 0) getSmsTypeName(it.getInt(typeIndex)) else "")
          )
          
          messages.add(message)
          counter++
        }
      }
      
      result.success(messages)
    } catch (e: Exception) {
      result.error("QUERY_ERROR", e.message, null)
    } finally {
      cursor?.close()
    }
  }

  private fun getSmsTypeName(type: Int): String {
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
