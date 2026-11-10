package com.turkmax.app.bluetooth

import java.io.Closeable
import java.io.IOException

/**
 * Kritik soyutlama 3/3: NaviLite baytlarının taşındığı çift yönlü kanal.
 *
 * Uygulamalar: [BluetoothRfcommTransport] (gerçek motosiklet) ve [FakeNaviLiteTransport]
 * (testler / sahte CCU). Protokol katmanı (`navilite` paketi) yalnızca bu arayüzü tanır;
 * görüntü üretimi ise bu arayüzden tamamen habersizdir.
 *
 * Tüm çağrılar bloklayıcıdır ve ana thread dışında yapılmalıdır.
 */
interface NaviLiteTransport : Closeable {
    val isOpen: Boolean

    @Throws(IOException::class)
    fun open()

    /** En az 1 bayt okur; akış kapandıysa -1 döner. */
    @Throws(IOException::class)
    fun read(buffer: ByteArray, offset: Int, length: Int): Int

    @Throws(IOException::class)
    fun write(bytes: ByteArray)
}
