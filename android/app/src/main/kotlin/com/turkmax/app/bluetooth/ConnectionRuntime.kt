package com.turkmax.app.bluetooth

import android.content.Context
import com.turkmax.app.navilite.FakeCcu
import com.turkmax.app.streaming.CockpitFrameState
import com.turkmax.app.streaming.JpegFrameEncoder
import com.turkmax.app.streaming.OffscreenCockpitFrameSource
import com.turkmax.app.streaming.OffscreenMapRenderer
import com.turkmax.app.streaming.SyntheticFrameSource

/**
 * Süreç ömrü boyunca yaşayan bağlantı durumu. Activity kapansa da ön plan servisi sürerken
 * bağlantı ve akış devam edebilsin diye Flutter motoruna değil sürece bağlıdır.
 */
object ConnectionRuntime {
    private val encoder = JpegFrameEncoder()

    @Volatile
    var appContext: Context? = null

    /** Sanal ekrandaki harita; ilk kullanımda kurulur. */
    @Volatile
    var offscreenMap: OffscreenMapRenderer? = null

    /** Flutter'ın en son bildirdiği cockpit içeriği. */
    @Volatile
    var cockpitState: CockpitFrameState = CockpitFrameState()

    val manager: BluetoothConnectionManager by lazy {
        BluetoothConnectionManager(
            frameSourceFactory = { profile, options ->
                if (options.source == StreamOptions.SOURCE_COCKPIT) {
                    val context = appContext ?: error("App context not set")
                    OffscreenCockpitFrameSource(
                        context = context,
                        profile = profile,
                        renderer = offscreenMap ?: OffscreenMapRenderer(context).also { offscreenMap = it },
                        encoder = encoder,
                        state = { cockpitState },
                    )::nextJpeg
                } else {
                    val source = SyntheticFrameSource(profile)
                    val provider: (Int) -> ByteArray? = { quality ->
                        encoder.encode(source.latestFrame(), quality)
                    }
                    provider
                }
            },
        )
    }

    /** Sahte gösterge bağlantısı etkinse, alınan kareleri göstermek için. */
    @Volatile
    var fakeCcu: FakeCcu? = null
}
