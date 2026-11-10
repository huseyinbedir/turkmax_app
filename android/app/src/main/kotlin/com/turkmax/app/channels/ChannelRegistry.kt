package com.turkmax.app.channels

import android.app.Activity
import android.content.Context
import com.turkmax.app.bluetooth.ConnectionRuntime
import com.turkmax.app.diagnostics.SessionLog
import com.turkmax.app.streaming.JpegFrameEncoder
import com.turkmax.app.streaming.SyntheticFrameSource
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/** Tüm platform kanallarını tek yerden kurar ve kapatır. */
class ChannelRegistry(
    private val context: Context,
    private val messenger: BinaryMessenger,
    private val activityProvider: () -> Activity?,
) {
    private val worker: ExecutorService = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "turkmax-native-worker").apply { isDaemon = true }
    }
    private val connectionManager = ConnectionRuntime.manager
    private val deviceStatus = DeviceStatusStreamHandler(context)
    private val connectionEvents = ConnectionStreamHandler(connectionManager)

    fun register() {
        SessionLog.init(context.getExternalFilesDir("logs"))
        ConnectionRuntime.appContext = context.applicationContext
        MethodChannel(messenger, ChannelNames.SYSTEM)
            .setMethodCallHandler(SystemMethodHandler(context, activityProvider))
        EventChannel(messenger, ChannelNames.DEVICE_STATUS_EVENTS)
            .setStreamHandler(deviceStatus)
        MethodChannel(messenger, ChannelNames.CONNECTION)
            .setMethodCallHandler(ConnectionMethodHandler(context, connectionManager, worker))
        EventChannel(messenger, ChannelNames.CONNECTION_EVENTS)
            .setStreamHandler(connectionEvents)
        MethodChannel(messenger, ChannelNames.STREAMING).setMethodCallHandler(
            StreamingMethodHandler(SyntheticFrameSource(), JpegFrameEncoder(), worker),
        )
    }

    fun dispose() {
        deviceStatus.onCancel(null)
        connectionEvents.onCancel(null)
        MethodChannel(messenger, ChannelNames.SYSTEM).setMethodCallHandler(null)
        MethodChannel(messenger, ChannelNames.CONNECTION).setMethodCallHandler(null)
        MethodChannel(messenger, ChannelNames.STREAMING).setMethodCallHandler(null)
        EventChannel(messenger, ChannelNames.DEVICE_STATUS_EVENTS).setStreamHandler(null)
        EventChannel(messenger, ChannelNames.CONNECTION_EVENTS).setStreamHandler(null)
        worker.shutdown()
    }
}
