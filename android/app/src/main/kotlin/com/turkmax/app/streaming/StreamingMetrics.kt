package com.turkmax.app.streaming

/** Akış ölçümleri. Tek bir akış thread'i yazar; [snapshot] herhangi bir thread'den okunabilir. */
class StreamingMetrics(private val clock: () -> Long = System::nanoTime) {
    data class Snapshot(
        val framesSent: Int = 0,
        val framesAcked: Int = 0,
        val ackTimeouts: Int = 0,
        val fps: Double = 0.0,
        val averageAckMs: Double = 0.0,
        val lastJpegBytes: Int = 0,
        val quality: Int = 0,
    ) {
        fun toMap(): Map<String, Any> = mapOf(
            "framesSent" to framesSent,
            "framesAcked" to framesAcked,
            "ackTimeouts" to ackTimeouts,
            "fps" to fps,
            "averageAckMs" to averageAckMs,
            "lastJpegBytes" to lastJpegBytes,
            "quality" to quality,
        )
    }

    private val ackTimes = ArrayDeque<Long>()
    private var framesSent = 0
    private var framesAcked = 0
    private var ackTimeouts = 0
    private var averageAckMs = 0.0
    private var lastJpegBytes = 0
    private var quality = 0

    @Synchronized
    fun onFrameSent(jpegBytes: Int, quality: Int) {
        framesSent++
        lastJpegBytes = jpegBytes
        this.quality = quality
    }

    @Synchronized
    fun onAck(ackMs: Double) {
        framesAcked++
        averageAckMs = if (framesAcked == 1) ackMs else averageAckMs * (1 - EMA_ALPHA) + ackMs * EMA_ALPHA
        ackTimes.addLast(clock())
        trim()
    }

    @Synchronized
    fun onAckTimeout() {
        ackTimeouts++
    }

    @Synchronized
    fun snapshot(): Snapshot {
        trim()
        return Snapshot(
            framesSent = framesSent,
            framesAcked = framesAcked,
            ackTimeouts = ackTimeouts,
            // Son pencere içinde onaylanan kare sayısı / pencere süresi.
            fps = ackTimes.size / WINDOW_SECONDS,
            averageAckMs = averageAckMs,
            lastJpegBytes = lastJpegBytes,
            quality = quality,
        )
    }

    private fun trim() {
        val cutoff = clock() - (WINDOW_SECONDS * 1_000_000_000L).toLong()
        while (ackTimes.isNotEmpty() && ackTimes.first() < cutoff) ackTimes.removeFirst()
    }

    private companion object {
        const val WINDOW_SECONDS = 2.0
        const val EMA_ALPHA = 0.2
    }
}
