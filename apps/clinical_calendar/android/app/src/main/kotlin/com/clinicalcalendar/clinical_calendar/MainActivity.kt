package com.clinicalcalendar.clinical_calendar

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
            // The engine's low-memory cleanup is asynchronous on the raster
            // task runner and requires the current graphics context. Keep the
            // rendering surface attached throughout; recycling it here creates
            // an additional EGL allocation on supported Samsung tablets.
            flutterEngine.dartExecutor.notifyLowMemoryWarning()
            flutterEngine.systemChannel.sendMemoryPressureWarning()
            window.decorView.postDelayed({
                Runtime.getRuntime().gc()
                System.runFinalization()
                Runtime.getRuntime().gc()
                result.success(null)
            }, 250)
        }
    }
}
