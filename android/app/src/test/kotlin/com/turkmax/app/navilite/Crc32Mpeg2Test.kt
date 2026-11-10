package com.turkmax.app.navilite

import org.junit.Assert.assertEquals
import org.junit.Test

class Crc32Mpeg2Test {
    @Test
    fun `standard check value`() {
        assertEquals(0x0376E6E7, Crc32Mpeg2.compute("123456789".toByteArray(Charsets.US_ASCII)))
    }

    @Test
    fun `empty input returns initial value`() {
        assertEquals(Crc32Mpeg2.INITIAL, Crc32Mpeg2.compute(ByteArray(0)))
    }

    @Test
    fun `chunked update equals single pass`() {
        val data = ByteArray(1000) { (it * 31).toByte() }
        val chunked = Crc32Mpeg2.compute(data.copyOfRange(0, 137), data.copyOfRange(137, 1000))
        assertEquals(Crc32Mpeg2.compute(data), chunked)
    }
}
