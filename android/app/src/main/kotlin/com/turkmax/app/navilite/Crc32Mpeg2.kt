package com.turkmax.app.navilite

/**
 * CRC-32/MPEG-2: polinom 0x04C11DB7, başlangıç 0xFFFFFFFF, yansıtma yok, son XOR yok.
 * Standart kontrol değeri: "123456789" → 0x0376E6E7.
 */
object Crc32Mpeg2 {
    private const val POLYNOMIAL = 0x04C11DB7

    private val table = IntArray(256) { index ->
        var value = index shl 24
        repeat(8) {
            value = if (value < 0) (value shl 1) xor POLYNOMIAL else value shl 1
        }
        value
    }

    fun update(crc: Int, data: ByteArray, offset: Int = 0, length: Int = data.size - offset): Int {
        var value = crc
        for (i in offset until offset + length) {
            value = (value shl 8) xor table[((value ushr 24) xor (data[i].toInt() and 0xFF)) and 0xFF]
        }
        return value
    }

    fun compute(vararg parts: ByteArray): Int = parts.fold(INITIAL) { crc, part -> update(crc, part) }

    const val INITIAL: Int = -1 // 0xFFFFFFFF
}
