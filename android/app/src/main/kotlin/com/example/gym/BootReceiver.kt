package com.example.gym

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Alarms are forgotten when the phone restarts or the clock changes, so set them again. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            AlarmScheduler.scheduleAll(context)
        } catch (e: Exception) {
            // Ignore: the app will set them again the next time it opens.
        }
    }
}
