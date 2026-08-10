package com.farhan.paisatrack.sms

import com.farhan.paisatrack.data.Account
import com.farhan.paisatrack.data.AccountType
import com.farhan.paisatrack.data.TxnType

/** Result of parsing a bank / UPI alert SMS. */
data class ParsedSms(
    val amount: Double,
    val type: TxnType,       // EXPENSE (debit) or INCOME (credit)
    val merchant: String,
    val ref: String?,
    val bankHint: String?,
    val isCreditCard: Boolean = false
)

object SmsParser {

    private val debitWords = listOf(
        "debited", "debit", "spent", "paid", "sent", "withdrawn",
        "purchase", "deducted", "txn of", "payment of"
    )
    private val creditWords = listOf(
        "credited", "credit", "received", "deposited", "added", "refund"
    )

    // Bank/marketing SMS that mention money but are not real transaction alerts.
    private val promoWords = listOf(
        "cashback up to", "up to ₹", "upto ₹", "% off", "% cashback", "flat off", "flat ₹",
        "mega sale", "sale is live", "offer valid", "limited period", "limited time",
        "hurry", "lucky draw", "click here", "apply now", "pre-approved", "preapproved",
        "pre approved", "instant loan", "insta loan", "personal loan of", "loan up to",
        "loan offer", "t&c apply", "tnc apply", "terms and conditions apply", "unsubscribe",
        "download now", "install now", "book now", "shop now", "explore now",
        "grab the deal", "deal of the day", "exclusive offer", "new arrival",
        "coupon code", "promo code", "voucher code", "congratulations you",
        "you have won", "you've won", "redeem now", "free gift", "starting at just",
        "get flat", "save up to", "lowest price", "best offer", "special offer",
        "welcome offer", "festive offer", "bumper offer", "win rewards", "win prizes",
        "reply stop", "know more", "call now", "visit nearest branch to avail",
        "eligible for a loan", "increase your limit", "activate now", "upgrade now"
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
        """\b(hdfc|icici|state bank of india|sbi card|sbi|axis|kotak|yes bank|punjab national bank|pnb|bank of baroda|bob|canara|idfc|indusind|federal|rbl|au bank|au small finance|paytm|phonepe|gpay|amazon pay)\b""",
        RegexOption.IGNORE_CASE
    )
    private val creditCardWords = listOf(
        "credit card", "card ending", "card no. xx", "card no xx", "card xx",
        "avl limit", "available limit", "credit limit", "card statement",
        "minimum amount due", "total amount due", "card outstanding"
    )
    private val debitCardWords = listOf("debit card")

    /** Normalize a raw bank match to the short code used in account names, e.g. "State Bank of India" -> "SBI". */
    private fun normalizeBank(raw: String): String {
        val r = raw.lowercase()
        return when {
            r.contains("state bank") || r.contains("sbi") -> "sbi"
            r.contains("punjab national") || r == "pnb" -> "pnb"
            r.contains("bank of baroda") || r == "bob" -> "bob"
            else -> r
        }
    }

    fun looksLikeTransaction(body: String): Boolean {
        val b = body.lowercase()
        if (promoWords.any { b.contains(it) }) return false
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
        val bank = bankRegex.find(body)?.value?.let { normalizeBank(it) }
        val isCreditCard = creditCardWords.any { b.contains(it) } && !debitCardWords.any { b.contains(it) }

        return ParsedSms(
            amount = amount,
            type = type,
            merchant = merchant,
            ref = ref,
            bankHint = bank,
            isCreditCard = isCreditCard
        )
    }

    /**
     * Pick the account a parsed SMS should post to: match the bank name in the SMS against
     * account names, preferring a CREDIT_CARD account when the SMS is about a card and a
     * non-card account otherwise (so e.g. an SBI Card charge doesn't land in the SBI savings
     * account just because both accounts have "SBI" in their name). Falls back to the given
     * default account, or null to leave the transaction unassigned.
     */
    fun matchAccountId(accounts: List<Account>, parsed: ParsedSms, defaultAccountId: Long): Long? {
        val hint = parsed.bankHint?.lowercase()
        if (hint != null) {
            val candidates = accounts.filter { acc ->
                val name = acc.name.lowercase()
                name.contains(hint) || hint.contains(name)
            }
            if (candidates.isNotEmpty()) {
                val preferred = if (parsed.isCreditCard) {
                    candidates.firstOrNull { it.type == AccountType.CREDIT_CARD }
                } else {
                    candidates.firstOrNull { it.type != AccountType.CREDIT_CARD }
                }
                return (preferred ?: candidates.first()).id
            }
        }
        if (defaultAccountId > 0 && accounts.any { it.id == defaultAccountId }) return defaultAccountId
        return null
    }
}
