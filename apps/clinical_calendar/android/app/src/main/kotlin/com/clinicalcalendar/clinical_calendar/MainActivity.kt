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
            // The engine's low-memory cleanup is asynchronous on the raster
            // task runner and requires the current graphics context. Keep the
            // rendering surface attached throughout; recycling it here creates
            // an additional EGL allocation on supported Samsung tablets.
            flutterEngine.dartExecutor.notifyLowMemoryWarning()
            flutterEngine.systemChannel.sendMemoryPressureWarning()
            // The direct engine notifications release Dart/image resources,
            // while the renderer callback releases registered graphics
            // resources. Android normally delivers this callback only under
            // system pressure, so Gallery cleanup must request both halves.
            flutterEngine.renderer.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_COMPLETE)
            window.decorView.postDelayed({
                Runtime.getRuntime().gc()
                result.success(null)
            }, 250)
        }
    }
}
