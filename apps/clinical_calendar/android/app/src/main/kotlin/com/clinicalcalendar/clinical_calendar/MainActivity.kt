package com.clinicalcalendar.clinical_calendar

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.system.exitProcess

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.clinicalcalendar.clinical_calendar/host_lifecycle",
        ).setMethodCallHandler { call, result ->
            if (call.method != "restartProcess") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            result.success(null)
            runOnUiThread { restartCleanly() }
        }
    }

    private fun restartCleanly() {
        startActivity(
            Intent(this, RestartActivity::class.java).addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK,
            ),
        )
        finishAffinity()
        exitProcess(0)
    }
}
