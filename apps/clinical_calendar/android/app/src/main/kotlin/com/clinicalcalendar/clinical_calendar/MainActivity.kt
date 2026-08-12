package com.clinicalcalendar.clinical_calendar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.clinicalcalendar.clinical_calendar/host_lifecycle",
        ).setMethodCallHandler { call, result ->
            if (call.method != "recreateActivity") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            result.success(null)
            runOnUiThread { recreate() }
        }
    }
}
