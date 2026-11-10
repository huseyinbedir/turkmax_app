package com.turkmax.app.channels

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.turkmax.app.bluetooth.BluetoothConnectionManager
import com.turkmax.app.bluetooth.BluetoothRfcommTransport
import com.turkmax.app.bluetooth.ConnectionRuntime
import com.turkmax.app.bluetooth.ConnectionSnapshot
import com.turkmax.app.bluetooth.ConnectionTarget
import com.turkmax.app.bluetooth.PipeTransport
import com.turkmax.app.bluetooth.StreamOptions
import com.turkmax.app.diagnostics.SessionLog
import com.turkmax.app.navilite.CcuDeviceProfile
import com.turkmax.app.navilite.FakeCcu
import com.turkmax.app.service.StreamingForegroundService
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService

class ConnectionMethodHandler(
    private val context: Context,
    private val manager: BluetoothConnectionManager,
    private val worker: ExecutorService,
) : MethodChannel.MethodCallHandler {
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getBondedDevices" -> bondedDevices(result)
            "connect" -> connect(
                address = call.argument<String>("address") ?: return result.error("BAD_ARGS", null, null),
                autoReconnect = call.argument<Boolean>("autoReconnect") ?: true,
                options = StreamOptions(
                    source = call.argument<String>("source") ?: StreamOptions.SOURCE_SYNTHETIC,
                    frameHeightOverride = call.argument<Int>("frameHeight"),
                    quality = call.argument<Int>("quality") ?: 40,
                    maxFps = call.argument<Int>("maxFps") ?: 15,
                    navStatusActive = call.argument<Boolean>("navStatusActive") ?: false,
                ),
                result = result,
            )
            // Bağlantıyı kesmek bekleyen ACK için kısa süre bloklayabilir; ana thread dışında.
            "disconnect" -> worker.execute {
                manager.requestDisconnect()
                ConnectionRuntime.offscreenMap?.stop()
                ConnectionRuntime.offscreenMap = null
                ConnectionRuntime.fakeCcu?.close()
                ConnectionRuntime.fakeCcu = null
                StreamingForegroundService.stop(context)
                mainHandler.post { result.success(null) }
            }
            "startStreaming" -> {
                manager.startStreaming()
                result.success(null)
            }
            "stopStreaming" -> {
                manager.stopStreaming()
                result.success(null)
            }
            "getSessionLog" -> result.success(
                mapOf("lines" to SessionLog.snapshot(), "path" to SessionLog.filePath),
            )
            "getFakeCcuFrame" -> {
                val ccu = ConnectionRuntime.fakeCcu
                result.success(
                    mapOf("jpeg" to ccu?.lastImage, "imagesReceived" to (ccu?.imagesReceived ?: 0)),
                )
            }
            else -> result.notImplemented()
        }
    }

    @SuppressLint("MissingPermission")
    private fun bondedDevices(result: MethodChannel.Result) {
        if (!hasBluetoothPermission()) return result.error(ERROR_PERMISSION, null, null)
        val adapter = adapter() ?: return result.error(ERROR_NO_BLUETOOTH, null, null)
        if (!adapter.isEnabled) return result.error(ERROR_BLUETOOTH_OFF, null, null)
        val devices = adapter.bondedDevices.orEmpty()
            .map { device ->
                mapOf(
                    "name" to (device.name ?: device.address),
                    "address" to device.address,
                    "likelyCcu" to CcuDeviceProfile.looksLikeCcu(device.name),
                )
            }
            .sortedWith(compareByDescending<Map<String, Any>> { it["likelyCcu"] as Boolean }
                .thenBy { it["name"] as String })
        result.success(devices)
    }

    @SuppressLint("MissingPermission")
    private fun connect(
        address: String,
        autoReconnect: Boolean,
        options: StreamOptions,
        result: MethodChannel.Result,
    ) {
        val target = if (address == FAKE_ADDRESS) {
            ConnectionTarget(FAKE_DEVICE_NAME) {
                val (phoneEnd, gaugeEnd) = PipeTransport.createPair()
                ConnectionRuntime.fakeCcu?.close()
                // Gerçek göstergeye benzer bir yanıt gecikmesi.
                ConnectionRuntime.fakeCcu = FakeCcu(gaugeEnd, FakeCcu.Options(ackDelayMs = 60))
                    .also { it.start() }
                phoneEnd
            }
        } else {
            if (!hasBluetoothPermission()) return result.error(ERROR_PERMISSION, null, null)
            val adapter = adapter() ?: return result.error(ERROR_NO_BLUETOOTH, null, null)
            if (!adapter.isEnabled) return result.error(ERROR_BLUETOOTH_OFF, null, null)
            val device = runCatching { adapter.getRemoteDevice(address) }.getOrNull()
                ?: return result.error("BAD_ADDRESS", null, null)
            // Yayın sırasında süreç canlı kalsın; yalnızca gerçek Bluetooth bağlantısında.
            StreamingForegroundService.start(context)
            ConnectionTarget(device.name ?: address) { BluetoothRfcommTransport(device, adapter) }
        }
        worker.execute {
            manager.connect(target, autoReconnect, options)
            mainHandler.post { result.success(null) }
        }
    }

    private fun adapter(): BluetoothAdapter? =
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    private fun hasBluetoothPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
            PackageManager.PERMISSION_GRANTED

    private companion object {
        const val FAKE_ADDRESS = "fake"
        const val FAKE_DEVICE_NAME = "Sahte CCU"
        const val ERROR_PERMISSION = "PERMISSION_DENIED"
        const val ERROR_BLUETOOTH_OFF = "BLUETOOTH_OFF"
        const val ERROR_NO_BLUETOOTH = "NO_BLUETOOTH"
    }
}

class ConnectionStreamHandler(
    private val manager: BluetoothConnectionManager,
) : EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var listener: ((ConnectionSnapshot) -> Unit)? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        onCancel(null)
        val newListener: (ConnectionSnapshot) -> Unit = { snapshot ->
            mainHandler.post { events.success(snapshot.toMap()) }
        }
        listener = newListener
        manager.addListener(newListener)
    }

    override fun onCancel(arguments: Any?) {
        listener?.let(manager::removeListener)
        listener = null
    }
}
