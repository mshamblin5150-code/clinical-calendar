package com.clinicalcalendar.clinical_calendar

import android.content.ComponentCallbacks2
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
            window.decorView.post {
                val surfaceView = flutterSurfaceView
                surfaceView?.detachFromRenderer()
                onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_COMPLETE)
                Runtime.getRuntime().gc()
                surfaceView?.attachToRenderer(flutterEngine.renderer)
                result.success(null)
            }
        }
    }
}
