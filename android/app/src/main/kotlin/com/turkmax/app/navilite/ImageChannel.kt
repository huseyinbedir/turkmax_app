package com.turkmax.app.navilite

import java.io.IOException

/**
 * Görüntü kanalı: tek çerçevede `[imageType=3][seq u16 LE][JPEG]` gönderir ve eşleşen
 * IMAGE_ACK'yi bekler (stop-and-wait). Sıra numarası her bağlantıda 1'den başlar.
 */
class ImageChannel(private val session: NaviLiteSession) {
    private var nextSequence = 1

    /** Görüntüyü gönderir ve kullanılan sıra numarasını döndürür. */
    @Throws(IOException::class)
    fun send(jpeg: ByteArray): Int {
        val sequence = nextSequence
        nextSequence = (nextSequence + 1) and 0xFFFF
        session.send(NaviLiteFrame(ServiceType.IMAGE, PayloadDataType.POINTER.wire, imagePayload(sequence, jpeg)))
        return sequence
    }

    /**
     * [sequence] için ACK gelene kadar bekler. Başka sıra numaralı, bozuk veya farklı türdeki
     * çerçeveler yok sayılır ve süreyi sıfırlamaz. Süre dolarsa `false`.
     */
    @Throws(IOException::class)
    fun awaitAck(sequence: Int, timeoutMs: Long = ACK_TIMEOUT_MS): Boolean =
        session.awaitFrame(timeoutMs) {
            it.serviceType == ServiceType.IMAGE_ACK && ackSequence(it.payload) == sequence
        } != null

    companion object {
        const val IMAGE_TYPE = 3
        const val ACK_TIMEOUT_MS = 2_000L

        fun imagePayload(sequence: Int, jpeg: ByteArray): ByteArray {
            val payload = ByteArray(3 + jpeg.size)
            payload[0] = IMAGE_TYPE.toByte()
            payload[1] = sequence.toByte()
            payload[2] = (sequence ushr 8).toByte()
            jpeg.copyInto(payload, 3)
            return payload
        }

        /** IMAGE payload'ındaki sıra numarası; biçim geçersizse `null`. */
        fun imageSequence(payload: ByteArray): Int? =
            if (payload.size >= 3) (payload[1].toInt() and 0xFF) or ((payload[2].toInt() and 0xFF) shl 8)
            else null

        fun ackPayload(sequence: Int) = byteArrayOf(sequence.toByte(), (sequence ushr 8).toByte())

        /** ACK'nin onayladığı sıra numarası; 2 bayttan kısa ACK bozuk sayılır (`null`). */
        fun ackSequence(payload: ByteArray): Int? =
            if (payload.size >= 2) (payload[0].toInt() and 0xFF) or ((payload[1].toInt() and 0xFF) shl 8)
            else null
    }
}
