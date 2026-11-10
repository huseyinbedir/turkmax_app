package com.turkmax.app.navilite

import java.io.IOException

class HandshakeTimeoutException(step: String) : IOException("Handshake timed out waiting for $step")

/**
 * NaviLite el sıkışması (bağımsız implementasyon; adımlar docs/NAVILITE_PROTOCOL.md §4).
 *
 * Gerçek gösterge üzerinde DOĞRULANMADI.
 */
object NaviLiteHandshake {
    const val TIMEOUT_MS = 5_000L
    const val NONCE_SIZE = 4
    private const val XOR_KEY = 0x0A

    class Result(val partNumber: String, val profile: CcuDeviceProfile)

    private val ESN_ACK_PAYLOAD = bytes(0x01, 0x00)
    private val AUTH_REQUEST_PAYLOAD = bytes(0x1C, 0x07, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00)

    /** El sıkışmadan sonra, yanıt beklenmeden gönderilen kurulum çerçeveleri (sırası önemli). */
    val setupFrames: List<NaviLiteFrame> = setupFrames(navStatusActive = false)

    /**
     * [navStatusActive]: NAV_STATUS için `01 00` gönder. Referans kod `00 00` gönderiyor,
     * belgesi `01 00` gözlendiğini söylüyor; hangisinin gerektiği doğrulanmadı.
     */
    fun setupFrames(navStatusActive: Boolean): List<NaviLiteFrame> = listOf(
        value(ServiceType.NAV_STATUS, if (navStatusActive) 0x01 else 0x00, 0x00),
        value(ServiceType.DAY_NIGHT, 0x01, 0x00),
        value(ServiceType.HOME, 0x00, 0x00),
        value(ServiceType.OFFICE, 0x00, 0x00),
        value(ServiceType.GPS, 0x01, 0x00),
        value(ServiceType.APP_SETTING, 0x00, 0x00),
        pointer(ServiceType.ZOOM, 0x07, 0x19, 0x06, 0x00, 0x30, 0x2E, 0x32, 0x20, 0x6D, 0x69),
        pointer(ServiceType.ROAD),
        pointer(ServiceType.SPEED_LIMIT, 0x00, 0x00, 0x00, 0x00, 0x03, 0x6D, 0x70, 0x68),
        value(ServiceType.GPS, 0x01, 0x00),
        value(ServiceType.APP_SETTING, 0x01, 0x00),
    )

    /**
     * Tüm el sıkışma için tek bir süre bütçesi uygular. Süre dolarsa
     * [HandshakeTimeoutException]; bağlantı koparsa [IOException].
     */
    @Throws(IOException::class)
    fun perform(
        session: NaviLiteSession,
        timeoutMs: Long = TIMEOUT_MS,
        navStatusActive: Boolean = false,
    ): Result {
        val deadline = System.nanoTime() + timeoutMs * 1_000_000
        fun remainingMs() = (deadline - System.nanoTime()) / 1_000_000

        session.awaitFrame(remainingMs()) { it.serviceType == ServiceType.ESN_UPDATE }
            ?: throw HandshakeTimeoutException("ESN_UPDATE")
        session.send(NaviLiteFrame(ServiceType.ESN_ACK, PayloadDataType.VALUE.wire, ESN_ACK_PAYLOAD))
        session.send(
            NaviLiteFrame(ServiceType.AUTH_REQUEST, PayloadDataType.POINTER.wire, AUTH_REQUEST_PAYLOAD),
        )

        val secData = session.awaitFrame(remainingMs()) { it.serviceType == ServiceType.SEC_DATA }
            ?: throw HandshakeTimeoutException("SEC_DATA")
        val partNumber = decodePartNumber(secData.payload)
            ?: throw IOException("SEC_DATA payload too short (${secData.payload.size} bytes)")
        session.send(
            NaviLiteFrame(
                ServiceType.SEC_DATA_ACK,
                PayloadDataType.POINTER.wire,
                secDataAckPayload(secData.payload),
            ),
        )
        setupFrames(navStatusActive).forEach(session::send)
        return Result(partNumber, CcuDeviceProfile.fromPartNumber(partNumber))
    }

    /** SEC_DATA: (ASCII parça no ‖ 4 bayt nonce), her bayt XOR 0x0A. Parça numarasını çözer. */
    fun decodePartNumber(secDataPayload: ByteArray): String? {
        if (secDataPayload.size < NONCE_SIZE) return null
        val length = secDataPayload.size - NONCE_SIZE
        return String(ByteArray(length) { xor(secDataPayload[it]) }, Charsets.US_ASCII)
    }

    /** SEC_DATA_ACK payload'ı: SEC_DATA'nın son 4 baytı, her biri XOR 0x0A. */
    fun secDataAckPayload(secDataPayload: ByteArray): ByteArray {
        require(secDataPayload.size >= NONCE_SIZE) { "SEC_DATA payload too short" }
        val start = secDataPayload.size - NONCE_SIZE
        return ByteArray(NONCE_SIZE) { xor(secDataPayload[start + it]) }
    }

    /** Gösterge tarafı (sahte CCU) için: parça no ve nonce'tan SEC_DATA payload'ı üretir. */
    fun encodeSecData(partNumber: String, nonce: ByteArray): ByteArray {
        require(nonce.size == NONCE_SIZE) { "Nonce must be $NONCE_SIZE bytes" }
        val plain = partNumber.toByteArray(Charsets.US_ASCII) + nonce
        return ByteArray(plain.size) { xor(plain[it]) }
    }

    private fun xor(value: Byte): Byte = (value.toInt() xor XOR_KEY).toByte()

    private fun bytes(vararg values: Int) = ByteArray(values.size) { values[it].toByte() }

    private fun value(serviceType: Int, vararg payload: Int) =
        NaviLiteFrame(serviceType, PayloadDataType.VALUE.wire, bytes(*payload))

    private fun pointer(serviceType: Int, vararg payload: Int) =
        NaviLiteFrame(serviceType, PayloadDataType.POINTER.wire, bytes(*payload))
}
