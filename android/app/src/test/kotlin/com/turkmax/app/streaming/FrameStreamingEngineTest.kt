package com.turkmax.app.streaming

import com.turkmax.app.bluetooth.PipeTransport
import com.turkmax.app.navilite.FakeCcu
import com.turkmax.app.navilite.ImageChannel
import com.turkmax.app.navilite.NaviLiteHandshake
import com.turkmax.app.navilite.NaviLiteSession
import java.io.IOException
import java.util.concurrent.atomic.AtomicInteger
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class FrameStreamingEngineTest {
    private class Fixture(options: FakeCcu.Options = FakeCcu.Options()) {
        val ccu: FakeCcu
        val session: NaviLiteSession
        val metrics = StreamingMetrics()
        val produced = AtomicInteger()

        init {
            val (phoneEnd, gaugeEnd) = PipeTransport.createPair()
            ccu = FakeCcu(gaugeEnd, options).also { it.start() }
            phoneEnd.open()
            session = NaviLiteSession(phoneEnd).also { it.start() }
            NaviLiteHandshake.perform(session, 2_000)
        }

        fun engine(maxFps: Int = 0, ackTimeoutMs: Long = 1_000) = FrameStreamingEngine(
            images = ImageChannel(session),
            // Kare numarasını taşıyan sahte "JPEG".
            nextJpeg = { quality -> byteArrayOf(produced.incrementAndGet().toByte(), quality.toByte()) },
            metrics = metrics,
            maxFps = maxFps,
            ackTimeoutMs = ackTimeoutMs,
        )

        fun close() {
            session.close()
            ccu.close()
        }
    }

    @Test
    fun `streams frames one at a time and receiver gets the latest`() {
        val fixture = Fixture()
        fixture.engine().run { fixture.metrics.snapshot().framesAcked >= 25 }

        val snapshot = fixture.metrics.snapshot()
        assertEquals(snapshot.framesSent, snapshot.framesAcked)
        assertEquals(0, snapshot.ackTimeouts)
        assertEquals(snapshot.framesSent, fixture.ccu.imagesReceived)
        assertEquals(fixture.produced.get().toByte(), fixture.ccu.lastImage!![0])
        fixture.close()
    }

    @Test
    fun `rate limit caps the frame rate`() {
        val fixture = Fixture()
        val start = System.nanoTime()
        fixture.engine(maxFps = 20).run { System.nanoTime() - start > 500_000_000 }
        // 20 fps × 0,5 sn ≈ 10 kare; zamanlama oynaklığı için pay bırakılır.
        assertTrue("sent ${fixture.metrics.snapshot().framesSent}", fixture.metrics.snapshot().framesSent in 5..12)
        fixture.close()
    }

    @Test
    fun `ack timeout keeps the link, drops quality and continues with fresh frames`() {
        val fixture = Fixture(FakeCcu.Options(dropAckEvery = 2))
        val engine = fixture.engine(ackTimeoutMs = 60)
        engine.run { fixture.metrics.snapshot().ackTimeouts >= 2 }

        val snapshot = fixture.metrics.snapshot()
        assertTrue(snapshot.framesAcked >= 2)
        assertTrue(engine.quality < JpegFrameEncoder.DEFAULT_QUALITY)
        assertTrue(engine.quality >= FrameStreamingEngine.DEFAULT_MIN_QUALITY)
        assertTrue(!fixture.session.isClosed)
        fixture.close()
    }

    @Test
    fun `slow acks lower quality`() {
        val slow = Fixture(FakeCcu.Options(ackDelayMs = 150))
        val engine = slow.engine(maxFps = 15)
        engine.run { slow.metrics.snapshot().framesAcked >= 3 }
        assertTrue(engine.quality < JpegFrameEncoder.DEFAULT_QUALITY)
        slow.close()
    }

    @Test
    fun `quality recovers to the configured level once acks are fast again, never above`() {
        val fast = Fixture()
        val engine = FrameStreamingEngine(
            images = ImageChannel(fast.session),
            nextJpeg = { byteArrayOf(1) },
            metrics = fast.metrics,
            maxFps = 0,
            startQuality = JpegFrameEncoder.MIN_QUALITY,
            minQuality = JpegFrameEncoder.MIN_QUALITY,
        )
        engine.run { fast.metrics.snapshot().framesAcked >= 60 }
        assertEquals(JpegFrameEncoder.DEFAULT_QUALITY, engine.quality)
        fast.close()
    }

    @Test
    fun `gauge disconnect ends the loop with io exception`() {
        val fixture = Fixture(FakeCcu.Options(disconnectAfterImages = 3))
        assertThrows(IOException::class.java) { fixture.engine().run { false } }
        assertEquals(3, fixture.ccu.imagesReceived)
        fixture.close()
    }

    @Test
    fun `waits when no frame is available`() {
        val fixture = Fixture()
        val calls = AtomicInteger()
        FrameStreamingEngine(
            images = ImageChannel(fixture.session),
            nextJpeg = { if (calls.incrementAndGet() < 4) null else byteArrayOf(1) },
            metrics = fixture.metrics,
            maxFps = 0,
            sleep = {},
        ).run { fixture.metrics.snapshot().framesAcked >= 1 }
        assertEquals(1, fixture.metrics.snapshot().framesSent)
        fixture.close()
    }
}
