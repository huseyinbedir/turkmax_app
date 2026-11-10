package com.turkmax.app.streaming

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.BatteryManager
import com.turkmax.app.diagnostics.SessionLog
import com.turkmax.app.navilite.CcuDeviceProfile
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * TFT karesini tümüyle native tarafta üretir: harita sanal ekrandan ([OffscreenMapRenderer]),
 * paneller [CockpitFrameRenderer] ile çizilir. Telefon ekranına bağlı olmadığı için uygulama
 * arka plandayken de güncel kare üretir.
 *
 * KULLANIM SINIRI: Google harita görüntüsünün motosiklet ekranına aktarımı için izin
 * doğrulanmadı (docs/LICENSE_AND_COMPLIANCE.md).
 */
class OffscreenCockpitFrameSource(
    private val context: Context,
    profile: CcuDeviceProfile,
    private val renderer: OffscreenMapRenderer,
    private val encoder: JpegFrameEncoder,
    private val state: () -> CockpitFrameState,
) {
    private val frame = Bitmap.createBitmap(profile.width, profile.height, Bitmap.Config.ARGB_8888)
    private val canvas = Canvas(frame)
    private val painter = CockpitFrameRenderer(profile.width, profile.height)
    private val mapBitmap = Bitmap.createBitmap(
        (painter.mapRect.width() * MAP_SCALE).toInt(),
        (painter.mapRect.height() * MAP_SCALE).toInt(),
        Bitmap.Config.ARGB_8888,
    )
    private val clockFormat = SimpleDateFormat("HH:mm", Locale.US)
    private var started = false
    private var darkMap: Boolean? = null
    private var batteryPercent: Int? = null
    private var charging = false
    private var lastBatteryReadNanos = 0L

    fun nextJpeg(quality: Int): ByteArray {
        val current = state()
        ensureMap(current.darkMap)
        readBatteryIfDue()
        val hasMap = renderer.copyLatestInto(mapBitmap)
        painter.draw(
            canvas = canvas,
            state = current,
            map = mapBitmap.takeIf { hasMap },
            clock = clockFormat.format(Date()),
            batteryPercent = batteryPercent,
            charging = charging,
        )
        return encoder.encode(frame, quality)
    }

    /** Sanal ekranı ilk karede kurar; harita modu değişirse yeniden kurar. */
    private fun ensureMap(dark: Boolean) {
        if (started && darkMap == dark) return
        runCatching {
            if (started) renderer.restart(mapBitmap.width, mapBitmap.height, MAP_DENSITY_DPI, dark)
            else renderer.start(mapBitmap.width, mapBitmap.height, MAP_DENSITY_DPI, dark)
        }.onFailure { SessionLog.log("OFFSCREEN", "start failed: $it") }
        started = true
        darkMap = dark
    }

    private fun readBatteryIfDue() {
        val now = System.nanoTime()
        if (lastBatteryReadNanos != 0L && now - lastBatteryReadNanos < 10_000_000_000L) return
        lastBatteryReadNanos = now
        // Yapışkan yayın: alıcı kaydetmeden son değer okunur.
        val intent = runCatching {
            context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        }.getOrNull() ?: return
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        batteryPercent = if (level >= 0 && scale > 0) level * 100 / scale else null
        charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL
    }

    private companion object {
        /** Harita, TFT'deki boyutunun iki katında çizilip küçültülür (daha temiz kenarlar). */
        const val MAP_SCALE = 2
        const val MAP_DENSITY_DPI = 240
    }
}
