package com.clinicalcalendar.clinical_calendar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private external fun purgeNativeAllocator(): Boolean

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
                purgeNativeAllocator()
                result.success(null)
            }, 250)
        }
    }

    companion object {
        init {
            System.loadLibrary("clinical_calendar_memory")
        }
    }
}
