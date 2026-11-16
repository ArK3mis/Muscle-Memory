package com.example.gym

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/** Runs when an alarm time arrives: sets the next ring, then starts the sound. */
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(AlarmScheduler.EXTRA_ID, -1)
        val label = intent.getStringExtra(AlarmScheduler.EXTRA_LABEL) ?: "Time to train"

        // Repeating reminders: set up the next one right away.
        if (id >= 0 && id != AlarmScheduler.TEST_ID) {
            try {
                val list = AlarmScheduler.loadConfig(context).optJSONArray("reminders")
                if (list != null) {
                    for (i in 0 until list.length()) {
                        val r = list.optJSONObject(i) ?: continue
                        if (r.optInt("id", -1) == id && r.optBoolean("enabled", true)) {
                            AlarmScheduler.scheduleReminder(context, r)
                        }
                    }
                }
            } catch (e: Exception) {
                // Keep going: the sound matters more than the next schedule.
            }
        }

        val svc = Intent(context, AlarmService::class.java).apply {
            action = AlarmService.ACTION_START
            putExtra(AlarmScheduler.EXTRA_LABEL, label)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(svc)
            } else {
                context.startService(svc)
            }
        } catch (e: Exception) {
            // The phone refused to start the service; nothing else we can do here.
        }
    }
}
