package com.turkmax.app.bluetooth

import java.io.IOException
import java.util.concurrent.LinkedBlockingQueue

/**
 * Bellek içi çift yönlü boru. [createPair] birbirine bağlı iki uç döndürür: biri telefon
 * tarafı, diğeri sahte gösterge (`FakeCcu`) tarafı. Bluetooth gerektirmez.
 */
class PipeTransport private constructor(
    private val incoming: LinkedBlockingQueue<ByteArray>,
    private val outgoing: LinkedBlockingQueue<ByteArray>,
) : NaviLiteTransport {
    private var pending: ByteArray = EOF
    private var pendingOffset = 0
    private var reachedEnd = false

    @Volatile
    override var isOpen: Boolean = false
        private set

    override fun open() {
        isOpen = true
    }

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
        if (reachedEnd) return -1
        if (pendingOffset >= pending.size) {
            pending = incoming.take()
            pendingOffset = 0
            if (pending === EOF) {
                reachedEnd = true
                return -1
            }
        }
        val count = minOf(length, pending.size - pendingOffset)
        System.arraycopy(pending, pendingOffset, buffer, offset, count)
        pendingOffset += count
        return count
    }

    override fun write(bytes: ByteArray) {
        if (!isOpen) throw IOException("Transport is not open")
        if (bytes.isNotEmpty()) outgoing.put(bytes.copyOf())
    }

    /** İki yönü de sonlandırır: karşı uç akış sonu görür, bu uçta bekleyen okuma uyanır. */
    override fun close() {
        if (!isOpen) return
        isOpen = false
        outgoing.put(EOF)
        incoming.put(EOF)
    }

    companion object {
        private val EOF = ByteArray(0)

        fun createPair(): Pair<PipeTransport, PipeTransport> {
            val aToB = LinkedBlockingQueue<ByteArray>()
            val bToA = LinkedBlockingQueue<ByteArray>()
            return PipeTransport(bToA, aToB) to PipeTransport(aToB, bToA)
        }
    }
}
