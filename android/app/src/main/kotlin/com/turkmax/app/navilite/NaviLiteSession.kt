package com.turkmax.app.navilite

import com.turkmax.app.bluetooth.NaviLiteTransport
import java.io.Closeable
import java.io.IOException
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit

/**
 * Açık bir [NaviLiteTransport] üzerinde çerçeve alışverişi. Gelen baytları ayrı bir thread
 * okuyup çözer; çağıran taraf [awaitFrame] ile belirli bir çerçeveyi süre sınırıyla bekler.
 *
 * Bloklayan soket okuması zaman aşımıyla kesilemediği için bekleyenleri uyandırmanın yolu
 * [close] çağırmaktır.
 */
class NaviLiteSession(
    private val transport: NaviLiteTransport,
    /** Tanılama günlüğü; varsayılan olarak kapalı (birim testleri). */
    private val log: ((String) -> Unit)? = null,
    /** Gelen her çerçeve için okuyucu thread'inde çağrılır (kuyruğa eklenmeden önce). */
    private val onFrame: ((NaviLiteFrame) -> Unit)? = null,
) : Closeable {
    private var imagesSent = 0
    private var acksSeen = 0

    private sealed interface Inbound {
        class Frame(val frame: NaviLiteFrame) : Inbound
        object Closed : Inbound
    }

    private val inbound = LinkedBlockingQueue<Inbound>()
    private val writeLock = Any()

    @Volatile
    private var closed = false

    private val reader = Thread({ readLoop() }, "turkmax-navilite-reader").apply {
        isDaemon = true
    }

    val isClosed: Boolean get() = closed

    fun start() = reader.start()

    @Throws(IOException::class)
    fun send(frame: NaviLiteFrame) {
        if (closed) throw IOException("Session is closed")
        val bytes = NaviLiteCodec.encode(frame)
        synchronized(writeLock) { transport.write(bytes) }
        log?.let { logTx(frame, it) }
    }

    /**
     * [matches] koşulunu sağlayan ilk çerçeveyi döndürür; diğerleri atlanır ve süreyi
     * sıfırlamaz. Süre dolarsa `null`. Bağlantı kapandıysa [IOException].
     */
    @Throws(IOException::class)
    fun awaitFrame(timeoutMs: Long, matches: (NaviLiteFrame) -> Boolean): NaviLiteFrame? {
        val deadline = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(timeoutMs)
        while (true) {
            val remaining = deadline - System.nanoTime()
            if (remaining <= 0) return null
            when (val item = inbound.poll(remaining, TimeUnit.NANOSECONDS)) {
                null -> return null
                is Inbound.Closed -> {
                    inbound.offer(Inbound.Closed) // sonraki bekleyenler de görsün
                    throw IOException("Connection closed")
                }
                is Inbound.Frame -> if (matches(item.frame)) return item.frame
            }
        }
    }

    override fun close() {
        if (closed) return
        closed = true
        runCatching { transport.close() }
        inbound.offer(Inbound.Closed)
    }

    private fun readLoop() {
        val decoder = NaviLiteCodec.Decoder()
        val buffer = ByteArray(4096)
        try {
            while (!closed) {
                val count = transport.read(buffer, 0, buffer.size)
                if (count < 0) break
                for (decoded in decoder.feed(buffer, 0, count)) {
                    log?.let { logRx(decoded, it) }
                    onFrame?.invoke(decoded.frame)
                    inbound.offer(Inbound.Frame(decoded.frame))
                }
            }
        } catch (e: IOException) {
            // Bağlantı koptu veya close() çağrıldı.
            if (!closed) log?.invoke("read error: $e")
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
        } finally {
            closed = true
            inbound.offer(Inbound.Closed)
        }
    }

    /** Görüntü çerçeveleri çok sık olduğundan yalnızca ilk birkaçı ve her 150'ncisi yazılır. */
    private fun logTx(frame: NaviLiteFrame, log: (String) -> Unit) {
        if (frame.serviceType == ServiceType.IMAGE) {
            imagesSent++
            if (imagesSent <= 3 || imagesSent % 150 == 0) {
                log("TX IMAGE #$imagesSent seq=${ImageChannel.imageSequence(frame.payload)} bytes=${frame.payload.size - 3}")
            }
        } else {
            log("TX svc=${frame.serviceType} pdt=${frame.payloadDataType} len=${frame.payload.size} [${hex(frame.payload)}]")
        }
    }

    private fun logRx(decoded: NaviLiteCodec.Decoder.Decoded, log: (String) -> Unit) {
        val frame = decoded.frame
        if (frame.serviceType == ServiceType.IMAGE_ACK) {
            acksSeen++
            if (acksSeen > 3 && acksSeen % 150 != 0) return
        }
        log(
            "RX svc=${frame.serviceType} type=${frame.frameType} pdt=${frame.payloadDataType} " +
                "len=${frame.payload.size} crc=${if (decoded.crcValid) "ok" else "BAD"} [${hex(frame.payload)}]",
        )
    }

    private fun hex(bytes: ByteArray): String {
        val shown = bytes.take(24).joinToString(" ") { "%02X".format(it) }
        return if (bytes.size > 24) "$shown …(+${bytes.size - 24})" else shown
    }
}
