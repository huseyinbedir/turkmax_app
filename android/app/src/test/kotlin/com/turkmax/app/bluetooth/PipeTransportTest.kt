package com.turkmax.app.bluetooth

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test

class PipeTransportTest {
    @Test
    fun `bytes written on one end are read on the other in order`() {
        val (a, b) = PipeTransport.createPair().also { it.first.open(); it.second.open() }
        a.write(byteArrayOf(1, 2, 3))
        a.write(byteArrayOf(4))

        val buffer = ByteArray(2)
        assertEquals(2, b.read(buffer, 0, 2))
        assertArrayEquals(byteArrayOf(1, 2), buffer)
        assertEquals(1, b.read(buffer, 0, 2))
        assertEquals(3.toByte(), buffer[0])
        assertEquals(1, b.read(buffer, 0, 2))
        assertEquals(4.toByte(), buffer[0])
    }

    @Test
    fun `closing one end ends both read sides`() {
        val (a, b) = PipeTransport.createPair().also { it.first.open(); it.second.open() }
        a.close()
        assertEquals(-1, b.read(ByteArray(4), 0, 4))
        assertEquals(-1, a.read(ByteArray(4), 0, 4))
    }
}
