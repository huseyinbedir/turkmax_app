package com.turkmax.app.streaming

import com.turkmax.app.navilite.ImageChannel
import java.io.IOException

/**
 * Kare döngüsü: en taze kareyi al → JPEG'e kodla → gönder → ACK bekle.
 *
 * Aynı anda en fazla bir onaylanmamış görüntü bulunur; eski kareler kuyruğa girmez. ACK
 * zaman aşımında bağlantı kapatılmaz, sıradaki en taze kare gönderilir. JPEG kalitesi ACK
 * süresine göre uyarlanır.
 *
 * [nextJpeg] verilen kalitede en taze karenin JPEG'ini döndürür (kare yoksa `null`); kare
 * üretimi ve kodlama bu sınıfın dışındadır.
 */
class FrameStreamingEngine(
    private val images: ImageChannel,
    private val nextJpeg: (quality: Int) -> ByteArray?,
    private val metrics: StreamingMetrics,
    private val maxFps: Int = DEFAULT_MAX_FPS,
    private val ackTimeoutMs: Long = ImageChannel.ACK_TIMEOUT_MS,
    initialQuality: Int = JpegFrameEncoder.DEFAULT_QUALITY,
    private val sleep: (Long) -> Unit = Thread::sleep,
    startQuality: Int? = null,
    /** `true` iken kare gönderilmez (gösterge içerik durdurma istediğinde). */
    private val isPaused: () -> Boolean = { false },
    /** Uyarlamanın inebileceği alt sınır. */
    private val minQuality: Int = DEFAULT_MIN_QUALITY,
) {
    /** Uyarlamanın çıkabileceği üst sınır: yapılandırılan kalite. */
    private val targetQuality =
        initialQuality.coerceIn(JpegFrameEncoder.MIN_QUALITY, JpegFrameEncoder.MAX_QUALITY)

    private val floorQuality = minQuality.coerceIn(JpegFrameEncoder.MIN_QUALITY, targetQuality)

    var quality: Int = (startQuality ?: targetQuality).coerceIn(floorQuality, targetQuality)
        private set

    /**
     * [shouldStop] `true` dönene kadar çalışır. Bağlantı koparsa [IOException] fırlatır.
     * Durdurulduğunda bekleyen son ACK için sınırlı süre bekler (bkz. protokol belgesi §7.3).
     */
    @Throws(IOException::class)
    fun run(shouldStop: () -> Boolean) {
        val minIntervalNanos = if (maxFps in 1..59) 1_000_000_000L / maxFps else 0L
        var lastSendNanos = 0L
        var pendingSequence = -1

        while (!shouldStop()) {
            if (isPaused()) {
                sleep(PAUSE_POLL_MS)
                continue
            }
            val wait = minIntervalNanos - (System.nanoTime() - lastSendNanos)
            if (lastSendNanos != 0L && wait > 0) sleep(wait / 1_000_000 + 1)

            val jpeg = nextJpeg(quality)
            if (jpeg == null) {
                sleep(NO_FRAME_POLL_MS)
                continue
            }
            lastSendNanos = System.nanoTime()
            val sequence = images.send(jpeg)
            pendingSequence = sequence
            metrics.onFrameSent(jpeg.size, quality)

            if (images.awaitAck(sequence, ackTimeoutMs)) {
                val ackMs = (System.nanoTime() - lastSendNanos) / 1_000_000.0
                metrics.onAck(ackMs)
                adaptQuality(ackMs)
                pendingSequence = -1
            } else {
                metrics.onAckTimeout()
                quality = (quality - QUALITY_STEP * 2).coerceAtLeast(floorQuality)
            }
        }
        if (pendingSequence >= 0) {
            runCatching { images.awaitAck(pendingSequence, STOP_ACK_GRACE_MS) }
        }
        // Son görüntüden hemen sonra bağlantının kapatılması bazı göstergelerde sonraki el
        // sıkışmayı bozabiliyor (protokol belgesi §7.3); kapatmadan önce kısa bir boşluk bırak.
        val sinceLastSendMs = (System.nanoTime() - lastSendNanos) / 1_000_000
        if (lastSendNanos != 0L && sinceLastSendMs < CLOSE_GAP_MS) {
            runCatching { sleep(CLOSE_GAP_MS - sinceLastSendMs) }
        }
    }

    /**
     * ACK süresi hedef kare süresini belirgin biçimde aşarsa kaliteyi düşürür; süre yeniden
     * hedefe yaklaşınca başlangıç kalitesine kadar kademeli olarak geri yükseltir.
     */
    private fun adaptQuality(ackMs: Double) {
        val budgetMs = if (maxFps in 1..59) 1000.0 / maxFps else DEFAULT_BUDGET_MS
        quality = when {
            ackMs > budgetMs * LOWER_THRESHOLD -> quality - QUALITY_STEP
            ackMs < budgetMs * RAISE_THRESHOLD -> quality + 1
            else -> quality
        }.coerceIn(floorQuality, targetQuality)
    }

    companion object {
        const val DEFAULT_MAX_FPS = 10

        /** Saha testinde kalite 10'a kadar inip görüntüyü gereksiz bozdu; taban yükseltildi. */
        const val DEFAULT_MIN_QUALITY = 25
        const val PAUSE_POLL_MS = 100L
        const val NO_FRAME_POLL_MS = 15L
        const val STOP_ACK_GRACE_MS = 500L
        const val CLOSE_GAP_MS = 300L
        private const val QUALITY_STEP = 5
        private const val DEFAULT_BUDGET_MS = 66.0
        private const val LOWER_THRESHOLD = 1.5
        private const val RAISE_THRESHOLD = 1.1
    }
}
