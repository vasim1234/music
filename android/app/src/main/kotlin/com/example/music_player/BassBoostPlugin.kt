package com.example.music_player

import android.content.Context
import android.media.audiofx.BassBoost
import android.media.audiofx.Virtualizer
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class BassBoostPlugin(private val context: Context) : MethodCallHandler {
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var audioSessionId: Int = 0

    // इसे MainActivity से सेट करेंगे जब just_audio AudioSession ID देगा
    fun setAudioSessionId(sessionId: Int) {
        this.audioSessionId = sessionId
        initEffects()
    }

    private fun initEffects() {
        try {
            // Bass Boost सेटअप
            bassBoost = BassBoost(0, audioSessionId).apply {
                enabled = false // शुरू में बंद रखेंगे
                setStrength(300) // 300 = 30% (रेंज 0-1000)
            }

            // Immersive Audio (Virtualizer) सेटअप
            virtualizer = Virtualizer(0, audioSessionId).apply {
                enabled = false
                setStrength(300) // 30% इमर्सिव
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setBassBoost" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val strength = call.argument<Int>("strength") ?: 0
                bassBoost?.let {
                    it.enabled = enabled
                    if (enabled) it.setStrength(strength.coerceIn(0, 1000))
                    result.success(it.enabled)
                } ?: result.error("NO_SESSION", "Audio session not ready", null)
            }
            "setImmersive" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val strength = call.argument<Int>("strength") ?: 0
                virtualizer?.let {
                    it.enabled = enabled
                    if (enabled) it.setStrength(strength.coerceIn(0, 1000))
                    result.success(it.enabled)
                } ?: result.error("NO_SESSION", "Audio session not ready", null)
            }
            "getBassBoost" -> {
                result.success(bassBoost?.let {
                    mapOf("enabled" to it.enabled, "strength" to it.strength)
                } ?: mapOf("enabled" to false, "strength" to 0))
            }
            else -> result.notImplemented()
        }
    }
}
