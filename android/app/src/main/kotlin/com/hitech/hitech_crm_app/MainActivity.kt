package com.hitech.hitech_crm_app

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FragmentActivity: required by local_auth (fingerprint / face unlock).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Optional screenshot / screen-recording block (FLAG_SECURE), turned
        // on by the Dart side for sensitive screens. See ScreenSecurity.
        MethodChannel(messenger, "com.hitech.crm/screen_security")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        if (call.argument<Boolean>("secure") == true) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Small device helpers for push notifications. See PushService.
        MethodChannel(messenger, "com.hitech.crm/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // e.g. "Samsung SM-A146B" — sent as device_name.
                    "deviceModel" -> {
                        val maker = Build.MANUFACTURER.replaceFirstChar { it.uppercase() }
                        val model = Build.MODEL
                        result.success(
                            if (model.startsWith(Build.MANUFACTURER, ignoreCase = true)) {
                                model
                            } else {
                                "$maker $model"
                            },
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
