package com.turkmax.app.bluetooth

import com.turkmax.app.diagnostics.SessionLog
import com.turkmax.app.navilite.CcuDeviceProfile
import com.turkmax.app.navilite.HandshakeTimeoutException
import com.turkmax.app.navilite.ImageChannel
import com.turkmax.app.navilite.NaviLiteFrame
import com.turkmax.app.navilite.NaviLiteHandshake
import com.turkmax.app.navilite.NaviLiteSession
import com.turkmax.app.navilite.ServiceType
import com.turkmax.app.streaming.FrameStreamingEngine
import com.turkmax.app.streaming.StreamingMetrics
import java.io.IOException
import java.util.concurrent.CopyOnWriteArraySet
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

/** Bağlantı durum makinesinin fazları. Dart karşılığı: `TftConnectionPhase`. */
enum class ConnectionPhase(val wireName: String) {
    DISCONNECTED("disconnected"),
    CONNECTING("connecting"),
    AUTHENTICATING("authenticating"),
    READY("ready"),
    STREAMING("streaming"),
    RECONNECTING("reconnecting"),
    FAILED("failed"),
}

data class ConnectionSnapshot(
    val phase: ConnectionPhase = ConnectionPhase.DISCONNECTED,
    val deviceName: String? = null,
    val errorCode: String? = null,
    val partNumber: String? = null,
    val frameWidth: Int? = null,
    val frameHeight: Int? = null,
    val metrics: StreamingMetrics.Snapshot? = null,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "phase" to phase.wireName,
        "deviceName" to deviceName,
        "errorCode" to errorCode,
        "partNumber" to partNumber,
        "frameWidth" to frameWidth,
        "frameHeight" to frameHeight,
        "metrics" to metrics?.toMap(),
    )
}

/** Bir bağlantı hedefi: her denemede yeni bir taşıma üretir. */
class ConnectionTarget(
    val deviceName: String,
    val transportFactory: () -> NaviLiteTransport,
)

/**
 * Bağlantı durum makinesinin tek sahibi: bağlan → el sıkış → hazır → (akış) → kopunca yeniden
 * bağlan. Tüm bloklayan işler kendi thread'inde yürür.
 *
 * Kurallar:
 * * Kullanıcının [requestDisconnect] talebi her zaman uygulanır ve yeniden bağlanmayı durdurur.
 * * Otomatik yeniden bağlanma yalnızca en az bir başarılı el sıkışmadan sonra devrededir
 *   (yanlış cihazda sonsuz döngüyü önlemek için).
 * * Görüntü üretimi bu sınıftan bağımsızdır: kareler [frameSourceFactory] üzerinden gelir.
 */
