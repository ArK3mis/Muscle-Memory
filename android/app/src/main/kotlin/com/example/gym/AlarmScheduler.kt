package com.example.gym

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject
import java.util.Calendar

/**
 * Keeps the reminder settings (sent from Flutter as JSON) and sets the phone's
 * alarm clock for the next time of each reminder.
 *
 * Days use the same numbers as Dart: 1 = Monday ... 7 = Sunday.
 */
object AlarmScheduler {
    const val PREFS = "mm_alarms"
    const val KEY_CONFIG = "config"
    const val KEY_IDS = "scheduled_ids"
    const val ACTION_FIRE = "com.example.gym.ALARM_FIRE"
    const val EXTRA_ID = "id"
    const val EXTRA_LABEL = "label"
    const val TEST_ID = 99999

    fun saveConfig(ctx: Context, json: String) {
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY_CONFIG, json).apply()
    }

    fun loadConfig(ctx: Context): JSONObject {
        val raw = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_CONFIG, null) ?: return JSONObject()
        return try { JSONObject(raw) } catch (e: Exception) { JSONObject() }
    }

    /** Next moment (millis) this reminder should ring, or -1 if never. */
    fun nextTrigger(hour: Int, minute: Int, days: List<Int>, nowMs: Long): Long {
        if (days.isEmpty()) return -1
        val cal = Calendar.getInstance()
        for (offset in 0..7) {
            cal.timeInMillis = nowMs
            cal.add(Calendar.DAY_OF_YEAR, offset)
            cal.set(Calendar.HOUR_OF_DAY, hour)
            cal.set(Calendar.MINUTE, minute)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            val dartDay = ((cal.get(Calendar.DAY_OF_WEEK) + 5) % 7) + 1
            if (cal.timeInMillis > nowMs && days.contains(dartDay)) {
                return cal.timeInMillis
            }
        }
        return -1
    }

    private fun pending(ctx: Context, id: Int, label: String): PendingIntent {
        val intent = Intent(ctx, AlarmReceiver::class.java).apply {
            action = ACTION_FIRE
            putExtra(EXTRA_ID, id)
            putExtra(EXTRA_LABEL, label)
        }
        return PendingIntent.getBroadcast(
            ctx, id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun setAt(ctx: Context, id: Int, label: String, whenMs: Long) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = pending(ctx, id, label)
        val show = PendingIntent.getActivity(
            ctx, id,
            Intent(ctx, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        try {
            am.setAlarmClock(AlarmManager.AlarmClockInfo(whenMs, show), pi)
        } catch (e: SecurityException) {
            // Exact alarms not allowed: fall back to a best-effort alarm.
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, whenMs, pi)
        }
    }

    fun cancel(ctx: Context, id: Int) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(pending(ctx, id, ""))
    }

    /** Cancels everything we set before and sets every enabled reminder again. */
    fun scheduleAll(ctx: Context) {
        val prefs = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val old = prefs.getString(KEY_IDS, "") ?: ""
        for (part in old.split(",")) {
            val id = part.trim().toIntOrNull() ?: continue
            cancel(ctx, id)
        }
        val config = loadConfig(ctx)
        val list = config.optJSONArray("reminders")
        val ids = ArrayList<Int>()
        if (list != null) {
            for (i in 0 until list.length()) {
                val r = list.optJSONObject(i) ?: continue
                if (!r.optBoolean("enabled", true)) continue
                scheduleReminder(ctx, r)?.let { ids.add(it) }
            }
        }
        prefs.edit().putString(KEY_IDS, ids.joinToString(",")).apply()
    }

    /** Sets the next ring of one reminder. Returns its id, or null if none. */
    fun scheduleReminder(ctx: Context, r: JSONObject): Int? {
        val id = r.optInt("id", -1)
        if (id < 0) return null
        val daysJson = r.optJSONArray("days")
        val days = ArrayList<Int>()
        if (daysJson != null) {
            for (i in 0 until daysJson.length()) days.add(daysJson.optInt(i))
        }
        val whenMs = nextTrigger(
            r.optInt("hour", 12), r.optInt("minute", 0), days, System.currentTimeMillis()
        )
        if (whenMs < 0) return null
        setAt(ctx, id, r.optString("label", "Time to train"), whenMs)
        return id
    }

    /** Rings once, a few seconds from now, using the saved sound settings. */
    fun scheduleTest(ctx: Context, seconds: Int) {
        val whenMs = System.currentTimeMillis() + seconds * 1000L
        setAt(ctx, TEST_ID, "Test alarm", whenMs)
    }

    fun canExact(ctx: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return am.canScheduleExactAlarms()
    }
}
