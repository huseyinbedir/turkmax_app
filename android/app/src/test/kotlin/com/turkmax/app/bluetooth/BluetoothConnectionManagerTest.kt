package com.turkmax.app.bluetooth

import com.turkmax.app.navilite.FakeCcu
import java.io.IOException
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicInteger
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BluetoothConnectionManagerTest {
    private val phases = CopyOnWriteArrayList<ConnectionPhase>()
    private val manager = BluetoothConnectionManager(
        frameSourceFactory = { _, _ -> { quality -> byteArrayOf(quality.toByte()) } },
        reconnectDelayMs = 30,
        handshakeTimeoutMs = 300,
        metricsIntervalMs = 20,
        maxReconnectDelayMs = 60,
        reconnectGiveUpMs = 400,
    ).also { m -> m.addListener { if (phases.lastOrNull() != it.phase) phases.add(it.phase) } }

    private val ccus = CopyOnWriteArrayList<FakeCcu>()
    private val attempts = AtomicInteger()

    /** Her denemede yeni bir sahte gösterge kuran hedef. */
    private fun target(optionsFor: (attempt: Int) -> FakeCcu.Options? = { FakeCcu.Options() }) =
        ConnectionTarget("Test CCU") {
            val options = optionsFor(attempts.incrementAndGet())
                ?: throw IOException("connect refused")
            val (phoneEnd, gaugeEnd) = PipeTransport.createPair()
            ccus += FakeCcu(gaugeEnd, options).also { it.start() }
            phoneEnd
        }

    @After
    fun tearDown() {
        manager.requestDisconnect()
        ccus.forEach { it.close() }
    }

    private fun waitFor(phase: ConnectionPhase) = waitUntil { manager.snapshot.phase == phase }

    private fun waitUntil(timeoutMs: Long = 3_000, condition: () -> Boolean) {
        val deadline = System.currentTimeMillis() + timeoutMs
        while (!condition()) {
            check(System.currentTimeMillis() < deadline) {
                "Condition not met; phase=${manager.snapshot.phase} history=$phases"
            }
            Thread.sleep(5)
        }
    }

    @Test
    fun `connects, authenticates and reports the gauge profile`() {
        manager.connect(target(), autoReconnect = true)
        waitFor(ConnectionPhase.READY)

        val snapshot = manager.snapshot
        assertEquals("Test CCU", snapshot.deviceName)
        assertEquals("006-B3952-03", snapshot.partNumber)
        assertEquals(480, snapshot.frameWidth)
        assertEquals(234, snapshot.frameHeight)
        assertEquals(
            listOf(
                ConnectionPhase.DISCONNECTED,
                ConnectionPhase.CONNECTING,
                ConnectionPhase.AUTHENTICATING,
                ConnectionPhase.READY,
            ),
            phases.toList(),
        )
    }

    @Test
    fun `streams on request, publishes metrics and returns to ready`() {
        manager.connect(target(), autoReconnect = true)
        waitFor(ConnectionPhase.READY)

        manager.startStreaming()
        waitUntil { (manager.snapshot.metrics?.framesAcked ?: 0) >= 5 }
        assertEquals(ConnectionPhase.STREAMING, manager.snapshot.phase)
        assertTrue(ccus.single().imagesReceived >= 5)

        manager.stopStreaming()
        waitFor(ConnectionPhase.READY)
        val received = ccus.single().imagesReceived
        Thread.sleep(80)
        assertEquals("no frames after stop", received, ccus.single().imagesReceived)
    }

    @Test
    fun `user disconnect ends in disconnected and does not reconnect`() {
        manager.connect(target(), autoReconnect = true)
        waitFor(ConnectionPhase.READY)
        manager.startStreaming()
        waitFor(ConnectionPhase.STREAMING)

        manager.requestDisconnect()
        assertEquals(ConnectionPhase.DISCONNECTED, manager.snapshot.phase)
        Thread.sleep(120)
        assertEquals(1, attempts.get())
        assertEquals(ConnectionPhase.DISCONNECTED, manager.snapshot.phase)
    }

    @Test
    fun `first connection failure is reported and not retried`() {
        manager.connect(target { null }, autoReconnect = true)
        waitFor(ConnectionPhase.FAILED)
        assertEquals(BluetoothConnectionManager.ERROR_CONNECT_FAILED, manager.snapshot.errorCode)
        Thread.sleep(100)
        assertEquals(1, attempts.get())
    }

    @Test
    fun `silent gauge fails with handshake timeout`() {
        manager.connect(target { FakeCcu.Options(silent = true) }, autoReconnect = true)
        waitFor(ConnectionPhase.FAILED)
        assertEquals(BluetoothConnectionManager.ERROR_HANDSHAKE_TIMEOUT, manager.snapshot.errorCode)
    }

    @Test
    fun `link loss while streaming reconnects and resumes`() {
        manager.connect(
            target { attempt ->
                if (attempt == 1) FakeCcu.Options(disconnectAfterImages = 3) else FakeCcu.Options()
            },
            autoReconnect = true,
        )
        waitFor(ConnectionPhase.READY)
        manager.startStreaming()

        waitUntil { attempts.get() == 2 && manager.snapshot.phase == ConnectionPhase.STREAMING }
        assertTrue(ConnectionPhase.RECONNECTING in phases)
        waitUntil { ccus.last().imagesReceived >= 3 }
    }

    @Test
    fun `link loss without auto reconnect ends in failed`() {
        manager.connect(target { FakeCcu.Options(disconnectAfterImages = 2) }, autoReconnect = false)
        waitFor(ConnectionPhase.READY)
        manager.startStreaming()
        waitFor(ConnectionPhase.FAILED)
        assertEquals(BluetoothConnectionManager.ERROR_LINK_LOST, manager.snapshot.errorCode)
        assertEquals(1, attempts.get())
    }

    @Test
    fun `gauge going away while idle is detected`() {
        manager.connect(target(), autoReconnect = false)
        waitFor(ConnectionPhase.READY)
        ccus.single().close()
        waitFor(ConnectionPhase.FAILED)
        assertEquals(BluetoothConnectionManager.ERROR_LINK_LOST, manager.snapshot.errorCode)
    }

    @Test
    fun `gauge stop request pauses frames and start request resumes them`() {
        manager.connect(target(), autoReconnect = false)
        waitFor(ConnectionPhase.READY)
        manager.startStreaming()
        val ccu = ccus.single()
        waitUntil { ccu.imagesReceived >= 3 }

        ccu.requestContent(start = false)
        Thread.sleep(250)
        val paused = ccu.imagesReceived
        Thread.sleep(300)
        assertTrue("frames kept flowing while paused", ccu.imagesReceived - paused <= 1)
        assertEquals(ConnectionPhase.STREAMING, manager.snapshot.phase)

        ccu.requestContent(start = true)
        waitUntil { ccu.imagesReceived >= paused + 3 }
    }

    @Test
    fun `reconnect backs off and gives up after the time limit`() {
        manager.connect(
            target { attempt -> if (attempt == 1) FakeCcu.Options(disconnectAfterImages = 1) else null },
            autoReconnect = true,
        )
        waitFor(ConnectionPhase.READY)
        manager.startStreaming()

        waitUntil(timeoutMs = 4_000) { manager.snapshot.phase == ConnectionPhase.FAILED }
        assertEquals(BluetoothConnectionManager.ERROR_CONNECT_FAILED, manager.snapshot.errorCode)
        // 30 ms'den başlayıp 60 ms'de sınırlanan beklemeyle 400 ms içinde yalnızca birkaç deneme.
        assertTrue("attempts=${attempts.get()}", attempts.get() in 3..12)
        val settled = attempts.get()
        Thread.sleep(200)
        assertEquals("no attempts after giving up", settled, attempts.get())
    }

    @Test
    fun `frame height override replaces the detected profile`() {
        manager.connect(target(), autoReconnect = false, options = StreamOptions(frameHeightOverride = 240))
        waitFor(ConnectionPhase.READY)
        assertEquals(480, manager.snapshot.frameWidth)
        assertEquals(240, manager.snapshot.frameHeight)
        assertEquals("006-B3952-03", manager.snapshot.partNumber)
    }
}
