package com.farhan.paisatrack.util

import android.content.Context

class Prefs(context: Context) {
    private val sp = context.getSharedPreferences("paisa_prefs", Context.MODE_PRIVATE)

    var reminderEnabled: Boolean
        get() = sp.getBoolean("reminder_enabled", true)
        set(v) = sp.edit().putBoolean("reminder_enabled", v).apply()

    var reminderHour: Int
        get() = sp.getInt("reminder_hour", 23)
        set(v) = sp.edit().putInt("reminder_hour", v).apply()

    var reminderMinute: Int
        get() = sp.getInt("reminder_minute", 0)
        set(v) = sp.edit().putInt("reminder_minute", v).apply()

    var smsCaptureEnabled: Boolean
        get() = sp.getBoolean("sms_capture", true)
        set(v) = sp.edit().putBoolean("sms_capture", v).apply()

    var defaultUpiAccountId: Long
        get() = sp.getLong("default_upi_account", -1L)
        set(v) = sp.edit().putLong("default_upi_account", v).apply()
}
