package com.farhan.paisatrack.sms

import com.farhan.paisatrack.data.TxnType

/** Result of parsing a bank / UPI alert SMS. */
data class ParsedSms(
    val amount: Double,
    val type: TxnType,       // EXPENSE (debit) or INCOME (credit)
    val merchant: String,
    val ref: String?,
    val bankHint: String?
)

object SmsParser {

    private val debitWords = listOf(
        "debited", "debit", "spent", "paid", "sent", "withdrawn",
        "purchase", "deducted", "txn of", "payment of"
    )
    private val creditWords = listOf(
        "credited", "credit", "received", "deposited", "added", "refund"
    )

    // ₹ / Rs / INR followed by an amount like 1,234.56
    private val amountRegex = Regex(
        """(?:rs\.?|inr|₹)\s*([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)""",
        RegexOption.IGNORE_CASE
    )
    private val refRegex = Regex(
        """(?:ref(?:erence)?(?:\s*no)?|upi(?:\s*ref)?|txn(?:\s*id)?|utr)[:\s#]*([a-z0-9]{6,})""",
        RegexOption.IGNORE_CASE
    )
    // "to NAME", "at MERCHANT", "VPA name@bank", "to VPA xyz"
    private val merchantRegex = Regex(
        """(?:to|at|towards|vpa|to vpa)\s+([a-z0-9@._\- ]{3,40}?)(?:\s+(?:on|ref|upi|txn|a/c|bal|avl)|[.\n]|$)""",
        RegexOption.IGNORE_CASE
    )
    private val bankRegex = Regex(
        """\b(hdfc|icici|sbi|axis|kotak|yes bank|pnb|bob|canara|idfc|indusind|federal|rbl|au bank|paytm|phonepe|gpay|amazon pay)\b""",
        RegexOption.IGNORE_CASE
    )

    fun looksLikeTransaction(body: String): Boolean {
        val b = body.lowercase()
        val hasMoney = amountRegex.containsMatchIn(body)
        val hasAction = (debitWords + creditWords).any { b.contains(it) }
        return hasMoney && hasAction
    }

    fun parse(body: String): ParsedSms? {
        if (!looksLikeTransaction(body)) return null
        val b = body.lowercase()

        val amount = amountRegex.find(body)
            ?.groupValues?.get(1)
            ?.replace(",", "")
            ?.toDoubleOrNull() ?: return null
        if (amount <= 0.0) return null

        val isCredit = creditWords.any { b.contains(it) } && !debitWords.any { b.contains(it) }
        // If both present, prefer the one appearing first.
        val type = if (isCredit) {
            TxnType.INCOME
        } else if (debitWords.any { b.contains(it) }) {
            TxnType.EXPENSE
        } else {
            TxnType.INCOME
        }

        val ref = refRegex.find(body)?.groupValues?.get(1)
        val merchant = merchantRegex.find(body)?.groupValues?.get(1)?.trim()?.trim('.', ',')?.take(40) ?: ""
        val bank = bankRegex.find(body)?.value?.uppercase()

        return ParsedSms(
            amount = amount,
            type = type,
            merchant = merchant,
            ref = ref,
            bankHint = bank
        )
    }
}
