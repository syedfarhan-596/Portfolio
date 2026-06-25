package com.farhan.paisatrack.work

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.farhan.paisatrack.util.Notifications

class ReminderWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        Notifications.showReminder(applicationContext)
        // Re-schedule for the next day.
        ReminderScheduler.schedule(applicationContext)
        return Result.success()
    }
}
