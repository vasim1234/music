package com.example.music_player

import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.media.audiofx.PresetReverb
import android.media.audiofx.Virtualizer
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class BassBoostPlugin : MethodCallHandler {
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var equalizer: Equalizer? = null
    private var reverb: PresetReverb? = null
    private var loudness: LoudnessEnhancer? = null
    private var audioSessionId: Int = 0

    private var eqMinLevel: Short = -1500
    private var eqMaxLevel: Short = 1500
    private var eqNumBands: Int = 5

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

            equalizer = Equalizer(0, audioSessionId).apply {
                enabled = false
                eqNumBands = numberOfBands.toInt()
                try {
                    val range = bandLevelRange
                    eqMinLevel = range[0]
                    eqMaxLevel = range[1]
                } catch (e: Exception) {
                    eqMinLevel = -1500
                    eqMaxLevel = 1500
                }
                for (i in 0 until eqNumBands) {
                    setBandLevel(i.toShort(), 0.toShort())
                }
            }

            reverb = PresetReverb(0, audioSessionId).apply {
                enabled = false
                preset = PresetReverb.PRESET_NONE
            }

            loudness = LoudnessEnhancer(audioSessionId).apply {
                enabled = false
                setTargetGain(0)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun applyEqualizerPreset(presetName: String) {
        equalizer?.let { eq ->
            val numBands = eq.numberOfBands.toInt()
            val centerFreqs = mutableListOf<Int>()
            for (i in 0 until numBands) {
                try {
                    centerFreqs.add(eq.getCenterFreq(i.toShort()) / 1000)
                } catch (e: Exception) {
                    centerFreqs.add(0)
                }
            }

            val levels = IntArray(numBands) { 0 }
            for (i in 0 until numBands) {
                val freq = centerFreqs.getOrElse(i) { 0 }
                levels[i] = when (presetName) {
                    "Rock" -> when {
                        freq < 200 -> 600
                        freq < 1000 -> -200
                        freq < 4000 -> 300
                        else -> 700
                    }
                    "Pop" -> when {
                        freq < 200 -> 300
                        freq < 1000 -> 500
                        freq < 4000 -> 400
                        else -> 200
                    }
                    "Jazz" -> when {
                        freq < 200 -> 400
                        freq < 1000 -> 200
                        freq < 4000 -> 300
                        else -> 500
                    }
                    "Classical" -> when {
                        freq < 200 -> 400
                        freq < 1000 -> 0
                        freq < 4000 -> 300
                        else -> 600
                    }
                    "BassBoost" -> when {
                        freq < 200 -> 1200
                        freq < 1000 -> 700
                        freq < 4000 -> 200
                        else -> 0
                    }
                    "TrebleBoost" -> when {
                        freq < 200 -> 0
                        freq < 1000 -> 100
                        freq < 4000 -> 700
                        else -> 1200
                    }
                    "Vocal" -> when {
                        freq < 200 -> -300
                        freq < 1000 -> 600
                        freq < 4000 -> 700
                        else -> 300
                    }
                    else -> 0
                }
            }

            for (i in 0 until numBands) {
                try {
                    val lvl = levels[i].coerceIn(eqMinLevel.toInt(), eqMaxLevel.toInt())
                    eq.setBandLevel(i.toShort(), lvl.toShort())
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
            eq.enabled = true
        }
    }

    private fun applyEqualizerBand(bandIndex: Int, levelMb: Int) {
        equalizer?.let { eq ->
            try {
                val numBands = eq.numberOfBands.toInt()
                if (bandIndex in 0 until numBands) {
                    val lvl = levelMb.coerceIn(eqMinLevel.toInt(), eqMaxLevel.toInt())
                    eq.setBandLevel(bandIndex.toShort(), lvl.toShort())
                    eq.enabled = true
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun getEqualizerInfo(): Map<String, Any> {
        val eq = equalizer ?: return mapOf(
            "numBands" to 0,
            "minLevel" to -1500,
            "maxLevel" to 1500,
            "centerFreqs" to emptyList<Int>()
        )
        val numBands = eq.numberOfBands.toInt()
        val freqs = mutableListOf<Int>()
        for (i in 0 until numBands) {
            try {
                freqs.add(eq.getCenterFreq(i.toShort()) / 1000)
            } catch (e: Exception) {
                freqs.add(0)
            }
        }
        return mapOf(
            "numBands" to numBands,
            "minLevel" to eqMinLevel.toInt(),
            "maxLevel" to eqMaxLevel.toInt(),
            "centerFreqs" to freqs
        )
    }

    private fun applyImmersive(enabled: Boolean, strength: Int) {
        virtualizer?.let {
            it.enabled = enabled
            if (enabled) it.setStrength(strength.coerceIn(0, 1000).toShort())
        }
        equalizer?.let { eq ->
            eq.enabled = enabled
            if (enabled) {
                val numBands = eq.numberOfBands.toInt()
                val maxBoostMb = (strength / 1000.0) * 1200.0
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
            }
        }
    }

    /**
     * Reverb apply karo
     * presetName: "None", "SmallRoom", "MediumRoom", "LargeRoom", "MediumHall", "LargeHall", "Plate"
     */
    private fun applyReverb(enabled: Boolean, presetName: String) {
        reverb?.let { rev ->
            if (!enabled) {
                rev.enabled = false
                rev.preset = PresetReverb.PRESET_NONE
                return
            }
            val preset = when (presetName) {
                "SmallRoom" -> PresetReverb.PRESET_SMALLROOM
                "MediumRoom" -> PresetReverb.PRESET_MEDIUMROOM
                "LargeRoom" -> PresetReverb.PRESET_LARGEROOM
                "MediumHall" -> PresetReverb.PRESET_MEDIUMHALL
                "LargeHall" -> PresetReverb.PRESET_LARGEHALL
                "Plate" -> PresetReverb.PRESET_PLATE
                else -> PresetReverb.PRESET_NONE
            }
            rev.preset = preset
            rev.enabled = preset != PresetReverb.PRESET_NONE
        }
    }

    /**
     * Loudness Enhancer apply karo
     * gainMb: 0 to 1500 (millibels) — 1000 mB = +10 dB
     */
    private fun applyLoudness(enabled: Boolean, gainMb: Int) {
        loudness?.let { l ->
            if (enabled && gainMb > 0) {
                l.setTargetGain(gainMb.coerceIn(0, 1500))
                l.enabled = true
            } else {
                l.enabled = false
                l.setTargetGain(0)
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
            "setEqualizerPreset" -> {
                val presetName = call.argument<String>("preset") ?: "Flat"
                applyEqualizerPreset(presetName)
                result.success(true)
            }
            "setEqualizerBand" -> {
                val bandIndex = call.argument<Int>("bandIndex") ?: 0
                val levelMb = call.argument<Int>("levelMb") ?: 0
                applyEqualizerBand(bandIndex, levelMb)
                result.success(true)
            }
            "getEqualizerInfo" -> {
                result.success(getEqualizerInfo())
            }
            "setEqualizerEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                equalizer?.enabled = enabled
                result.success(enabled)
            }
            "setReverb" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val presetName = call.argument<String>("preset") ?: "None"
                applyReverb(enabled, presetName)
                result.success(true)
            }
            "setLoudness" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val gainMb = call.argument<Int>("gainMb") ?: 0
                applyLoudness(enabled, gainMb)
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
