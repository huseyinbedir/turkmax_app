package com.turkmax.app.streaming

import android.graphics.Bitmap
import java.io.ByteArrayOutputStream

/** Cockpit karesini TFT'ye gönderilecek baseline JPEG'e kodlar. */
class JpegFrameEncoder {
    private val buffer = ByteArrayOutputStream(32 * 1024)

    @Synchronized
    fun encode(bitmap: Bitmap, quality: Int = DEFAULT_QUALITY): ByteArray {
        buffer.reset()
        val clamped = quality.coerceIn(MIN_QUALITY, MAX_QUALITY)
        check(bitmap.compress(Bitmap.CompressFormat.JPEG, clamped, buffer)) {
            "JPEG encoding failed"
        }
        return buffer.toByteArray()
    }

    companion object {
        const val MIN_QUALITY = 10
        const val MAX_QUALITY = 80
        const val DEFAULT_QUALITY = 40
    }
}
