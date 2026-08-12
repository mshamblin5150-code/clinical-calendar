package com.clinicalcalendar.clinical_calendar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterSurfaceView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var flutterSurfaceView: FlutterSurfaceView? = null

    override fun onFlutterSurfaceViewCreated(flutterSurfaceView: FlutterSurfaceView) {
        super.onFlutterSurfaceViewCreated(flutterSurfaceView)
        this.flutterSurfaceView = flutterSurfaceView
    }

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
            // task runner and requires a current rendering surface. Notify it
            // first; detaching immediately makes the rasterizer skip cleanup
            // because no surface/graphics context is available.
            flutterEngine.dartExecutor.notifyLowMemoryWarning()
            flutterEngine.systemChannel.sendMemoryPressureWarning()
            window.decorView.postDelayed({
                val surfaceView = flutterSurfaceView
                surfaceView?.detachFromRenderer()
                Runtime.getRuntime().gc()
                surfaceView?.attachToRenderer(flutterEngine.renderer)
                result.success(null)
            }, 250)
        }
    }
}
