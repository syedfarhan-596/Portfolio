package com.farhan.paisatrack.sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import com.farhan.paisatrack.PaisaApp
import com.farhan.paisatrack.data.Txn
import com.farhan.paisatrack.data.TxnSource
import com.farhan.paisatrack.data.TxnStatus
import com.farhan.paisatrack.util.Notifications
import com.farhan.paisatrack.util.Prefs
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val prefs = Prefs(context)
        if (!prefs.smsCaptureEnabled) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
        val body = messages.joinToString("") { it.messageBody ?: "" }
        if (body.isBlank()) return

        val parsed = SmsParser.parse(body) ?: return
        val app = context.applicationContext as PaisaApp
        val repo = app.repository
        val defaultAccount = prefs.defaultUpiAccountId

        val pending = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                if (parsed.ref != null && repo.refExists(parsed.ref)) return@launch
                val accounts = repo.accountDao.activeOnce()
                val accountId = SmsParser.matchAccountId(accounts, parsed, defaultAccount)
                    ?: repo.accountDao.firstActiveId() ?: 0L
                val txn = Txn(
                    type = parsed.type,
                    amount = parsed.amount,
                    accountId = accountId,
                    note = "",
                    merchant = parsed.merchant,
                    dateTime = System.currentTimeMillis(),
                    source = TxnSource.SMS,
                    status = TxnStatus.PENDING,
                    upiRef = parsed.ref,
                    rawSms = body
                )
                repo.upsertTxn(txn)
                Notifications.showPendingTxn(context, parsed.amount, parsed.type, parsed.merchant)
            } finally {
                pending.finish()
            }
        }
    }
}
