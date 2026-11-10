package com.turkmax.app.navilite

import com.turkmax.app.bluetooth.PipeTransport
import java.io.IOException
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class ImageChannelTest {
    private val jpeg = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 1, 2, 3, 0xFF.toByte(), 0xD9.toByte())

    private class Fixture(options: FakeCcu.Options = FakeCcu.Options()) {
        val ccu: FakeCcu
        val session: NaviLiteSession
        val images: ImageChannel

        init {
            val (phoneEnd, gaugeEnd) = PipeTransport.createPair()
            ccu = FakeCcu(gaugeEnd, options).also { it.start() }
            phoneEnd.open()
            session = NaviLiteSession(phoneEnd).also { it.start() }
            NaviLiteHandshake.perform(session, 2_000)
            images = ImageChannel(session)
        }

        fun close() {
            session.close()
            ccu.close()
        }
    }

    @Test
    fun `image payload layout and sequence parsing`() {
        val payload = ImageChannel.imagePayload(0x1234, jpeg)
        assertEquals(3, payload[0].toInt())
        assertEquals(0x34, payload[1].toInt())
        assertEquals(0x12, payload[2].toInt())
        assertArrayEquals(jpeg, payload.copyOfRange(3, payload.size))
        assertEquals(0x1234, ImageChannel.imageSequence(payload))
        assertEquals(0xFFFE, ImageChannel.ackSequence(ImageChannel.ackPayload(0xFFFE)))
        assertNull(ImageChannel.ackSequence(byteArrayOf(1)))
    }

    @Test
    fun `sequence starts at one and each image is acked`() {
        val fixture = Fixture()
        for (expected in 1..3) {
            val sequence = fixture.images.send(jpeg)
            assertEquals(expected, sequence)
            assertTrue(fixture.images.awaitAck(sequence, 1_000))
        }
        assertEquals(3, fixture.ccu.imagesReceived)
        assertArrayEquals(jpeg, fixture.ccu.lastImage)
        fixture.close()
    }

    @Test
    fun `missing ack times out without closing the session`() {
        val fixture = Fixture(FakeCcu.Options(dropAckEvery = 1))
        val sequence = fixture.images.send(jpeg)
        assertFalse(fixture.images.awaitAck(sequence, 100))
        assertFalse(fixture.session.isClosed)
        fixture.close()
    }

    @Test
    fun `ack with wrong sequence does not unlock the next image`() {
        val fixture = Fixture(FakeCcu.Options(corruptAckEvery = 1))
        val sequence = fixture.images.send(jpeg)
        assertFalse(fixture.images.awaitAck(sequence, 150))
        fixture.close()
    }

    @Test
    fun `gauge disconnect surfaces as io exception`() {
        val fixture = Fixture(FakeCcu.Options(disconnectAfterImages = 1))
        val first = fixture.images.send(jpeg)
        fixture.images.awaitAck(first, 1_000)
        assertThrows(IOException::class.java) {
            val second = fixture.images.send(jpeg)
            fixture.images.awaitAck(second, 1_000)
        }
        fixture.close()
    }
}
