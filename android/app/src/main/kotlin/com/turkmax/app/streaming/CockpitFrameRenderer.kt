package com.turkmax.app.streaming

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.text.TextPaint
import android.text.TextUtils

/**
 * Tek cockpit ekranını TFT çözünürlüğünde Canvas ile çizer. Yerleşim, Flutter'daki
 * `CockpitView` ile aynıdır: topbar 26 px; sol %66 harita; sağda yönlendirme / bildirim / medya.
 *
 * Renkler `lib/core/design/app_colors.dart` ile aynı tutulmalıdır.
 */
class CockpitFrameRenderer(private val width: Int, private val height: Int) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
    private val text = TextPaint(Paint.ANTI_ALIAS_FLAG)
    private val path = Path()
    private val rect = RectF()

    private val mapRight = (width * MAP_FRACTION)
    val mapRect = RectF(GAP, TOP_BAR, mapRight - GAP / 2, height - GAP)
    private val panelLeft = mapRight + GAP / 2
    private val panelRight = width - GAP

    fun draw(
        canvas: Canvas,
        state: CockpitFrameState,
        map: Bitmap?,
        clock: String,
        batteryPercent: Int?,
        charging: Boolean,
    ) {
        canvas.drawColor(BACKGROUND)
        drawTopBar(canvas, state, clock, batteryPercent, charging)
        drawMap(canvas, map)

        // Sağ panel: 42 / 26 / 32 oranında üç kart.
        val available = height - GAP - TOP_BAR - 2 * GAP
        val navBottom = TOP_BAR + available * 0.42f
        val notificationBottom = navBottom + GAP + available * 0.26f
        drawNavigationCard(canvas, state, TOP_BAR, navBottom)
        drawNotificationCard(canvas, state, navBottom + GAP, notificationBottom)
        drawMediaCard(canvas, state, notificationBottom + GAP, height - GAP)
    }

    private fun drawTopBar(
        canvas: Canvas,
        state: CockpitFrameState,
        clock: String,
        batteryPercent: Int?,
        charging: Boolean,
    ) {
        val baseline = TOP_BAR / 2 + 4.5f
        text.set(13f, TEXT, bold = true)
        canvas.drawText(clock, 8f, baseline, text)
        var x = 8f + text.measureText(clock) + 8f

        state.demoBadge?.let { badge ->
            text.set(9f, WARNING, bold = true)
            val badgeWidth = text.measureText(badge) + 8f
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 1f
            paint.color = WARNING
            rect.set(x, 7f, x + badgeWidth, TOP_BAR - 7f)
            canvas.drawRoundRect(rect, 3f, 3f, paint)
            paint.style = Paint.Style.FILL
            canvas.drawText(badge, x + 4f, baseline - 1.5f, text)
            x += badgeWidth
        }

        val low = !charging && batteryPercent != null && batteryPercent <= 15
        text.set(13f, if (low) DANGER else TEXT, bold = true)
        val label = batteryPercent?.let { "%$it" } ?: "--"
        val labelWidth = text.measureText(label)
        canvas.drawText(label, width - 8f - labelWidth, baseline, text)

        // Pil simgesi.
        val batteryRight = width - 8f - labelWidth - 4f
        paint.color = if (low) DANGER else TEXT
        rect.set(batteryRight - 8f, 8f, batteryRight, TOP_BAR - 7f)
        canvas.drawRoundRect(rect, 1.5f, 1.5f, paint)
        canvas.drawRect(batteryRight - 6f, 6.5f, batteryRight - 2f, 8f, paint)
        if (charging) {
            // Şimşek.
            paint.color = ACCENT
            val cx = batteryRight - 15f
            path.rewind()
            path.moveTo(cx + 2f, 6f)
            path.lineTo(cx - 3f, 14f)
            path.lineTo(cx, 14f)
            path.lineTo(cx - 2f, 20f)
            path.lineTo(cx + 3f, 12f)
            path.lineTo(cx, 12f)
            path.close()
            canvas.drawPath(path, paint)
        }
    }

    private fun drawMap(canvas: Canvas, map: Bitmap?) {
        val save = canvas.save()
        path.rewind()
        path.addRoundRect(mapRect, RADIUS, RADIUS, Path.Direction.CW)
        canvas.clipPath(path)
        if (map != null) {
            canvas.drawBitmap(map, null, mapRect, paint)
        } else {
            paint.color = SURFACE
            canvas.drawRect(mapRect, paint)
        }
        canvas.restoreToCount(save)
    }

    private fun drawPanel(canvas: Canvas, top: Float, bottom: Float) {
        rect.set(panelLeft, top, panelRight, bottom)
        paint.style = Paint.Style.FILL
        paint.color = SURFACE
        canvas.drawRoundRect(rect, RADIUS, RADIUS, paint)
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 1f
        paint.color = BORDER
        canvas.drawRoundRect(rect, RADIUS, RADIUS, paint)
        paint.style = Paint.Style.FILL
    }

    private fun drawNavigationCard(canvas: Canvas, state: CockpitFrameState, top: Float, bottom: Float) {
        drawPanel(canvas, top, bottom)
        val left = panelLeft + PADDING
        val contentWidth = panelRight - PADDING - left
        val maneuver = state.maneuver
        if (maneuver == null) {
            drawCentered(canvas, state.navigationMessage, top, bottom)
            return
        }
        val iconSize = 34f
        drawManeuver(canvas, maneuver, left, top + 6f, iconSize)

        text.set(22f, TEXT, bold = true)
        val distance = state.maneuverDistance.orEmpty()
        val distanceWidth = contentWidth - iconSize - 4f
        // Uzun mesafe metni sığmazsa küçültülür.
        val measured = text.measureText(distance)
        if (measured > distanceWidth) text.textSize = 22f * distanceWidth / measured
        canvas.drawText(distance, left + iconSize + 4f, top + 31f, text)

        var y = top + 56f
        state.roadName?.let {
            text.set(12f, TEXT, bold = true)
            canvas.drawText(ellipsize(it, contentWidth), left, y, text)
            y += 15f
        }
        state.routeLine?.let {
            text.set(10f, TEXT_SECONDARY)
            canvas.drawText(ellipsize(it, contentWidth), left, y, text)
        }
    }

    private fun drawNotificationCard(canvas: Canvas, state: CockpitFrameState, top: Float, bottom: Float) {
        drawPanel(canvas, top, bottom)
        val title = state.notificationTitle
        if (title == null) {
            drawCentered(canvas, state.notificationEmptyText, top, bottom)
            return
        }
        val center = (top + bottom) / 2
        val left = panelLeft + PADDING
        // Zil yerine sade bir işaret.
        paint.color = ACCENT
        canvas.drawCircle(left + 5f, center, 4f, paint)

        var textRight = panelRight - PADDING
        if (state.notificationCount > 1) {
            val label = if (state.notificationCount > 9) "9+" else state.notificationCount.toString()
            text.set(9f, BACKGROUND, bold = true)
            val badgeWidth = text.measureText(label) + 10f
            paint.color = PRIMARY
            rect.set(textRight - badgeWidth, center - 7f, textRight, center + 7f)
            canvas.drawRoundRect(rect, 7f, 7f, paint)
            canvas.drawText(label, textRight - badgeWidth + 5f, center + 3.2f, text)
            textRight -= badgeWidth + 4f
        }
        drawTwoLines(canvas, title, state.notificationPreview, left + 15f, textRight, center)
    }

    private fun drawMediaCard(canvas: Canvas, state: CockpitFrameState, top: Float, bottom: Float) {
        drawPanel(canvas, top, bottom)
        val title = state.mediaTitle
        if (title == null) {
            drawCentered(canvas, state.mediaEmptyText, top, bottom)
            return
        }
        val center = (top + bottom) / 2
        val left = panelLeft + PADDING
        val cx = left + 11f
        paint.color = PRIMARY
        canvas.drawCircle(cx, center, 11f, paint)
        paint.color = BACKGROUND
        if (state.mediaPlaying) {
            canvas.drawRect(cx - 4.5f, center - 5f, cx - 1.5f, center + 5f, paint)
            canvas.drawRect(cx + 1.5f, center - 5f, cx + 4.5f, center + 5f, paint)
        } else {
            path.rewind()
            path.moveTo(cx - 3.5f, center - 6f)
            path.lineTo(cx + 5.5f, center)
            path.lineTo(cx - 3.5f, center + 6f)
            path.close()
            canvas.drawPath(path, paint)
        }
        drawTwoLines(canvas, title, state.mediaArtist, left + 28f, panelRight - PADDING, center)
    }

    private fun drawTwoLines(
        canvas: Canvas,
        title: String,
        subtitle: String?,
        left: Float,
        right: Float,
        center: Float,
    ) {
        val maxWidth = right - left
        text.set(12f, TEXT, bold = true)
        if (subtitle == null) {
            canvas.drawText(ellipsize(title, maxWidth), left, center + 4f, text)
            return
        }
        canvas.drawText(ellipsize(title, maxWidth), left, center - 2f, text)
        text.set(10f, TEXT_SECONDARY)
        canvas.drawText(ellipsize(subtitle, maxWidth), left, center + 11f, text)
    }

    private fun drawCentered(canvas: Canvas, message: String, top: Float, bottom: Float) {
        text.set(10f, TEXT_SECONDARY)
        val shown = ellipsize(message, panelRight - panelLeft - 2 * PADDING)
        val x = (panelLeft + panelRight) / 2 - text.measureText(shown) / 2
        canvas.drawText(shown, x, (top + bottom) / 2 + 3.5f, text)
    }

    /** Manevra oku: aşağıdan gelen gövde ve manevra yönüne dönen uç. */
    private fun drawManeuver(canvas: Canvas, maneuver: String, left: Float, top: Float, size: Float) {
        paint.color = ACCENT
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = size * 0.13f
        paint.strokeCap = Paint.Cap.ROUND
        paint.strokeJoin = Paint.Join.ROUND
        val cx = left + size / 2
        val bottom = top + size * 0.92f
        val mid = top + size * 0.55f
        path.rewind()

        when (maneuver) {
            "arrive" -> {
                // Bayrak.
                path.moveTo(left + size * 0.3f, bottom)
                path.lineTo(left + size * 0.3f, top + size * 0.12f)
                path.lineTo(left + size * 0.8f, top + size * 0.3f)
                path.lineTo(left + size * 0.3f, top + size * 0.5f)
            }
            "roundabout" -> {
                canvas.drawCircle(cx, mid, size * 0.2f, paint)
                path.moveTo(cx, bottom)
                path.lineTo(cx, mid + size * 0.2f)
                path.moveTo(cx + size * 0.2f, mid)
                path.lineTo(left + size * 0.9f, mid)
                arrowHead(left + size * 0.9f, mid, 0f, size)
            }
            "uTurn" -> {
                val x1 = left + size * 0.68f
                val x0 = left + size * 0.3f
                path.moveTo(x1, bottom)
                path.lineTo(x1, top + size * 0.4f)
                rect.set(x0, top + size * 0.18f, x1, top + size * 0.62f)
                path.arcTo(rect, 0f, -180f)
                path.lineTo(x0, top + size * 0.72f)
                arrowHead(x0, top + size * 0.72f, 90f, size)
            }
            else -> {
                // Açı: 0 = yukarı, pozitif = sağ.
                val angle = when (maneuver) {
                    "slightLeft" -> -45f
                    "left" -> -90f
                    "sharpLeft" -> -135f
                    "slightRight" -> 45f
                    "right" -> 90f
                    "sharpRight" -> 135f
                    else -> 0f
                }
                path.moveTo(cx, bottom)
                if (angle == 0f) {
                    val tipY = top + size * 0.12f
                    path.lineTo(cx, tipY)
                    arrowHead(cx, tipY, -90f, size)
                } else {
                    path.lineTo(cx, mid)
                    val radians = Math.toRadians((angle - 90f).toDouble())
                    val reach = size * 0.36f
                    val tipX = cx + (Math.cos(radians) * reach).toFloat()
                    val tipY = mid + (Math.sin(radians) * reach).toFloat()
                    path.lineTo(tipX, tipY)
                    arrowHead(tipX, tipY, angle - 90f, size)
                }
            }
        }
        canvas.drawPath(path, paint)
        paint.style = Paint.Style.FILL
        paint.strokeCap = Paint.Cap.BUTT
    }

    /** [directionDegrees]: okun baktığı yön (0 = sağ, 90 = aşağı). */
    private fun arrowHead(x: Float, y: Float, directionDegrees: Float, size: Float) {
        val length = size * 0.2f
        for (offset in floatArrayOf(150f, -150f)) {
            val radians = Math.toRadians((directionDegrees + offset).toDouble())
            path.moveTo(x, y)
            path.lineTo(x + (Math.cos(radians) * length).toFloat(), y + (Math.sin(radians) * length).toFloat())
        }
        path.moveTo(x, y)
    }

    private fun ellipsize(value: String, maxWidth: Float): String =
        TextUtils.ellipsize(value, text, maxWidth, TextUtils.TruncateAt.END).toString()

    private fun TextPaint.set(size: Float, color: Int, bold: Boolean = false) {
        textSize = size
        this.color = color
        typeface = if (bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
    }

    companion object {
        const val TOP_BAR = 26f
        const val GAP = 4f
        const val MAP_FRACTION = 0.66f
        private const val PADDING = 8f
        private const val RADIUS = 8f

        val BACKGROUND = Color.rgb(0x08, 0x14, 0x16)
        val SURFACE = Color.rgb(0x10, 0x25, 0x27)
        val PRIMARY = Color.rgb(0x14, 0xB8, 0xA6)
        val ACCENT = Color.rgb(0x2D, 0xD4, 0xBF)
        val TEXT = Color.rgb(0xF0, 0xFA, 0xF9)
        val TEXT_SECONDARY = Color.rgb(0x9B, 0xB5, 0xB3)
        val BORDER = Color.rgb(0x28, 0x43, 0x46)
        val WARNING = Color.rgb(0xF5, 0xB9, 0x42)
        val DANGER = Color.rgb(0xF2, 0x6D, 0x6D)
    }
}
