package com.example.music_player

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.example.music_player/bass_boost"
    private var bassBoostPlugin: BassBoostPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        bassBoostPlugin = BassBoostPlugin()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                bassBoostPlugin?.onMethodCall(call, result)
            }
    }

    fun onAudioSessionIdReceived(sessionId: Int) {
        bassBoostPlugin?.setAudioSessionId(sessionId)
    }
}
