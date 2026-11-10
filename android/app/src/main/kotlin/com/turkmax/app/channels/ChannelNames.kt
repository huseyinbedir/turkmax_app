package com.turkmax.app.channels

/**
 * Flutter ↔ native kanal adları.
 *
 * Dart karşılığı: `lib/core/platform/channel_names.dart`. İki dosya birlikte güncellenmelidir.
 */
object ChannelNames {
    const val SYSTEM = "turkmax/system"
    const val DEVICE_STATUS_EVENTS = "turkmax/device_status/events"
    const val CONNECTION = "turkmax/connection"
    const val CONNECTION_EVENTS = "turkmax/connection/events"
    const val STREAMING = "turkmax/streaming"
}
