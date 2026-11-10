package com.turkmax.app.bluetooth

/**
 * Bir bağlantının akış ayarları. Gerçek göstergede doğrulanmamış noktaları sahada
 * deneyebilmek için bazıları kullanıcı tarafından değiştirilebilir.
 */
data class StreamOptions(
    /** Kare kaynağı: [SOURCE_COCKPIT] (haritalı gerçek cockpit) veya [SOURCE_SYNTHETIC]. */
    val source: String = SOURCE_COCKPIT,
    /** Kare yüksekliği; `null` ise göstergenin parça numarasına göre seçilir. */
    val frameHeightOverride: Int? = null,
    val quality: Int = 40,
    val maxFps: Int = 10,
    /** Kurulumda NAV_STATUS `01 00` gönder (varsayılan `00 00`); hangisinin gerektiği doğrulanmadı. */
    val navStatusActive: Boolean = false,
) {
    override fun toString(): String =
        "source=$source height=${frameHeightOverride ?: "auto"} quality=$quality maxFps=$maxFps " +
            "navStatus=${if (navStatusActive) "01" else "00"}"

    companion object {
        const val SOURCE_COCKPIT = "cockpit"
        const val SOURCE_SYNTHETIC = "synthetic"
    }
}
