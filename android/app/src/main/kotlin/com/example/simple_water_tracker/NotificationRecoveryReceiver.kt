package com.example.simple_water_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Recalculates watering reminders after Android removes posted notifications
 * during a package update. The Flutter engine is headless and exists only for
 * the duration of the recovery entry point.
 */
class NotificationRecoveryReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) return

        RecoverySession(context.applicationContext, goAsync()).start()
    }

    private class RecoverySession(
        private val context: Context,
        private val pendingResult: BroadcastReceiver.PendingResult,
    ) {
        private val handler = Handler(Looper.getMainLooper())
        private val finished = AtomicBoolean(false)
        private var engine: FlutterEngine? = null
        private var channel: MethodChannel? = null
        private val timeout = Runnable {
            Log.e(TAG, "Reminder recovery timed out")
            finish()
        }

        fun start() {
            try {
                val flutterEngine = FlutterEngine(context)
                engine = flutterEngine
                val completionChannel = MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    CHANNEL_NAME,
                )
                channel = completionChannel
                completionChannel.setMethodCallHandler { call, result ->
                    if (call.method != "complete") {
                        result.notImplemented()
                        return@setMethodCallHandler
                    }

                    val success = call.argument<Boolean>("success") ?: false
                    if (!success) {
                        Log.e(
                            TAG,
                            "Reminder recovery failed: ${call.argument<String>("error")}",
                        )
                    }
                    result.success(null)
                    finish()
                }

                handler.postDelayed(timeout, TIMEOUT_MILLIS)
                val entrypoint = DartExecutor.DartEntrypoint(
                    FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                    DART_ENTRYPOINT,
                )
                flutterEngine.dartExecutor.executeDartEntrypoint(entrypoint)
            } catch (error: Exception) {
                Log.e(TAG, "Could not start reminder recovery", error)
                finish()
            }
        }

        private fun finish() {
            if (!finished.compareAndSet(false, true)) return

            handler.removeCallbacks(timeout)
            channel?.setMethodCallHandler(null)
            channel = null
            engine?.destroy()
            engine = null
            pendingResult.finish()
        }
    }

    private companion object {
        const val TAG = "NotificationRecovery"
        const val CHANNEL_NAME =
            "com.bromiapps.simplywaterplant/notification_recovery"
        const val DART_ENTRYPOINT = "notificationRecoveryMain"
        // MY_PACKAGE_REPLACED is a background broadcast, whose execution
        // window is longer than the usual foreground-broadcast limit.
        const val TIMEOUT_MILLIS = 25_000L
    }
}
