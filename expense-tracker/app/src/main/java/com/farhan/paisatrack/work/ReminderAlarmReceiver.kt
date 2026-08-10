package com.farhan.paisatrack.work

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.farhan.paisatrack.util.Notifications

class ReminderAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Notifications.showReminder(context)
        // Re-schedule for the next day.
        ReminderScheduler.schedule(context)
    }
}
