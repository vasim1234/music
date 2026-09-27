package com.example.music_player

import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.Virtualizer
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class BassBoostPlugin : MethodCallHandler {
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var equalizer: Equalizer? = null
    private var audioSessionId: Int = 0

    fun setAudioSessionId(sessionId: Int) {
        this.audioSessionId = sessionId
        initEffects()
    }

    private fun initEffects() {
        try {
            // Bass Boost setup
            bassBoost = BassBoost(0, audioSessionId).apply {
                enabled = false
                setStrength(300.toShort())
            }

            // Virtualizer setup (3D surround)
            virtualizer = Virtualizer(0, audioSessionId).apply {
                enabled = false
                setStrength(300.toShort())
            }

            // Equalizer setup (immersive ke liye)
            equalizer = Equalizer(0, audioSessionId).apply {
                enabled = false
                // Sabhi bands ko 0 (neutral) pe set karo
                val numBands = numberOfBands.toInt()
                for (i in 0 until numBands) {
                    setBandLevel(i.toShort(), 0.toShort())
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Immersive audio: Virtualizer + Equalizer (high frequencies boost)
     * strength: 0-1000
     */
    private fun applyImmersive(enabled: Boolean, strength: Int) {
        // Virtualizer
        virtualizer?.let {
            it.enabled = enabled
            if (enabled) it.setStrength(strength.coerceIn(0, 1000).toShort())
        }

        // Equalizer — high frequencies boost (immersive feel)
        equalizer?.let { eq ->
            eq.enabled = enabled
            if (enabled) {
                val numBands = eq.numberOfBands.toInt()
                // Strength ko 0-1000 se 0-maxBoost millibels mein convert karo
                // High bands pe zyada boost, low bands pe kam
                val maxBoostMb = (strength / 1000.0) * 1200.0  // max 1200 mB = 12 dB
                val centerFreqs = mutableListOf<Int>()
                for (i in 0 until numBands) {
                    try {
                        centerFreqs.add(eq.getCenterFreq(i.toShort()) / 1000)
                    } catch (e: Exception) {
                        centerFreqs.add(0)
                    }
                }
                for (i in 0 until numBands) {
                    val freq = centerFreqs.getOrElse(i) { 0 }
                    // High frequencies (4kHz+) pe full boost
                    // Mid (1-4kHz) pe half boost
                    // Low (<1kHz) pe zero boost
                    val boostMb = when {
                        freq >= 4000 -> maxBoostMb
                        freq >= 1000 -> maxBoostMb * 0.5
                        else -> 0.0
                    }
                    try {
                        eq.setBandLevel(i.toShort(), boostMb.toInt().toShort())
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            } else {
                // Disable karte waqt sab bands neutral pe
                val numBands = eq.numberOfBands.toInt()
                for (i in 0 until numBands) {
                    try {
                        eq.setBandLevel(i.toShort(), 0.toShort())
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
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
                applyImmersive(enabled, strength)
                result.success(true)
            }
            "getBassBoost" -> {
                val enabled = bassBoost?.enabled ?: false
                result.success(mapOf("enabled" to enabled, "strength" to 0))
            }
            else -> result.notImplemented()
        }
    }
}
