package com.naarixa.app

import android.content.Context
import android.media.AudioManager
import android.view.KeyEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Volume Button Listener - Detects volume button presses for SOS triggering
 * 
 * This service runs in the main activity and intercepts hardware key events.
 * It then communicates with the Dart layer via MethodChannel.
 */
class VolumeButtonListenerService(private val activity: android.app.Activity) {
    companion object {
        private const val CHANNEL = "com.naarixa.app/volume_listener"
    }

    private var methodChannel: MethodChannel? = null
    private var isListening = false

    fun setupChannel(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startVolumeListener" -> {
                    startListening()
                    result.success(true)
                }
                "stopVolumeListener" -> {
                    stopListening()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startListening() {
        isListening = true
        android.util.Log.d("VolumeListener", "Volume button listener started")
    }

    private fun stopListening() {
        isListening = false
        android.util.Log.d("VolumeListener", "Volume button listener stopped")
    }

    /**
     * This method should be called from MainActivity's onKeyDown
     * to intercept volume button presses
     */
    fun onKeyDown(keyCode: Int): Boolean {
        if (!isListening) return false

        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP -> {
                android.util.Log.d("VolumeListener", "Volume UP detected")
                methodChannel?.invokeMethod("onVolumeUpPressed", null)
                true // Consume the event
            }
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                android.util.Log.d("VolumeListener", "Volume DOWN detected")
                methodChannel?.invokeMethod("onVolumeDownPressed", null)
                true // Consume the event
            }
            else -> false
        }
    }
}
