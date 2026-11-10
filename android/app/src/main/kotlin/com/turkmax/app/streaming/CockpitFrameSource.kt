package com.turkmax.app.streaming

import android.graphics.Bitmap

/**
 * Kritik soyutlama 2/3: TFT'ye gönderilecek en güncel cockpit görüntüsünü sağlar.
 *
 * Kaynak, karenin nasıl kodlanacağını veya nereye gönderileceğini bilmez; bağlantı motoru da
 * karenin nasıl üretildiğini bilmez. Haritalı gerçek cockpit için bkz.
 * [OffscreenCockpitFrameSource].
 */
interface CockpitFrameSource {
    val id: String

    /** Henüz kare yoksa `null`. Dönen bitmap çağıran tarafından değiştirilmemelidir. */
    fun latestFrame(): Bitmap?
}
