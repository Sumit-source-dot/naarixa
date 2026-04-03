package com.naarixa.app

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val VOLUME_CHANNEL = "com.naarixa.app/volume_listener"
    }

    private var methodChannel: MethodChannel? = null
    private var isVolumeListenerActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup volume button listener channel
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VOLUME_CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startVolumeListener" -> {
                    isVolumeListenerActive = true
                    android.util.Log.d("VolumeListener", "Volume listener started")
                    result.success(true)
                }
                "stopVolumeListener" -> {
                    isVolumeListenerActive = false
                    android.util.Log.d("VolumeListener", "Volume listener stopped")
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Intercepts hardware key events to detect volume button presses
     * This allows SOS to be triggered even when app is in background or screen is off
     */
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (!isVolumeListenerActive) {
            return super.onKeyDown(keyCode, event)
        }

        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP -> {
                android.util.Log.d("VolumeListener", "Volume UP pressed")
                methodChannel?.invokeMethod("onVolumeUpPressed", null)
                true // Consume the event to prevent system volume change
            }
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                android.util.Log.d("VolumeListener", "Volume DOWN pressed")
                methodChannel?.invokeMethod("onVolumeDownPressed", null)
                true // Consume the event
            }
            else -> super.onKeyDown(keyCode, event)
        }
    }
}
