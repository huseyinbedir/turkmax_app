package com.turkmax.app.navilite

import com.turkmax.app.bluetooth.NaviLiteTransport
import java.io.Closeable
import java.io.IOException
import java.util.concurrent.atomic.AtomicInteger
import kotlin.random.Random

/**
 * Gerçek motosiklet olmadan test için sahte gösterge (CCU). Bir taşımanın "gösterge" ucunda
 * çalışır: el sıkışmayı yürütür, gelen görüntüleri saklar ve IMAGE_ACK gönderir.
 *
 * Davranışı docs/NAVILITE_PROTOCOL.md'deki tarife göre modellenmiştir; gerçek bir CCU'nun
 * tüm davranışlarını temsil ettiği iddia edilmez.
 */
class FakeCcu(
    private val transport: NaviLiteTransport,
    private val options: Options = Options(),
) : Closeable {
    class Options(
        val partNumber: String = "006-B3952-03",
        /** Her ACK'den önce beklenen süre (göstergenin kod çözme gecikmesi). */
        val ackDelayMs: Long = 0,
        /** N > 0 ise her N'inci görüntünün ACK'si hiç gönderilmez. */
        val dropAckEvery: Int = 0,
        /** N > 0 ise her N'inci ACK yanlış sıra numarasıyla gönderilir. */
        val corruptAckEvery: Int = 0,
        /** N > 0 ise N görüntüden sonra bağlantıyı kapatır. */
        val disconnectAfterImages: Int = 0,
        /** `true` ise ESN_UPDATE hiç gönderilmez (el sıkışma zaman aşımı senaryosu). */
        val silent: Boolean = false,
        val nonce: ByteArray? = null,
    )

    private val nonce = options.nonce ?: Random.nextBytes(NaviLiteHandshake.NONCE_SIZE)
    private val imageCount = AtomicInteger()
    private val setupCount = AtomicInteger()

    @Volatile
    var authenticated = false
        private set

    @Volatile
    var lastImage: ByteArray? = null
        private set

    val imagesReceived: Int get() = imageCount.get()
    val setupFramesReceived: Int get() = setupCount.get()

    private val thread = Thread({ run() }, "turkmax-fake-ccu").apply { isDaemon = true }

    fun start() {
        transport.open()
        thread.start()
    }

    /** Göstergenin içerik başlat (55) / durdur (56) isteğini taklit eder. */
    fun requestContent(start: Boolean) = send(
        if (start) ServiceType.CONTENT_START else ServiceType.CONTENT_STOP,
        byteArrayOf(1, 0),
    )

    override fun close() {
        runCatching { transport.close() }
        thread.interrupt()
    }

    private fun run() {
        try {
            if (options.silent) {
                drain()
                return
            }
            send(ServiceType.ESN_UPDATE, "FAKE-ESN".toByteArray(Charsets.US_ASCII))
            val decoder = NaviLiteCodec.Decoder()
            val buffer = ByteArray(8192)
            while (true) {
                val count = transport.read(buffer, 0, buffer.size)
                if (count < 0) return
                for (decoded in decoder.feed(buffer, 0, count)) {
                    if (!handle(decoded.frame)) return
                }
            }
        } catch (_: IOException) {
            // Telefon tarafı bağlantıyı kapattı.
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
        } finally {
            runCatching { transport.close() }
        }
    }

    /** `false` dönerse bağlantı kapatılır. */
    private fun handle(frame: NaviLiteFrame): Boolean {
        when (frame.serviceType) {
            ServiceType.AUTH_REQUEST ->
                send(ServiceType.SEC_DATA, NaviLiteHandshake.encodeSecData(options.partNumber, nonce))
            ServiceType.SEC_DATA_ACK -> authenticated = frame.payload.contentEquals(nonce)
            ServiceType.IMAGE -> return handleImage(frame.payload)
            ServiceType.ESN_ACK -> Unit
            else -> if (authenticated) setupCount.incrementAndGet()
        }
        return true
    }

    private fun handleImage(payload: ByteArray): Boolean {
        // Gerçek gösterge doğrulanmamış oturumdan gelen görüntüyü çizmez varsayımı.
        if (!authenticated) return true
        val sequence = ImageChannel.imageSequence(payload) ?: return true
        lastImage = payload.copyOfRange(3, payload.size)
        val index = imageCount.incrementAndGet()

        if (options.ackDelayMs > 0) Thread.sleep(options.ackDelayMs)
        val drop = options.dropAckEvery > 0 && index % options.dropAckEvery == 0
        val corrupt = options.corruptAckEvery > 0 && index % options.corruptAckEvery == 0
        if (!drop) {
            val ackSequence = if (corrupt) (sequence + 1000) and 0xFFFF else sequence
            send(ServiceType.IMAGE_ACK, ImageChannel.ackPayload(ackSequence))
        }
        return options.disconnectAfterImages <= 0 || index < options.disconnectAfterImages
    }

    private fun drain() {
        val buffer = ByteArray(1024)
        while (transport.read(buffer, 0, buffer.size) >= 0) Unit
    }

    @Synchronized
    private fun send(serviceType: Int, payload: ByteArray) {
        transport.write(
            NaviLiteCodec.encode(
                NaviLiteFrame(serviceType, PayloadDataType.POINTER.wire, payload, FRAME_TYPE_GAUGE),
            ),
        )
    }

    private companion object {
        /** Gösterge → telefon çerçevelerinin gerçek frameType değeri doğrulanmadı. */
        const val FRAME_TYPE_GAUGE = 6
    }
}
