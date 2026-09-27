package com.example.music_player

import android.media.audiofx.BassBoost
import android.media.audiofx.Virtualizer
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class BassBoostPlugin : MethodCallHandler {
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var audioSessionId: Int = 0

    fun setAudioSessionId(sessionId: Int) {
        this.audioSessionId = sessionId
        initEffects()
    }

    private fun initEffects() {
        try {
            bassBoost = BassBoost(0, audioSessionId).apply {
                enabled = false
                setStrength(300.toShort())
            }

            virtualizer = Virtualizer(0, audioSessionId).apply {
                enabled = false
                setStrength(300.toShort())
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setAudioSessionId" -> {
                val sessionId = call.argument<Int>("sessionId") ?: 0
                setAudioSessionId(sessionId)
                result.success(true)
            }
            "setBassBoost" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val strength = call.argument<Int>("strength") ?: 0
                bassBoost?.let {
                    it.enabled = enabled
                    if (enabled) it.setStrength(strength.coerceIn(0, 1000).toShort())
                    result.success(it.enabled)
                } ?: result.error("NO_SESSION", "Audio session not ready", null)
            }
            "setImmersive" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val strength = call.argument<Int>("strength") ?: 0
                virtualizer?.let {
                    it.enabled = enabled
                    if (enabled) it.setStrength(strength.coerceIn(0, 1000).toShort())
                    result.success(it.enabled)
                } ?: result.error("NO_SESSION", "Audio session not ready", null)
            }
            "getBassBoost" -> {
                // Android BassBoost/Virtualizer mein direct "getStrength" nahi hota
                // Isliye sirf enabled status bhej rahe hain
                val enabled = bassBoost?.enabled ?: false
                result.success(mapOf("enabled" to enabled, "strength" to 0))
            }
            else -> result.notImplemented()
        }
    }
}
