package com.turkmax.app.streaming

import org.junit.Assert.assertEquals
import org.junit.Test

class StreamingMetricsTest {
    @Test
    fun `counts frames and computes fps over a sliding window`() {
        var now = 0L
        val metrics = StreamingMetrics { now }
        repeat(20) {
            metrics.onFrameSent(jpegBytes = 5_000, quality = 40)
            metrics.onAck(50.0)
            now += 100_000_000 // 100 ms
        }
        val snapshot = metrics.snapshot()
        assertEquals(20, snapshot.framesSent)
        assertEquals(20, snapshot.framesAcked)
        assertEquals(10.0, snapshot.fps, 0.6)
        assertEquals(50.0, snapshot.averageAckMs, 0.001)
        assertEquals(5_000, snapshot.lastJpegBytes)

        now += 5_000_000_000 // akış durdu
        assertEquals(0.0, metrics.snapshot().fps, 0.0)
    }

    @Test
    fun `timeouts are counted separately`() {
        val metrics = StreamingMetrics { 0 }
        metrics.onFrameSent(100, 40)
        metrics.onAckTimeout()
        assertEquals(1, metrics.snapshot().ackTimeouts)
        assertEquals(0, metrics.snapshot().framesAcked)
    }
}
