package com.farhan.paisatrack.util

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.farhan.paisatrack.MainActivity
import com.farhan.paisatrack.R
import com.farhan.paisatrack.data.TxnType

object Notifications {
    const val CHANNEL_REMINDER = "reminder"
    const val CHANNEL_TXN = "txn_alerts"

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_REMINDER,
                context.getString(R.string.reminder_channel_name),
                NotificationManager.IMPORTANCE_HIGH
            ).apply { description = context.getString(R.string.reminder_channel_desc) }
        )
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_TXN,
                context.getString(R.string.txn_channel_name),
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply { description = context.getString(R.string.txn_channel_desc) }
        )
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun canNotify(context: Context): Boolean =
        NotificationManagerCompat.from(context).areNotificationsEnabled()

    fun showReminder(context: Context) {
        if (!canNotify(context)) return
        val n = NotificationCompat.Builder(context, CHANNEL_REMINDER)
            .setSmallIcon(R.drawable.ic_stat_money)
            .setContentTitle("Time to log today's expenses 💸")
            .setContentText("Add what you spent today so your balances stay accurate.")
            .setStyle(NotificationCompat.BigTextStyle().bigText("Add what you spent today — food, friends, cash — so your balances and reports stay accurate."))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(openAppIntent(context))
            .build()
        try {
            NotificationManagerCompat.from(context).notify(1001, n)
        } catch (_: SecurityException) {
        }
    }

    fun showPendingTxn(context: Context, amount: Double, type: TxnType, merchant: String) {
        if (!canNotify(context)) return
        val verb = if (type == TxnType.INCOME) "received" else "spent"
        val who = if (merchant.isNotBlank()) " · $merchant" else ""
        val n = NotificationCompat.Builder(context, CHANNEL_TXN)
            .setSmallIcon(R.drawable.ic_stat_money)
            .setContentTitle("New transaction detected")
            .setContentText("${Format.money(amount)} $verb$who — tap to confirm & categorize")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(openAppIntent(context))
            .build()
        try {
            NotificationManagerCompat.from(context).notify(amount.toInt() + 2000, n)
        } catch (_: SecurityException) {
        }
    }
}
