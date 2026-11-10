package com.turkmax.app.channels

import android.os.Handler
import android.os.Looper
import com.turkmax.app.bluetooth.ConnectionRuntime
import com.turkmax.app.streaming.CockpitFrameSource
import com.turkmax.app.streaming.CockpitFrameState
import com.turkmax.app.streaming.JpegFrameEncoder
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService

class StreamingMethodHandler(
    private val frameSource: CockpitFrameSource,
    private val encoder: JpegFrameEncoder,
    private val worker: ExecutorService,
) : MethodChannel.MethodCallHandler {
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "captureSyntheticFrame" -> runOnWorker(result, "FRAME_FAILED") {
                val bitmap = frameSource.latestFrame() ?: error("Frame source returned no frame")
                val startNanos = System.nanoTime()
                val jpeg = encoder.encode(bitmap)
                mapOf(
                    "jpeg" to jpeg,
                    "width" to bitmap.width,
                    "height" to bitmap.height,
                    "encodeMicros" to (System.nanoTime() - startNanos) / 1_000,
                )
            }
            // TFT karesinde çizilecek içerik; Flutter her değişiklikte gönderir.
            "setCockpitState" -> {
                (call.arguments as? Map<*, *>)?.let {
                    ConnectionRuntime.cockpitState = CockpitFrameState.fromMap(it)
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** Bloklayan işi Flutter UI thread'i dışında çalıştırır, sonucu ana thread'de bildirir. */
    private fun runOnWorker(result: MethodChannel.Result, errorCode: String, block: () -> Any?) {
        worker.execute {
            val outcome = runCatching(block)
            mainHandler.post {
                outcome.fold(
                    onSuccess = result::success,
                    onFailure = { result.error(errorCode, it.message, null) },
                )
            }
        }
    }
}
