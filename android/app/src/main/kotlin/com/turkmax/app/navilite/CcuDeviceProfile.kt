package com.turkmax.app.navilite

/**
 * Göstergenin (CCU) el sıkışmada bildirdiği parça numarasına göre seçilen ekran profili.
 * Yanlış çözünürlükte kare gönderildiğinde göstergenin hata verdiği raporlanmıştır.
 */
data class CcuDeviceProfile(val id: String, val width: Int, val height: Int) {
    companion object {
        /** XMAX scooter CCU ailesi. */
        val XMAX = CcuDeviceProfile(id = "xmax", width = 480, height = 234)

        /** Bilinen diğer göstergeler için varsayılan. */
        val DEFAULT = CcuDeviceProfile(id = "default", width = 480, height = 240)

        private const val XMAX_PART_NUMBER_PREFIX = "006-B3952"

        fun fromPartNumber(partNumber: String?): CcuDeviceProfile =
            if (partNumber?.startsWith(XMAX_PART_NUMBER_PREFIX) == true) XMAX else DEFAULT

        /** Eşleşmiş cihaz listesinde olası Yamaha CCU'larını öne çıkarmak için ad sezgisi. */
        fun looksLikeCcu(bluetoothName: String?): Boolean {
            val name = bluetoothName?.uppercase() ?: return false
            return name.startsWith("YCCU") || name.contains("CCU")
        }
    }
}
