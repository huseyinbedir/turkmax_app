package com.turkmax.app.navilite

/**
 * NaviLite çerçeve kodlayıcı/çözücü (bağımsız implementasyon).
 *
 * Çerçeve düzeni — çok baytlı alanlar little-endian:
 * ```
 *  0  4  magic "nAl@"
 *  4  1  version (1)
 *  5  1  frameType
 *  6  1  serviceType
 *  7  4  payloadSize
 * 11  1  payloadDataType
 * 12  4  CRC-32/MPEG-2 (ilk 12 bayt + payload üzerinden)
 * 16  N  payload
 * ```
 * Gerçek gösterge ile DOĞRULANMADI; ayrıntılar docs/NAVILITE_PROTOCOL.md.
 */
object NaviLiteCodec {
    const val HEADER_SIZE = 12
    const val PREFIX_SIZE = 16
    const val VERSION = 1
    const val FRAME_TYPE_PHONE = 6

    /** Bozuk uzunluk alanına karşı üst sınır; 480×234 JPEG kareleri bunun çok altındadır. */
    const val MAX_PAYLOAD_SIZE = 1 shl 20

    private val MAGIC = byteArrayOf(0x6E, 0x41, 0x6C, 0x40)

    fun encode(frame: NaviLiteFrame): ByteArray {
        val payload = frame.payload
        require(payload.size <= MAX_PAYLOAD_SIZE) { "Payload too large: ${payload.size}" }
        val out = ByteArray(PREFIX_SIZE + payload.size)
        MAGIC.copyInto(out)
        out[4] = VERSION.toByte()
        out[5] = frame.frameType.toByte()
        out[6] = frame.serviceType.toByte()
        putIntLe(out, 7, payload.size)
        out[11] = frame.payloadDataType.toByte()
        payload.copyInto(out, PREFIX_SIZE)
        var crc = Crc32Mpeg2.update(Crc32Mpeg2.INITIAL, out, 0, HEADER_SIZE)
        crc = Crc32Mpeg2.update(crc, payload)
        putIntLe(out, HEADER_SIZE, crc)
        return out
    }

    internal fun putIntLe(target: ByteArray, offset: Int, value: Int) {
        target[offset] = value.toByte()
        target[offset + 1] = (value ushr 8).toByte()
        target[offset + 2] = (value ushr 16).toByte()
        target[offset + 3] = (value ushr 24).toByte()
    }

    internal fun getIntLe(source: ByteArray, offset: Int): Int =
        (source[offset].toInt() and 0xFF) or
            ((source[offset + 1].toInt() and 0xFF) shl 8) or
            ((source[offset + 2].toInt() and 0xFF) shl 16) or
            ((source[offset + 3].toInt() and 0xFF) shl 24)

    /**
     * Akıştan gelen baytları biriktirip tam çerçeveleri çıkarır. Magic bulunamazsa bayt bayt
     * kaydırarak yeniden eşzamanlanır. Göstergenin gönderdiği çerçevelerdeki CRC kuralı henüz
     * doğrulanmadığı için gelen CRC yalnızca [Decoded.crcValid] olarak raporlanır, çerçeve atılmaz.
     */
    class Decoder {
        class Decoded(val frame: NaviLiteFrame, val crcValid: Boolean)

        private var buffer = ByteArray(4096)
        private var size = 0

        fun feed(data: ByteArray, offset: Int = 0, length: Int = data.size - offset): List<Decoded> {
            if (size + length > buffer.size) {
                buffer = buffer.copyOf(maxOf(buffer.size * 2, size + length))
            }
            System.arraycopy(data, offset, buffer, size, length)
            size += length

            val frames = ArrayList<Decoded>()
            var position = 0
            while (size - position >= PREFIX_SIZE) {
                if (!hasMagicAt(position)) {
                    position++
                    continue
                }
                val payloadSize = getIntLe(buffer, position + 7)
                if (payloadSize < 0 || payloadSize > MAX_PAYLOAD_SIZE) {
                    position++
                    continue
                }
                val total = PREFIX_SIZE + payloadSize
                if (size - position < total) break
                val payload = buffer.copyOfRange(position + PREFIX_SIZE, position + total)
                var crc = Crc32Mpeg2.update(Crc32Mpeg2.INITIAL, buffer, position, HEADER_SIZE)
                crc = Crc32Mpeg2.update(crc, payload)
                frames += Decoded(
                    NaviLiteFrame(
                        serviceType = buffer[position + 6].toInt() and 0xFF,
                        payloadDataType = buffer[position + 11].toInt() and 0xFF,
                        payload = payload,
                        frameType = buffer[position + 5].toInt() and 0xFF,
                    ),
                    crcValid = crc == getIntLe(buffer, position + HEADER_SIZE),
                )
                position += total
            }
            // Magic'in başlangıcı olabilecek son baytlar dışında tüketilen kısmı at.
            System.arraycopy(buffer, position, buffer, 0, size - position)
            size -= position
            return frames
        }

        private fun hasMagicAt(position: Int): Boolean =
            buffer[position] == MAGIC[0] && buffer[position + 1] == MAGIC[1] &&
                buffer[position + 2] == MAGIC[2] && buffer[position + 3] == MAGIC[3]
    }
}