class BluetoothConnectionManager(
    private val frameSourceFactory: (CcuDeviceProfile, StreamOptions) -> (quality: Int) -> ByteArray?,
    private val reconnectDelayMs: Long = RECONNECT_DELAY_MS,
    private val handshakeTimeoutMs: Long = NaviLiteHandshake.TIMEOUT_MS,
    private val metricsIntervalMs: Long = 1_000,
    private val maxReconnectDelayMs: Long = MAX_RECONNECT_DELAY_MS,
    /** Bağlantı koptuktan sonra yeniden bağlanmanın denenmeye devam edeceği azami süre. */
    private val reconnectGiveUpMs: Long = RECONNECT_GIVE_UP_MS,
) {
    private val listeners = CopyOnWriteArraySet<(ConnectionSnapshot) -> Unit>()
    private val lock = Object()
    private var ticker: ScheduledExecutorService? = null

    @Volatile
    var snapshot: ConnectionSnapshot = ConnectionSnapshot()
        private set

    // Aşağıdaki alanlar [lock] ile korunur.
    private var worker: Thread? = null
    private var session: NaviLiteSession? = null
    private var stopRequested = false
    private var streamingRequested = false
    private var metrics: StreamingMetrics? = null

    /** Gösterge içerik durdurma istedi (56); başlat isteği (55) gelene kadar kare gönderilmez. */
    @Volatile
    private var contentPaused = false

    /** Dinleyici eklenir eklenmez güncel durumu alır. */
    fun addListener(listener: (ConnectionSnapshot) -> Unit) {
        listeners.add(listener)
        listener(snapshot)
    }

    fun removeListener(listener: (ConnectionSnapshot) -> Unit) {
        listeners.remove(listener)
    }

    /** Yeni bir bağlantı başlatır; süren bağlantı varsa önce kapatılır. */
    fun connect(
        target: ConnectionTarget,
        autoReconnect: Boolean,
        options: StreamOptions = StreamOptions(),
    ) {
        requestDisconnect()
        synchronized(lock) {
            stopRequested = false
            streamingRequested = false
            worker = Thread({ runConnection(target, autoReconnect, options) }, "turkmax-connection").apply {
                isDaemon = true
                start()
            }
        }
    }

    fun startStreaming() = synchronized(lock) {
        streamingRequested = true
        lock.notifyAll()
    }

    fun stopStreaming() = synchronized(lock) {
        streamingRequested = false
        lock.notifyAll()
    }

    /** Kullanıcının bağlantıyı kesme talebi; yeniden bağlanmayı da durdurur. Bloklar. */
    fun requestDisconnect() {
        val thread: Thread?
        synchronized(lock) {
            stopRequested = true
            streamingRequested = false
            thread = worker
            worker = null
            lock.notifyAll()
        }
        if (thread != null && thread !== Thread.currentThread()) {
            // Akış döngüsüne bekleyen ACK için sınırlı süre tanı, sonra soketi kapat.
            thread.join(FrameStreamingEngine.STOP_ACK_GRACE_MS + 200)
            synchronized(lock) { session }?.close()
            thread.join(2_000)
        }
        stopTicker()
        update(ConnectionSnapshot())
    }

    private fun runConnection(target: ConnectionTarget, autoReconnect: Boolean, options: StreamOptions) {
        SessionLog.log("CONN", "connect to '${target.deviceName}' autoReconnect=$autoReconnect $options")
        var everConnected = false
        var failedAttempts = 0
        var linkLostAtNanos = 0L
        var base = ConnectionSnapshot(deviceName = target.deviceName)
        while (!isStopRequested()) {
            update(base.copy(phase = if (everConnected) ConnectionPhase.RECONNECTING else ConnectionPhase.CONNECTING))
            var errorCode = ERROR_CONNECT_FAILED
            var currentSession: NaviLiteSession? = null
            try {
                val transport = target.transportFactory()
                transport.open()
                contentPaused = false
                currentSession = NaviLiteSession(
                    transport,
                    log = { SessionLog.log("NAVI", it) },
                    onFrame = ::onGaugeFrame,
                )
                synchronized(lock) { session = currentSession }
                if (isStopRequested()) return
                currentSession.start()

                errorCode = ERROR_HANDSHAKE_FAILED
                update(base.copy(phase = ConnectionPhase.AUTHENTICATING))
                val handshakeStart = System.nanoTime()
                val result = NaviLiteHandshake.perform(
                    currentSession,
                    handshakeTimeoutMs,
                    options.navStatusActive,
                )
                everConnected = true
                failedAttempts = 0
                linkLostAtNanos = 0L
                val profile = options.frameHeightOverride
                    ?.let { result.profile.copy(id = "override", height = it) }
                    ?: result.profile
                SessionLog.log(
                    "CONN",
                    "handshake ok in ${(System.nanoTime() - handshakeStart) / 1_000_000} ms; " +
                        "part='${result.partNumber}' auto=${result.profile.width}x${result.profile.height} " +
                        "using=${profile.width}x${profile.height}",
                )
                base = base.copy(
                    partNumber = result.partNumber,
                    frameWidth = profile.width,
                    frameHeight = profile.height,
                )

                errorCode = ERROR_LINK_LOST
                serve(currentSession, profile, base, options)
            } catch (e: SecurityException) {
                errorCode = ERROR_PERMISSION_DENIED
                SessionLog.log("CONN", "error: $e")
            } catch (e: HandshakeTimeoutException) {
                errorCode = ERROR_HANDSHAKE_TIMEOUT
                SessionLog.log("CONN", "error: $e")
            } catch (e: IOException) {
                // errorCode, hatanın oluştuğu aşamaya göre yukarıda belirlendi.
                SessionLog.log("CONN", "error ($errorCode): $e")
            } catch (e: InterruptedException) {
                return
            } catch (e: RuntimeException) {
                // Beklenmeyen hata uygulamayı düşürmesin; bağlantı hatası olarak raporla.
                errorCode = ERROR_INTERNAL
                SessionLog.log("CONN", "internal error: ${e.stackTraceToString().take(600)}")
            } finally {
                currentSession?.close()
                synchronized(lock) { if (session === currentSession) session = null }
                stopTicker()
            }
            if (isStopRequested()) return
            if (!(everConnected && autoReconnect)) {
                update(base.copy(phase = ConnectionPhase.FAILED, errorCode = errorCode))
                return
            }
            // Artan bekleme ve azami süre: motosiklet kapalıyken sonsuza dek denenmesin.
            if (linkLostAtNanos == 0L) linkLostAtNanos = System.nanoTime()
            val elapsedMs = (System.nanoTime() - linkLostAtNanos) / 1_000_000
            if (elapsedMs >= reconnectGiveUpMs) {
                SessionLog.log("CONN", "giving up reconnect after ${elapsedMs / 1000} s")
                update(base.copy(phase = ConnectionPhase.FAILED, errorCode = errorCode))
                return
            }
            val delayMs = (reconnectDelayMs shl minOf(failedAttempts, 10)).coerceAtMost(maxReconnectDelayMs)
            failedAttempts++
            update(base.copy(phase = ConnectionPhase.RECONNECTING, errorCode = errorCode))
            if (!sleepUnlessStopped(delayMs)) return
        }
    }

    /** El sıkışma sonrası: hazır bekle, istenince akışı çalıştır. Bağlantı koparsa fırlatır. */
    private fun serve(
        session: NaviLiteSession,
        profile: CcuDeviceProfile,
        base: ConnectionSnapshot,
        options: StreamOptions,
    ) {
        val images = ImageChannel(session)
        val source = frameSourceFactory(profile, options)
        while (!isStopRequested()) {
            update(base.copy(phase = ConnectionPhase.READY))
            synchronized(lock) {
                while (!stopRequested && !streamingRequested && !session.isClosed) {
                    lock.wait(IDLE_POLL_MS)
                }
            }
            if (isStopRequested()) return
            if (session.isClosed) throw IOException("Connection closed while idle")

            val streamMetrics = StreamingMetrics()
            synchronized(lock) { metrics = streamMetrics }
            update(base.copy(phase = ConnectionPhase.STREAMING, metrics = streamMetrics.snapshot()))
            startTicker(base, streamMetrics)
            try {
                FrameStreamingEngine(
                    images = images,
                    nextJpeg = source,
                    metrics = streamMetrics,
                    maxFps = options.maxFps,
                    initialQuality = options.quality,
                    isPaused = { contentPaused },
                ).run {
                    synchronized(lock) { stopRequested || !streamingRequested }
                }
            } finally {
                stopTicker()
                SessionLog.log("STREAM", "stopped: ${streamMetrics.snapshot()}")
            }
        }
    }

    private fun onGaugeFrame(frame: NaviLiteFrame) {
        when (frame.serviceType) {
            ServiceType.CONTENT_STOP -> if (!contentPaused) {
                contentPaused = true
                SessionLog.log("CONN", "gauge requested content stop; pausing frames")
            }
            ServiceType.CONTENT_START -> if (contentPaused) {
                contentPaused = false
                SessionLog.log("CONN", "gauge requested content start; resuming frames")
            }
        }
    }

    private fun startTicker(base: ConnectionSnapshot, streamMetrics: StreamingMetrics) {
        stopTicker()
        ticker = Executors.newSingleThreadScheduledExecutor { runnable ->
            Thread(runnable, "turkmax-metrics").apply { isDaemon = true }
        }.also {
            var ticks = 0
            it.scheduleWithFixedDelay({
                if (snapshot.phase == ConnectionPhase.STREAMING) {
                    val current = streamMetrics.snapshot()
                    update(base.copy(phase = ConnectionPhase.STREAMING, metrics = current))
                    // Günlüğe yaklaşık 10 saniyede bir özet.
                    if (++ticks % 10 == 0) SessionLog.log("STREAM", current.toString())
                }
            }, metricsIntervalMs, metricsIntervalMs, TimeUnit.MILLISECONDS)
        }
    }

    private fun stopTicker() {
        ticker?.shutdownNow()
        ticker = null
    }

    private fun isStopRequested() = synchronized(lock) { stopRequested }

    /** Durdurma isteğine duyarlı bekleme; durdurulduysa `false`. */
    private fun sleepUnlessStopped(durationMs: Long): Boolean = synchronized(lock) {
        val deadline = System.nanoTime() + durationMs * 1_000_000
        while (!stopRequested) {
            val remaining = (deadline - System.nanoTime()) / 1_000_000
            if (remaining <= 0) return true
            lock.wait(remaining)
        }
        false
    }

    private fun update(newSnapshot: ConnectionSnapshot) {
        if (newSnapshot == snapshot) return
        if (newSnapshot.phase != snapshot.phase || newSnapshot.errorCode != snapshot.errorCode) {
            SessionLog.log(
                "CONN",
                "phase ${snapshot.phase} -> ${newSnapshot.phase}" +
                    (newSnapshot.errorCode?.let { " error=$it" } ?: ""),
            )
        }
        snapshot = newSnapshot
        listeners.forEach { it(newSnapshot) }
    }

    companion object {
        const val RECONNECT_DELAY_MS = 1_500L
        const val MAX_RECONNECT_DELAY_MS = 30_000L
        const val RECONNECT_GIVE_UP_MS = 5 * 60_000L
        private const val IDLE_POLL_MS = 250L

        /** RFCOMM açılamadı: motosiklet kapalı/menzil dışı ya da bağlantı başka uygulamada. */
        const val ERROR_CONNECT_FAILED = "CONNECT_FAILED"
        const val ERROR_HANDSHAKE_TIMEOUT = "HANDSHAKE_TIMEOUT"
        const val ERROR_HANDSHAKE_FAILED = "HANDSHAKE_FAILED"
        const val ERROR_LINK_LOST = "LINK_LOST"
        const val ERROR_PERMISSION_DENIED = "PERMISSION_DENIED"
        const val ERROR_INTERNAL = "INTERNAL_ERROR"
    }
}
