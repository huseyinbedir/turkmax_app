package com.turkmax.app.navilite

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NaviLiteCodecTest {
    private fun hex(text: String): ByteArray =
        text.replace(" ", "").chunked(2).map { it.toInt(16).toByte() }.toByteArray()

    private val secDataAck = NaviLiteFrame(
        serviceType = ServiceType.SEC_DATA_ACK,
        payloadDataType = PayloadDataType.POINTER.wire,
        payload = hex("B0A04756"),
    )

    @Test
    fun `encodes documented reference frame`() {
        // docs/NAVILITE_PROTOCOL.md içindeki referans vektör.
        assertArrayEquals(
            hex("6E416C40 01 06 54 04000000 01 24F0735B B0A04756"),
            NaviLiteCodec.encode(secDataAck),
        )
    }

    @Test
    fun `encodes empty payload`() {
        val bytes = NaviLiteCodec.encode(
            NaviLiteFrame(ServiceType.ROAD, PayloadDataType.VALUE.wire, ByteArray(0)),
        )
        assertEquals(NaviLiteCodec.PREFIX_SIZE, bytes.size)
    }

    @Test
    fun `decoder round trips frames split across reads`() {
        val image = NaviLiteFrame(
            ServiceType.IMAGE,
            PayloadDataType.POINTER.wire,
            ByteArray(5000) { it.toByte() },
        )
        val stream = NaviLiteCodec.encode(secDataAck) + NaviLiteCodec.encode(image)
        val decoder = NaviLiteCodec.Decoder()
        val frames = stream.toList().chunked(333).flatMap { decoder.feed(it.toByteArray()) }

        assertEquals(listOf(secDataAck, image), frames.map { it.frame })
        assertTrue(frames.all { it.crcValid })
    }

    @Test
    fun `decoder resynchronises after garbage`() {
        val decoder = NaviLiteCodec.Decoder()
        val frames = decoder.feed(hex("00FF6E41") + NaviLiteCodec.encode(secDataAck))
        assertEquals(listOf(secDataAck), frames.map { it.frame })
    }

    @Test
    fun `decoder reports corrupted crc without dropping frame`() {
        val bytes = NaviLiteCodec.encode(secDataAck)
        bytes[bytes.size - 1] = (bytes[bytes.size - 1].toInt() xor 0x01).toByte()
        val frames = NaviLiteCodec.Decoder().feed(bytes)
        assertEquals(1, frames.size)
        assertFalse(frames.single().crcValid)
    }

    @Test
    fun `decoder waits for incomplete frame`() {
        val bytes = NaviLiteCodec.encode(secDataAck)
        val decoder = NaviLiteCodec.Decoder()
        assertTrue(decoder.feed(bytes, 0, bytes.size - 1).isEmpty())
        assertEquals(1, decoder.feed(bytes, bytes.size - 1, 1).size)
    }
}
