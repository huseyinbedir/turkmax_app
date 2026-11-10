package com.turkmax.app.channels

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.provider.Settings
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class SystemMethodHandler(
    private val context: Context,
    private val activityProvider: () -> Activity?,
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformInfo" -> result.success(
                mapOf(
                    "osVersion" to (Build.VERSION.RELEASE ?: "?"),
                    "sdkInt" to Build.VERSION.SDK_INT,
                    "deviceModel" to "${Build.MANUFACTURER} ${Build.MODEL}",
                ),
            )
            "getMapsConfig" -> result.success(
                mapOf(
                    "apiKey" to mapsApiKey(),
                    "packageName" to context.packageName,
                    "certSha1" to signingCertSha1(),
                ),
            )
            "isIgnoringBatteryOptimizations" -> result.success(
                Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                    context.getSystemService(PowerManager::class.java)
                        ?.isIgnoringBatteryOptimizations(context.packageName) == true,
            )
            // Yalnızca sistem ayar sayfasını açar; seçimi kullanıcı yapar.
            "openBatterySettings" -> {
                val opened = runCatching {
                    context.startActivity(
                        Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                }.isSuccess
                result.success(opened)
            }
            else -> result.notImplemented()
        }
    }

    /** Manifestteki Maps anahtarı; yapılandırılmamışsa `null`. */
    private fun mapsApiKey(): String? = runCatching {
        val info = context.packageManager.getApplicationInfo(
            context.packageName,
            PackageManager.GET_META_DATA,
        )
        info.metaData?.getString(MAPS_KEY_META)
            ?.takeIf { it.isNotBlank() && it != PLACEHOLDER_KEY }
    }.getOrNull()

    /** Android kısıtlı anahtarla REST çağrısı için imza sertifikasının SHA-1 özeti. */
    @Suppress("DEPRECATION")
    private fun signingCertSha1(): String? = runCatching {
        val packageManager = context.packageManager
        val signature = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val signingInfo = packageManager
                .getPackageInfo(context.packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                .signingInfo ?: return@runCatching null
            (if (signingInfo.hasMultipleSigners()) signingInfo.apkContentsSigners
            else signingInfo.signingCertificateHistory).firstOrNull()
        } else {
            packageManager
                .getPackageInfo(context.packageName, PackageManager.GET_SIGNATURES)
                .signatures?.firstOrNull()
        } ?: return@runCatching null
        MessageDigest.getInstance("SHA-1").digest(signature.toByteArray())
            .joinToString("") { "%02X".format(it) }
    }.getOrNull()

    private companion object {
        const val MAPS_KEY_META = "com.google.android.geo.API_KEY"
        const val PLACEHOLDER_KEY = "DEFAULT_API_KEY"
    }
}
