package com.farhan.paisatrack.work

import android.content.Context
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.farhan.paisatrack.util.Prefs
import java.time.Duration
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId

object ReminderScheduler {
    private const val WORK_NAME = "daily_expense_reminder"

    fun schedule(context: Context) {
        val prefs = Prefs(context)
        if (!prefs.reminderEnabled) {
            cancel(context)
            return
        }
        val now = LocalDateTime.now()
        val target = LocalTime.of(prefs.reminderHour, prefs.reminderMinute)
        var next = now.toLocalDate().atTime(target)
        if (!next.isAfter(now)) next = next.plusDays(1)

        val delayMillis = Duration.between(
            now.atZone(ZoneId.systemDefault()).toInstant(),
            next.atZone(ZoneId.systemDefault()).toInstant()
        ).toMillis()

        val request = OneTimeWorkRequestBuilder<ReminderWorker>()
            .setInitialDelay(Duration.ofMillis(delayMillis))
            .build()

        WorkManager.getInstance(context).enqueueUniqueWork(
            WORK_NAME,
            ExistingWorkPolicy.REPLACE,
            request
        )
    }

    fun cancel(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
    }
}
