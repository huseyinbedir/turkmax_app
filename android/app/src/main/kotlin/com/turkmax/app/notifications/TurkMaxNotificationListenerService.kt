package com.turkmax.app.notifications

import android.service.notification.NotificationListenerService

/**
 * Kullanıcı izin verdiğinde bildirim özetlerini okuyacak servis.
 *
 * DURUM: iskelet; henüz uygulanmadı ve manifestte `enabled="false"` olarak tanımlıdır.
 * Bildirim içeriği kalıcı saklanmayacak ve cihaz dışına gönderilmeyecek.
 */
class TurkMaxNotificationListenerService : NotificationListenerService()
