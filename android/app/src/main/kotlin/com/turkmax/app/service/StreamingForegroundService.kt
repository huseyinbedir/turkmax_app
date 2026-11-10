package com.turkmax.app.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import com.turkmax.app.R
import com.turkmax.app.diagnostics.SessionLog

/**
 * Motosiklet bağlantısı sürerken süreci canlı tutan ön plan servisi (`connectedDevice`).
 * Bağlantı mantığı burada değil `ConnectionRuntime` içindedir; servis yalnızca Android'e
 * "kullanıcının bildiği, süren bir iş var" bilgisini verir.
 *
 * Arka planda / ekran kapalıyken gerçek motosikletle davranışı DOĞRULANMADI.
 */
class StreamingForegroundService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopForegroundCompat()
            stopSelf()
            return START_NOT_STICKY
        }
        try {
            val notification = buildNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            acquireWakeLock()
        } catch (e: RuntimeException) {
            // İzin eksikliği veya arka plandan başlatma kısıtı: servis olmadan devam edilir.
            SessionLog.log("SERVICE", "foreground start failed: $e")
            stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        wakeLock?.takeIf { it.isHeld }?.release()
        wakeLock = null
        super.onDestroy()
    }

    /** Ekran kapansa da Bluetooth akışı sürsün diye CPU'yu uyanık tutar (süre sınırlı). */
    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        wakeLock = getSystemService(PowerManager::class.java)
            ?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "turkmax:connection")
            ?.apply { acquire(WAKE_LOCK_TIMEOUT_MS) }
    }

    private fun buildNotification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    getString(R.string.connection_channel_name),
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setContentTitle(getString(R.string.connection_notification_title))
            .setContentText(getString(R.string.connection_notification_text))
            .setSmallIcon(R.drawable.ic_stat_turkmax)
            .setOngoing(true)
            .build()
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    companion object {
        private const val CHANNEL_ID = "turkmax.connection"
        private const val NOTIFICATION_ID = 1001
        private const val WAKE_LOCK_TIMEOUT_MS = 3 * 60 * 60 * 1000L
        private const val ACTION_STOP = "com.turkmax.app.action.STOP_CONNECTION_SERVICE"

        fun start(context: Context) {
            val intent = Intent(context, StreamingForegroundService::class.java)
            runCatching {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            }
        }

        fun stop(context: Context) {
            runCatching {
                context.stopService(Intent(context, StreamingForegroundService::class.java))
            }
        }
    }
}
