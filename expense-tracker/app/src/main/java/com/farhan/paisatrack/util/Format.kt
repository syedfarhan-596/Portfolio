package com.farhan.paisatrack.util

import java.text.NumberFormat
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

object Format {
    private val inr: NumberFormat = NumberFormat.getCurrencyInstance(Locale("en", "IN"))
    private val dateFmt = DateTimeFormatter.ofPattern("dd MMM yyyy")
    private val dateTimeFmt = DateTimeFormatter.ofPattern("dd MMM yyyy, hh:mm a")
    private val timeFmt = DateTimeFormatter.ofPattern("hh:mm a")
    private val monthFmt = DateTimeFormatter.ofPattern("MMM yyyy")
    private val dayFmt = DateTimeFormatter.ofPattern("EEE, dd MMM")

    fun money(amount: Double): String = inr.format(amount)

    fun moneyShort(amount: Double): String {
        val a = kotlin.math.abs(amount)
        val sign = if (amount < 0) "-" else ""
        return when {
            a >= 10_000_000 -> "$sign₹%.2fCr".format(a / 10_000_000)
            a >= 100_000 -> "$sign₹%.2fL".format(a / 100_000)
            a >= 1_000 -> "$sign₹%.1fK".format(a / 1_000)
            else -> "$sign₹%.0f".format(a)
        }
    }

    private fun ldt(millis: Long) =
        Instant.ofEpochMilli(millis).atZone(ZoneId.systemDefault()).toLocalDateTime()

    fun date(millis: Long): String = ldt(millis).format(dateFmt)
    fun dateTime(millis: Long): String = ldt(millis).format(dateTimeFmt)
    fun time(millis: Long): String = ldt(millis).format(timeFmt)
    fun month(millis: Long): String = ldt(millis).format(monthFmt)
    fun day(millis: Long): String = ldt(millis).format(dayFmt)

    fun monthKey(millis: Long): String {
        val d = ldt(millis)
        return "%04d-%02d".format(d.year, d.monthValue)
    }
}
