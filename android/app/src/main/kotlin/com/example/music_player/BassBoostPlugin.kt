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
