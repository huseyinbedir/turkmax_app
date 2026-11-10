package com.turkmax.app.navilite

/** Kullanılan NaviLite servis türleri. Kaynak ve doğrulama durumu: docs/NAVILITE_PROTOCOL.md. */
object ServiceType {
    const val IMAGE = 0
    const val NAV_STATUS = 2
    const val ROAD = 3
    const val HOME = 10
    const val OFFICE = 11
    const val APP_SETTING = 12
    const val GPS = 13
    const val ZOOM = 14
    const val SPEED_LIMIT = 17
    const val DAY_NIGHT = 31
    const val AUTH_REQUEST = 33
    /** Gösterge → telefon: içerik (görüntü) göndermeye başla / durdur isteği. */
    const val CONTENT_START = 55
    const val CONTENT_STOP = 56
    const val ESN_UPDATE = 66
    const val IMAGE_ACK = 80
    const val ESN_ACK = 81
    const val AUTH_ACK = 82
    const val SEC_DATA = 83
    const val SEC_DATA_ACK = 84
}

enum class PayloadDataType(val wire: Int) {
    VALUE(0),
    POINTER(1),
}

/** Tek bir NaviLite çerçevesinin mantıksal içeriği. */
class NaviLiteFrame(
    val serviceType: Int,
    val payloadDataType: Int,
    val payload: ByteArray,
    val frameType: Int = NaviLiteCodec.FRAME_TYPE_PHONE,
) {
    override fun equals(other: Any?): Boolean =
        other is NaviLiteFrame &&
            serviceType == other.serviceType &&
            payloadDataType == other.payloadDataType &&
            frameType == other.frameType &&
            payload.contentEquals(other.payload)

    override fun hashCode(): Int =
        31 * (31 * (31 * serviceType + payloadDataType) + frameType) + payload.contentHashCode()

    override fun toString(): String =
        "NaviLiteFrame(service=$serviceType, pdt=$payloadDataType, type=$frameType, size=${payload.size})"
}
