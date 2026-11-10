package com.turkmax.app.bluetooth

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import com.turkmax.app.diagnostics.SessionLog
import java.io.IOException
import java.util.UUID

/**
 * Eşleşmiş bir Yamaha CCU'ya Bluetooth Classic RFCOMM (SPP) üzerinden bağlanır.
 *
 * Gerçek motosiklet üzerinde DOĞRULANMADI. Çağıran taraf `BLUETOOTH_CONNECT` iznini önceden
 * almış olmalıdır.
 */
class BluetoothRfcommTransport(
    private val device: BluetoothDevice,
    private val adapter: BluetoothAdapter? = null,
) : NaviLiteTransport {
    @Volatile
    private var socket: BluetoothSocket? = null

    override val isOpen: Boolean
        get() = socket?.isConnected == true

    @SuppressLint("MissingPermission")
    override fun open() {
        close()
        // Süren bir cihaz araması RFCOMM bağlantısını yavaşlatır/başarısız kılar.
        runCatching { adapter?.cancelDiscovery() }

        // Önce belgelenen yöntem (insecure, SDP ile); olmazsa secure soket denenir.
        val attempts: List<Pair<String, () -> BluetoothSocket>> = listOf(
            "insecure" to { device.createInsecureRfcommSocketToServiceRecord(NAVILITE_SERVICE_UUID) },
            "secure" to { device.createRfcommSocketToServiceRecord(NAVILITE_SERVICE_UUID) },
        )
        var lastError: IOException? = null
        for ((name, create) in attempts) {
            val candidate = try {
                create()
            } catch (e: IOException) {
                SessionLog.log("BT", "$name socket create failed: $e")
                lastError = e
                continue
            }
            try {
                SessionLog.log("BT", "connecting ($name RFCOMM, uuid 0x7220)…")
                candidate.connect()
                socket = candidate
                SessionLog.log("BT", "connected ($name)")
                return
            } catch (e: IOException) {
                SessionLog.log("BT", "$name connect failed: $e")
                lastError = e
                runCatching { candidate.close() }
            }
        }
        throw lastError ?: IOException("RFCOMM connect failed")
    }

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int =
        requireSocket().inputStream.read(buffer, offset, length)

    override fun write(bytes: ByteArray) {
        requireSocket().outputStream.apply {
            write(bytes)
            flush()
        }
    }

    override fun close() {
        socket?.let { runCatching { it.close() } }
        socket = null
    }

    private fun requireSocket(): BluetoothSocket =
        socket ?: throw IOException("Transport is not open")

    companion object {
        /** NaviLite SPP servis UUID'si (16 bit kısa biçim: 0x7220). Bkz. docs/NAVILITE_PROTOCOL.md. */
        val NAVILITE_SERVICE_UUID: UUID = UUID.fromString("00007220-0000-1000-8000-00805F9B34FB")
    }
}
