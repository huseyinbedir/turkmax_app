package com.turkmax.app.diagnostics

import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Bağlantı günlüğü: bellekte son satırları tutar ve (başlatıldıysa) dosyaya da yazar.
 *
 * Saha testinde bilgisayar bağlı olmadığı için bağlantının her adımı burada kayıt altına
 * alınır; uygulama içinden görüntülenir, panoya kopyalanır ve dosyadan sonradan okunabilir.
 * Görüntü verisi ve bildirim içeriği yazılmaz; yalnızca protokol üst verisi.
 */
object SessionLog {
    private const val MAX_LINES = 600
    private val lines = ArrayDeque<String>()
    private val timeFormat = SimpleDateFormat("HH:mm:ss.SSS", Locale.US)
    private var writer: FileWriter? = null

    @Volatile
    var filePath: String? = null
        private set

    /** Günlük dosyasını açar; her uygulama başlangıcında yeni dosya. Hata olursa yalnızca bellek. */
    @Synchronized
    fun init(directory: File?) {
        if (writer != null || directory == null) return
        runCatching {
            directory.mkdirs()
            // Eski günlükler birikmesin: en yeni 10 dosya kalır.
            directory.listFiles { file -> file.name.startsWith("session-") }
                ?.sortedByDescending { it.name }
                ?.drop(9)
                ?.forEach { it.delete() }
            val name = "session-" + SimpleDateFormat("yyyyMMdd-HHmmss", Locale.US).format(Date()) + ".log"
            val file = File(directory, name)
            writer = FileWriter(file, true)
            filePath = file.absolutePath
        }
    }

    @Synchronized
    fun log(tag: String, message: String) {
        val line = "${timeFormat.format(Date())} [$tag] $message"
        lines.addLast(line)
        while (lines.size > MAX_LINES) lines.removeFirst()
        runCatching {
            writer?.apply {
                write(line)
                write("\n")
                flush()
            }
        }
    }

    @Synchronized
    fun snapshot(): List<String> = lines.toList()

    @Synchronized
    fun clear() = lines.clear()

    fun hex(bytes: ByteArray, limit: Int = 24): String {
        val shown = bytes.take(limit).joinToString(" ") { "%02X".format(it) }
        return if (bytes.size > limit) "$shown … (+${bytes.size - limit})" else shown
    }
}
