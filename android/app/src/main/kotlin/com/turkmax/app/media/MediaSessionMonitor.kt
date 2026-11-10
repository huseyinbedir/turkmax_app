package com.turkmax.app.media

/**
 * Aktif medya oturumunu (MediaSessionManager / MediaController) izleyecek bileşen.
 *
 * DURUM: yer tutucu; henüz uygulanmadı. Bildirim erişimi izni gerektirir.
 */
interface MediaSessionMonitor {
    fun start()

    fun stop()
}
