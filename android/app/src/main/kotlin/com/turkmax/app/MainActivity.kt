package com.turkmax.app

import com.turkmax.app.channels.ChannelRegistry
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var channels: ChannelRegistry? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channels = ChannelRegistry(applicationContext, flutterEngine.dartExecutor.binaryMessenger) { this }
            .also { it.register() }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channels?.dispose()
        channels = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
