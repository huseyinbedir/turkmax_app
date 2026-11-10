package com.turkmax.app.streaming

import android.app.Presentation
import android.content.Context
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.GoogleMapOptions
import com.google.android.libraries.navigation.NavigationView
import com.turkmax.app.diagnostics.SessionLog
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/**
 * Navigasyon haritasını telefon ekranı yerine görünmez bir sanal ekrana çizer ve kareleri
 * oradan okur. Böylece uygulama arka plandayken (ve ekran kapalıyken) de harita güncellenir.
 *
 * Yöntem, Navigation SDK'nın Android Auto için kullandığı düzenle aynıdır: sanal ekran +
 * `Presentation` + `NavigationView`. Navigasyon oturumu süreç genelinde paylaşıldığı için bu
 * görünüm, Flutter tarafında başlatılan rota ve konum takibini kendiliğinden gösterir.
 */
class OffscreenMapRenderer(private val context: Context) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val readerThread = HandlerThread("turkmax-offscreen-map").apply { start() }
    private val frameCount = AtomicInteger()
    private val lock = Any()

    private var imageReader: ImageReader? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var presentation: Presentation? = null
    private var navigationView: NavigationView? = null
    private var latest: Bitmap? = null

    val framesRendered: Int get() = frameCount.get()

    @Volatile
    var isRunning = false
        private set

    /** Sanal ekranı kurar. Herhangi bir thread'den çağrılabilir; kurulum ana thread'de yapılır. */
    fun start(width: Int, height: Int, densityDpi: Int, darkMap: Boolean = true) {
        if (isRunning) return
        val done = CountDownLatch(1)
        var failure: Throwable? = null
        mainHandler.post {
            try {
                startOnMain(width, height, densityDpi, darkMap)
            } catch (e: Throwable) {
                failure = e
                stopOnMain()
            } finally {
                done.countDown()
            }
        }
        check(done.await(5, TimeUnit.SECONDS)) { "Offscreen map start timed out" }
        failure?.let { throw IllegalStateException("Offscreen map failed: $it", it) }
    }

    private fun startOnMain(width: Int, height: Int, densityDpi: Int, darkMap: Boolean) {
        val reader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        reader.setOnImageAvailableListener({ onImageAvailable(it) }, Handler(readerThread.looper))
        imageReader = reader

        val display = context.getSystemService(DisplayManager::class.java).createVirtualDisplay(
            "turkmax-cockpit-map",
            width,
            height,
            densityDpi,
            reader.surface,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_OWN_CONTENT_ONLY,
        ) ?: error("createVirtualDisplay returned null")
        virtualDisplay = display

        val view = NavigationView(
            context,
            GoogleMapOptions().compassEnabled(false).mapToolbarEnabled(false).zoomControlsEnabled(false),
        )
        navigationView = view
        view.setForceNightMode(
            if (darkMap) com.google.android.libraries.navigation.ForceNightMode.FORCE_NIGHT
            else com.google.android.libraries.navigation.ForceNightMode.FORCE_DAY,
        )
        view.onCreate(null)
        view.onStart()
        view.onResume()
        // Dönüş bilgisi sağ panelde çizildiği için SDK'nın bilgi şeritleri kapalı; Google
        // logosu ve atıf öğelerine dokunulmaz.
        view.isNavigationUiEnabled = true
        view.setHeaderEnabled(false)
        view.setRecenterButtonEnabled(false)
        view.setEtaCardEnabled(false)
        view.setSpeedometerEnabled(false)
        view.setTripProgressBarEnabled(false)
        view.setReportIncidentButtonEnabled(false)

        val dialog = Presentation(context, display.display)
        dialog.setContentView(view)
        dialog.show()
        presentation = dialog

        view.getMapAsync { map: GoogleMap ->
            runCatching {
                map.uiSettings.isMyLocationButtonEnabled = false
                map.uiSettings.isIndoorLevelPickerEnabled = false
                @Suppress("MissingPermission")
                map.isMyLocationEnabled = true
                map.followMyLocation(GoogleMap.CameraPerspective.TILTED)
            }.onFailure { SessionLog.log("OFFSCREEN", "map setup failed: $it") }
        }
        isRunning = true
        SessionLog.log("OFFSCREEN", "virtual display started ${width}x$height @${densityDpi}dpi")
    }

    /** Harita modu değiştiğinde sanal ekranı yeniden kurar. */
    fun restart(width: Int, height: Int, densityDpi: Int, darkMap: Boolean) {
        val done = CountDownLatch(1)
        mainHandler.post {
            stopOnMain()
            done.countDown()
        }
        done.await(3, TimeUnit.SECONDS)
        start(width, height, densityDpi, darkMap)
    }

    fun stop() {
        if (!isRunning && virtualDisplay == null) return
        mainHandler.post { stopOnMain() }
    }

    private fun stopOnMain() {
        isRunning = false
        runCatching {
            navigationView?.apply {
                onPause()
                onStop()
                onDestroy()
            }
        }
        navigationView = null
        runCatching { presentation?.dismiss() }
        presentation = null
        runCatching { virtualDisplay?.release() }
        virtualDisplay = null
        runCatching { imageReader?.close() }
        imageReader = null
        SessionLog.log("OFFSCREEN", "virtual display stopped after ${frameCount.get()} frames")
    }

    /**
     * En son çizilen harita karesini [target] üzerine kopyalar. Henüz kare yoksa `false`.
     * [target] harita ile aynı boyutta olmalıdır.
     */
    fun copyLatestInto(target: Bitmap): Boolean = synchronized(lock) {
        val source = latest ?: return false
        if (source.width != target.width || source.height != target.height) return false
        android.graphics.Canvas(target).drawBitmap(source, 0f, 0f, null)
        true
    }

    private fun onImageAvailable(reader: ImageReader) {
        val image = runCatching { reader.acquireLatestImage() }.getOrNull() ?: return
        try {
            val plane = image.planes[0]
            val rowPixels = plane.rowStride / plane.pixelStride
            synchronized(lock) {
                // Satır dolgusu olabilir; önce dolgulu genişlikte okunur, sonra kırpılır.
                val padded = Bitmap.createBitmap(rowPixels, image.height, Bitmap.Config.ARGB_8888)
                padded.copyPixelsFromBuffer(plane.buffer)
                val frame = if (rowPixels == image.width) {
                    padded
                } else {
                    Bitmap.createBitmap(padded, 0, 0, image.width, image.height).also { padded.recycle() }
                }
                latest?.recycle()
                latest = frame
            }
            frameCount.incrementAndGet()
        } catch (e: RuntimeException) {
            SessionLog.log("OFFSCREEN", "frame read failed: $e")
        } finally {
            image.close()
        }
    }
}
