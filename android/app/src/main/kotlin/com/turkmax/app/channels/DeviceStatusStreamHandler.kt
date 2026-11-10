package com.turkmax.app.channels

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import io.flutter.plugin.common.EventChannel

/** Telefon pil/şarj durumunu `ACTION_BATTERY_CHANGED` üzerinden yayınlar. */
class DeviceStatusStreamHandler(private val context: Context) : EventChannel.StreamHandler {
    private var receiver: BroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        onCancel(null)
        val newReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                events.success(toMap(intent))
            }
        }
        receiver = newReceiver
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        // Yapışkan yayın: kayıt anında son değer alıcıya da teslim edilir.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(newReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(newReceiver, filter)
        }
    }

    override fun onCancel(arguments: Any?) {
        receiver?.let { runCatching { context.unregisterReceiver(it) } }
        receiver = null
    }

    private fun toMap(intent: Intent): Map<String, Any?> {
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        return mapOf(
            "batteryPercent" to if (level >= 0 && scale > 0) level * 100 / scale else null,
            "isCharging" to (
                status == BatteryManager.BATTERY_STATUS_CHARGING ||
                    status == BatteryManager.BATTERY_STATUS_FULL
                ),
        )
    }
}
