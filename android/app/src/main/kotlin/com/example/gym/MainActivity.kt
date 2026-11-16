package com.example.gym

import android.Manifest
import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.OpenableColumns
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "muscle_memory/alarms"
    private val pickCode = 7001
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "scheduleAll" -> {
                    val json = call.argument<String>("config") ?: "{}"
                    AlarmScheduler.saveConfig(this, json)
                    AlarmScheduler.scheduleAll(this)
                    result.success(true)
                }
                "testIn" -> {
                    val seconds = call.argument<Int>("seconds") ?: 10
                    val json = call.argument<String>("config")
                    if (json != null) AlarmScheduler.saveConfig(this, json)
                    AlarmScheduler.scheduleTest(this, seconds)
                    result.success(true)
                }
                "stopAlarm" -> {
                    AlarmService.stop(this)
                    result.success(true)
                }
                "status" -> result.success(status())
                "pickAudio" -> pickAudio(result)
                "requestNotifications" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7002)
                    }
                    result.success(true)
                }
                "openExactAlarmSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val i = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                        i.data = Uri.parse("package:$packageName")
                        startActivity(i)
                    }
                    result.success(true)
                }
                "openBatterySettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                    } catch (e: Exception) {
                        openAppSettings()
                    }
                    result.success(true)
                }
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("alarm_error", e.message, null)
        }
    }

    private fun openAppSettings() {
        val i = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        i.data = Uri.parse("package:$packageName")
        startActivity(i)
    }

    private fun status(): Map<String, Any> {
        val notif = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        } else true
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        return mapOf(
            "notifications" to notif,
            "exact" to AlarmScheduler.canExact(this),
            "batteryUnrestricted" to pm.isIgnoringBatteryOptimizations(packageName),
            "sdk" to Build.VERSION.SDK_INT,
        )
    }

    private fun pickAudio(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "Already picking a file", null)
            return
        }
        val i = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*"
        }
        pendingPick = result
        startActivityForResult(i, pickCode)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != pickCode) {
            @Suppress("DEPRECATION")
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingPick
        pendingPick = null
        val uri = data?.data
        if (result == null) return
        if (resultCode != RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            var name = "ringtone"
            contentResolver.query(uri, null, null, null, null)?.use { c ->
                val col = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (col >= 0 && c.moveToFirst()) name = c.getString(col) ?: name
            }
            val ext = name.substringAfterLast('.', "mp3").take(5)
            val out = File(filesDir, "ringtone.$ext")
            filesDir.listFiles()?.forEach {
                if (it.name.startsWith("ringtone.")) it.delete()
            }
            contentResolver.openInputStream(uri)?.use { input ->
                out.outputStream().use { input.copyTo(it) }
            }
            result.success(mapOf("path" to out.absolutePath, "name" to name))
        } catch (e: Exception) {
            result.error("copy_failed", e.message, null)
        }
    }
}
