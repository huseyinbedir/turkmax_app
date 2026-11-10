package com.turkmax.app.streaming

/**
 * TFT karesinde gösterilecek, Flutter tarafından hazırlanmış içerik. Metinler Dart'ta
 * biçimlendirilir (tek biçimlendirme kaynağı); native taraf yalnızca çizer. Saat ve pil
 * native tarafta okunur, böylece Flutter arayüzü durmuşken de güncel kalır.
 */
data class CockpitFrameState(
    /** `straight`, `left`, `slightRight` … (Dart `ManeuverType.name`); manevra yoksa `null`. */
    val maneuver: String? = null,
    val maneuverDistance: String? = null,
    val roadName: String? = null,
    /** Kalan mesafe ve varış saati satırı. */
    val routeLine: String? = null,
    /** Manevra yokken gösterilecek metin ("Rota yok", "Rota hesaplanıyor" …). */
    val navigationMessage: String = "",
    val notificationTitle: String? = null,
    val notificationPreview: String? = null,
    val notificationCount: Int = 0,
    val notificationEmptyText: String = "",
    val mediaTitle: String? = null,
    val mediaArtist: String? = null,
    val mediaPlaying: Boolean = false,
    val mediaEmptyText: String = "",
    /** Ekranda demo verisi varsa gösterilecek rozet metni; yoksa `null`. */
    val demoBadge: String? = null,
    val darkMap: Boolean = true,
) {
    companion object {
        fun fromMap(map: Map<*, *>): CockpitFrameState = CockpitFrameState(
            maneuver = map["maneuver"] as? String,
            maneuverDistance = map["maneuverDistance"] as? String,
            roadName = map["roadName"] as? String,
            routeLine = map["routeLine"] as? String,
            navigationMessage = map["navigationMessage"] as? String ?: "",
            notificationTitle = map["notificationTitle"] as? String,
            notificationPreview = map["notificationPreview"] as? String,
            notificationCount = (map["notificationCount"] as? Number)?.toInt() ?: 0,
            notificationEmptyText = map["notificationEmptyText"] as? String ?: "",
            mediaTitle = map["mediaTitle"] as? String,
            mediaArtist = map["mediaArtist"] as? String,
            mediaPlaying = map["mediaPlaying"] as? Boolean ?: false,
            mediaEmptyText = map["mediaEmptyText"] as? String ?: "",
            demoBadge = map["demoBadge"] as? String,
            darkMap = map["darkMap"] as? Boolean ?: true,
        )
    }
}
