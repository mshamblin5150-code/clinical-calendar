package com.clinicalcalendar.clinical_calendar

import android.content.ComponentCallbacks2
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.clinicalcalendar.clinical_calendar/memory_lifecycle",
        ).setMethodCallHandler { call, result ->
            if (call.method != "trimGallery") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            result.success(null)
            window.decorView.post {
                onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_COMPLETE)
                Runtime.getRuntime().gc()
            }
        }
    }
}
