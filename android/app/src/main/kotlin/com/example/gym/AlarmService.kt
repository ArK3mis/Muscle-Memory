package com.example.gym

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import java.io.File

/** Plays the reminder sound (looping) with a notification that has a Stop button. */
class AlarmService : Service() {
    companion object {
        const val ACTION_START = "com.example.gym.ALARM_START"
        const val ACTION_STOP = "com.example.gym.ALARM_STOP"
        const val CHANNEL_ID = "mm_alarm_channel"
        const val NOTIF_ID = 4242

        fun stop(ctx: Context) {
            ctx.stopService(Intent(ctx, AlarmService::class.java))
        }
    }

    private var player: MediaPlayer? = null
    private var wake: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())
    private val autoStop = Runnable { stopSelf() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        val label = intent?.getStringExtra(AlarmScheduler.EXTRA_LABEL) ?: "Time to train"
        showNotification(label)
        startSound()
        return START_NOT_STICKY
    }

    private fun showNotification(label: String) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                CHANNEL_ID, "Workout reminders", NotificationManager.IMPORTANCE_HIGH
            )
            ch.setSound(null, null)
            ch.enableVibration(false)
            nm.createNotificationChannel(ch)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), flags)
        val stopIntent = Intent(this, AlarmService::class.java).apply { action = ACTION_STOP }
        val stop = PendingIntent.getService(this, 1, stopIntent, flags)

        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION") Notification.Builder(this)
        }
        b.setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Muscle Memory")
            .setContentText(label)
            .setContentIntent(open)
            .setCategory(Notification.CATEGORY_ALARM)
            .setOngoing(true)
            .addAction(Notification.Action.Builder(null, "STOP", stop).build())
        val n = b.build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIF_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIF_ID, n)
        }
    }

    private fun startSound() {
        val cfg = AlarmScheduler.loadConfig(this)
        val ringSeconds = cfg.optInt("ringSeconds", 60).coerceIn(5, 600)
        val vibrate = cfg.optBoolean("vibrate", true)
        val soundPath = cfg.optString("sound", "")

        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wake = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "musclememory:alarm")
        wake?.acquire((ringSeconds + 10) * 1000L)

        releasePlayer()
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()

        var started = false
        if (soundPath.isNotEmpty() && File(soundPath).exists()) {
            started = tryPlay(attrs) { it.setDataSource(soundPath) }
        }
        if (!started) {
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            if (uri != null) {
                started = tryPlay(attrs) { it.setDataSource(this, uri) }
            }
        }

        if (vibrate) {
            @Suppress("DEPRECATION")
            val v = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            val pattern = longArrayOf(0, 600, 500)
            if (v != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    v.vibrate(VibrationEffect.createWaveform(pattern, 0))
                } else {
                    @Suppress("DEPRECATION") v.vibrate(pattern, 0)
                }
            }
        }

        handler.removeCallbacks(autoStop)
        handler.postDelayed(autoStop, ringSeconds * 1000L)
    }

    private fun tryPlay(attrs: AudioAttributes, source: (MediaPlayer) -> Unit): Boolean {
        return try {
            val mp = MediaPlayer()
            mp.setAudioAttributes(attrs)
            source(mp)
            mp.isLooping = true
            mp.prepare()
            mp.start()
            player = mp
            true
        } catch (e: Exception) {
            releasePlayer()
            false
        }
    }

    private fun releasePlayer() {
        try { player?.stop() } catch (e: Exception) { }
        try { player?.release() } catch (e: Exception) { }
        player = null
    }

    override fun onDestroy() {
        handler.removeCallbacks(autoStop)
        releasePlayer()
        @Suppress("DEPRECATION")
        (getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator)?.cancel()
        try { if (wake?.isHeld == true) wake?.release() } catch (e: Exception) { }
        super.onDestroy()
    }
}
