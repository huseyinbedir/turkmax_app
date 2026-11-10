package com.turkmax.app.streaming

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import com.turkmax.app.navilite.CcuDeviceProfile
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Üçüncü taraf içerik barındırmayan teşhis karesi üretir. Gerçek göstergede şunları gözle
 * doğrulamaya yarar: görüntünün kırpılıp kırpılmadığı (kenar çerçevesi ve köşe işaretleri),
 * renklerin doğruluğu (renk şeritleri), karelerin gerçekten yenilendiği (sayaç, saat ve
 * hareketli çubuk) ve gönderilen çözünürlük.
 */
class SyntheticFrameSource(
    private val profile: CcuDeviceProfile = CcuDeviceProfile.XMAX,
) : CockpitFrameSource {
    private val bitmap = Bitmap.createBitmap(profile.width, profile.height, Bitmap.Config.ARGB_8888)
    private val canvas = Canvas(bitmap)
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val clock = SimpleDateFormat("HH:mm:ss", Locale.US)
    private var frameCounter = 0

    override val id: String = "synthetic"

    @Synchronized
    override fun latestFrame(): Bitmap {
        frameCounter++
        val w = profile.width.toFloat()
        val h = profile.height.toFloat()

        canvas.drawColor(BACKGROUND)

        // Kenar çerçevesi: dört kenarı da görünüyorsa görüntü kırpılmıyor demektir.
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 2f
        paint.color = ACCENT
        canvas.drawRect(1f, 1f, w - 1f, h - 1f, paint)

        // Köşe işaretleri.
        paint.style = Paint.Style.FILL
        paint.color = TEXT
        val corner = 14f
        canvas.drawRect(0f, 0f, corner, 3f, paint)
        canvas.drawRect(0f, 0f, 3f, corner, paint)
        canvas.drawRect(w - corner, 0f, w, 3f, paint)
        canvas.drawRect(w - 3f, 0f, w, corner, paint)
        canvas.drawRect(0f, h - 3f, corner, h, paint)
        canvas.drawRect(0f, h - corner, 3f, h, paint)
        canvas.drawRect(w - corner, h - 3f, w, h, paint)
        canvas.drawRect(w - 3f, h - corner, w, h, paint)

        // Renk şeritleri.
        val barWidth = (w - 40f) / COLOR_BARS.size
        COLOR_BARS.forEachIndexed { index, color ->
            paint.color = color
            canvas.drawRect(20f + index * barWidth, h - 46f, 20f + (index + 1) * barWidth, h - 22f, paint)
        }

        // Hareketli çubuk: her karede ilerler.
        paint.color = PRIMARY
        val travel = w - 60f
        val x = 20f + (frameCounter * 8 % travel.toInt())
        canvas.drawRect(x, h - 18f, x + 20f, h - 10f, paint)

        paint.color = TEXT
        paint.typeface = Typeface.DEFAULT_BOLD
        paint.textAlign = Paint.Align.LEFT
        paint.textSize = 30f
        canvas.drawText("TURKMAX TEST", 20f, 48f, paint)

        paint.textSize = 22f
        paint.color = ACCENT
        canvas.drawText("${profile.width}×${profile.height}", 20f, 84f, paint)

        paint.color = TEXT
        paint.typeface = Typeface.DEFAULT
        paint.textSize = 20f
        canvas.drawText("Kare #$frameCounter", 20f, 116f, paint)
        canvas.drawText(clock.format(Date()), 20f, 144f, paint)

        paint.textAlign = Paint.Align.RIGHT
        paint.color = TEXT_SECONDARY
        paint.textSize = 14f
        canvas.drawText("SENTETİK TEST KARESİ", w - 20f, 30f, paint)
        paint.textAlign = Paint.Align.LEFT
        return bitmap
    }

    private companion object {
        val BACKGROUND = Color.rgb(0x08, 0x14, 0x16)
        val PRIMARY = Color.rgb(0x14, 0xB8, 0xA6)
        val ACCENT = Color.rgb(0x2D, 0xD4, 0xBF)
        val TEXT = Color.rgb(0xF0, 0xFA, 0xF9)
        val TEXT_SECONDARY = Color.rgb(0x9B, 0xB5, 0xB3)
        val COLOR_BARS = intArrayOf(
            Color.WHITE, Color.YELLOW, Color.CYAN, Color.GREEN, Color.MAGENTA, Color.RED, Color.BLUE,
        )
    }
}
