package com.turkmax.app.navilite

import com.turkmax.app.bluetooth.PipeTransport
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class NaviLiteHandshakeTest {
    private fun hex(text: String): ByteArray =
        text.replace(" ", "").chunked(2).map { it.toInt(16).toByte() }.toByteArray()

    // docs/NAVILITE_PROTOCOL.md §4.1 test vektörleri.
    private val vectors = listOf(
        Triple("3A3A3C27483E3B3C3A273A3A BAAA4D5C", "006-B4160-00", "B0A04756"),
        Triple("3A3A3C27483E3B3C3A273A3A C12B8A7B", "006-B4160-00", "CB218071"),
        Triple("3A3A3C27483E3B3C3A273A3A 43719E55", "006-B4160-00", "497B945F"),
        Triple("3A3A3C274839333F38273A39 2504211C", "006-B3952-03", "2F0E2B16"),
    )

    @Test
    fun `decodes part number and builds ack for documented vectors`() {
        for ((secData, partNumber, ack) in vectors) {
            assertEquals(partNumber, NaviLiteHandshake.decodePartNumber(hex(secData)))
            assertArrayEquals(hex(ack), NaviLiteHandshake.secDataAckPayload(hex(secData)))
        }
    }

    @Test
    fun `encodeSecData is the inverse of decoding`() {
        val nonce = hex("2F0E2B16")
        val payload = NaviLiteHandshake.encodeSecData("006-B3952-03", nonce)
        assertArrayEquals(hex("3A3A3C274839333F38273A39 2504211C"), payload)
        assertArrayEquals(nonce, NaviLiteHandshake.secDataAckPayload(payload))
    }

    @Test
    fun `too short sec data is rejected`() {
        assertNull(NaviLiteHandshake.decodePartNumber(ByteArray(3)))
    }

    @Test
    fun `setup burst has eleven frames in documented order`() {
        assertEquals(
            listOf(2, 31, 10, 11, 13, 12, 14, 3, 17, 13, 12),
            NaviLiteHandshake.setupFrames.map { it.serviceType },
        )
        assertEquals(0, NaviLiteHandshake.setupFrames[7].payload.size)
    }

    @Test
    fun `nav status variant only changes the first setup frame`() {
        val active = NaviLiteHandshake.setupFrames(navStatusActive = true)
        assertArrayEquals(byteArrayOf(1, 0), active.first().payload)
        assertArrayEquals(byteArrayOf(0, 0), NaviLiteHandshake.setupFrames.first().payload)
        assertEquals(NaviLiteHandshake.setupFrames.drop(1), active.drop(1))
    }

    @Test
    fun `full handshake against fake ccu selects xmax profile`() {
        val (phoneEnd, gaugeEnd) = PipeTransport.createPair()
        val ccu = FakeCcu(gaugeEnd).also { it.start() }
        phoneEnd.open()
        val session = NaviLiteSession(phoneEnd).also { it.start() }

        val result = NaviLiteHandshake.perform(session, timeoutMs = 2_000)

        assertEquals("006-B3952-03", result.partNumber)
        assertEquals(CcuDeviceProfile.XMAX, result.profile)
        waitUntil { ccu.setupFramesReceived == 11 }
        assertTrue(ccu.authenticated)
        session.close()
        ccu.close()
    }

    @Test
    fun `other part numbers select the default profile`() {
        val (phoneEnd, gaugeEnd) = PipeTransport.createPair()
        val ccu = FakeCcu(gaugeEnd, FakeCcu.Options(partNumber = "006-B4160-00")).also { it.start() }
        phoneEnd.open()
        val session = NaviLiteSession(phoneEnd).also { it.start() }

        assertEquals(CcuDeviceProfile.DEFAULT, NaviLiteHandshake.perform(session, 2_000).profile)
        session.close()
        ccu.close()
    }

    @Test
    fun `silent gauge causes handshake timeout`() {
        val (phoneEnd, gaugeEnd) = PipeTransport.createPair()
        val ccu = FakeCcu(gaugeEnd, FakeCcu.Options(silent = true)).also { it.start() }
        phoneEnd.open()
        val session = NaviLiteSession(phoneEnd).also { it.start() }

        assertThrows(HandshakeTimeoutException::class.java) {
            NaviLiteHandshake.perform(session, timeoutMs = 150)
        }
        session.close()
        ccu.close()
    }
}

internal fun waitUntil(timeoutMs: Long = 3_000, condition: () -> Boolean) {
    val deadline = System.currentTimeMillis() + timeoutMs
    while (!condition()) {
        check(System.currentTimeMillis() < deadline) { "Condition not met within $timeoutMs ms" }
        Thread.sleep(5)
    }
}
