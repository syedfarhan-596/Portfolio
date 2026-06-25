package com.farhan.paisatrack.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.farhan.paisatrack.PaisaApp
import com.farhan.paisatrack.data.Account
import com.farhan.paisatrack.data.AccountBalance
import com.farhan.paisatrack.data.AccountType
import com.farhan.paisatrack.data.Category
import com.farhan.paisatrack.data.Debt
import com.farhan.paisatrack.data.DebtDirection
import com.farhan.paisatrack.data.PeopleSummary
import com.farhan.paisatrack.data.Repository
import com.farhan.paisatrack.data.Txn
import com.farhan.paisatrack.data.TxnStatus
import com.farhan.paisatrack.data.TxnType
import com.farhan.paisatrack.util.Prefs
import com.farhan.paisatrack.work.ReminderScheduler
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class DashboardState(
    val liquidTotal: Double = 0.0,
    val creditOutstanding: Double = 0.0,
    val netWorth: Double = 0.0,
    val toReceive: Double = 0.0,
    val toPay: Double = 0.0,
    val monthExpense: Double = 0.0,
    val monthIncome: Double = 0.0,
    val balances: List<AccountBalance> = emptyList()
)

class MainViewModel(app: Application) : AndroidViewModel(app) {

    private val repo: Repository = (app as PaisaApp).repository
    val prefs = Prefs(app)

    val accounts: StateFlow<List<Account>> =
        repo.accounts().stateInVm(emptyList())
    val allCategories: StateFlow<List<Category>> =
        repo.categories().stateInVm(emptyList())
    val confirmedTxns: StateFlow<List<Txn>> =
        repo.confirmedTxns().stateInVm(emptyList())
    val pendingTxns: StateFlow<List<Txn>> =
        repo.pendingTxns().stateInVm(emptyList())
    val debts: StateFlow<List<Debt>> =
        repo.debts().stateInVm(emptyList())

    val balances: StateFlow<List<AccountBalance>> =
        combine(repo.accounts(), repo.confirmedTxns()) { accs, txns ->
            accs.map { AccountBalance(it, repo.computeBalance(it, txns)) }
        }.stateInVm(emptyList())

    val dashboard: StateFlow<DashboardState> =
        combine(repo.accounts(), repo.confirmedTxns(), repo.debts()) { accs, txns, debts ->
            val balances = accs.map { AccountBalance(it, repo.computeBalance(it, txns)) }
            val liquid = balances.filter {
                it.account.type != AccountType.CREDIT_CARD && it.account.includeInTotal
            }.sumOf { it.balance }
            val credit = balances.filter { it.account.type == AccountType.CREDIT_CARD }
                .sumOf { -it.balance } // spent on card = negative balance -> positive outstanding
            val toReceive = debts.filter { !it.settled && it.direction == DebtDirection.I_LENT }
                .sumOf { it.amount - it.paidAmount }
            val toPay = debts.filter { !it.settled && it.direction == DebtDirection.I_BORROWED }
                .sumOf { it.amount - it.paidAmount }
            val nowMonth = monthKeyNow()
            val monthTxns = txns.filter { monthKey(it.dateTime) == nowMonth }
            val monthExpense = monthTxns.filter { it.type == TxnType.EXPENSE }.sumOf { it.amount }
            val monthIncome = monthTxns.filter { it.type == TxnType.INCOME }.sumOf { it.amount }
            DashboardState(
                liquidTotal = liquid,
                creditOutstanding = credit,
                netWorth = liquid - credit + (toReceive - toPay),
                toReceive = toReceive,
                toPay = toPay,
                monthExpense = monthExpense,
                monthIncome = monthIncome,
                balances = balances
            )
        }.stateInVm(DashboardState())

    val people: StateFlow<List<PeopleSummary>> =
        repo.debts().mapToPeople().stateInVm(emptyList())

    // ---- Account ops ----
    fun saveAccount(a: Account) = launchIo { repo.upsertAccount(a) }
    fun updateAccount(a: Account) = launchIo { repo.updateAccount(a) }
    fun deleteAccount(a: Account) = launchIo { repo.deleteAccount(a) }

    // ---- Category ops ----
    fun saveCategory(c: Category) = launchIo { repo.upsertCategory(c) }
    fun deleteCategory(c: Category) = launchIo { repo.deleteCategory(c) }

    // ---- Txn ops ----
    fun saveTxn(t: Txn) = launchIo { repo.upsertTxn(t) }
    fun deleteTxn(t: Txn) = launchIo { repo.deleteTxn(t) }
    fun confirmTxn(t: Txn) = launchIo { repo.upsertTxn(t.copy(status = TxnStatus.CONFIRMED)) }
    fun dismissPending(t: Txn) = launchIo { repo.deleteTxn(t) }
    suspend fun txnById(id: Long) = repo.txnById(id)

    // ---- Debt ops ----
    fun saveDebt(d: Debt) = launchIo { repo.upsertDebt(d) }
    fun deleteDebt(d: Debt) = launchIo { repo.deleteDebt(d) }
    fun settleDebt(d: Debt) = launchIo {
        repo.updateDebt(d.copy(paidAmount = d.amount, settled = true, settledAt = System.currentTimeMillis()))
    }
    fun recordPayment(d: Debt, amount: Double) = launchIo {
        val paid = (d.paidAmount + amount).coerceAtMost(d.amount)
        val settled = paid >= d.amount - 0.01
        repo.updateDebt(d.copy(paidAmount = paid, settled = settled,
            settledAt = if (settled) System.currentTimeMillis() else null))
    }
    suspend fun debtById(id: Long) = repo.debtById(id)

    // ---- Settings ----
    fun setReminder(enabled: Boolean, hour: Int, minute: Int) {
        prefs.reminderEnabled = enabled
        prefs.reminderHour = hour
        prefs.reminderMinute = minute
        ReminderScheduler.schedule(getApplication())
    }
    fun setSmsCapture(enabled: Boolean) { prefs.smsCaptureEnabled = enabled }
    fun setDefaultUpiAccount(id: Long) { prefs.defaultUpiAccountId = id }

    /** Scan the device SMS inbox, parse bank/UPI alerts and add them as PENDING transactions. */
    fun importSmsInbox(onDone: (Int) -> Unit) {
        viewModelScope.launch {
            val added = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
                val ctx = getApplication<Application>()
                val accId = repo.accountDao.firstActiveId()
                    ?: prefs.defaultUpiAccountId.takeIf { it > 0 } ?: 0L
                val targetAcc = if (prefs.defaultUpiAccountId > 0) prefs.defaultUpiAccountId else accId
                var count = 0
                val uri = android.provider.Telephony.Sms.Inbox.CONTENT_URI
                val cols = arrayOf(
                    android.provider.Telephony.Sms.BODY,
                    android.provider.Telephony.Sms.DATE
                )
                ctx.contentResolver.query(uri, cols, null, null,
                    "${android.provider.Telephony.Sms.DATE} DESC LIMIT 300")?.use { c ->
                    val bodyIdx = c.getColumnIndexOrThrow(android.provider.Telephony.Sms.BODY)
                    val dateIdx = c.getColumnIndexOrThrow(android.provider.Telephony.Sms.DATE)
                    while (c.moveToNext()) {
                        val body = c.getString(bodyIdx) ?: continue
                        val date = c.getLong(dateIdx)
                        val parsed = com.farhan.paisatrack.sms.SmsParser.parse(body) ?: continue
                        if (parsed.ref != null && repo.refExists(parsed.ref)) continue
                        repo.upsertTxn(
                            Txn(
                                type = parsed.type,
                                amount = parsed.amount,
                                accountId = targetAcc,
                                merchant = parsed.merchant,
                                dateTime = date,
                                source = com.farhan.paisatrack.data.TxnSource.IMPORT,
                                status = TxnStatus.PENDING,
                                upiRef = parsed.ref,
                                rawSms = body
                            )
                        )
                        count++
                    }
                }
                count
            }
            onDone(added)
        }
    }

    private fun launchIo(block: suspend () -> Unit) = viewModelScope.launch { block() }

    private fun <T> kotlinx.coroutines.flow.Flow<T>.stateInVm(initial: T): StateFlow<T> =
        stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), initial)

    private fun kotlinx.coroutines.flow.Flow<List<Debt>>.mapToPeople() =
        this.map { debts ->
            debts.groupBy { it.contactName }.map { (name, list) ->
                val toReceive = list.filter { !it.settled && it.direction == DebtDirection.I_LENT }
                    .sumOf { it.amount - it.paidAmount }
                val toPay = list.filter { !it.settled && it.direction == DebtDirection.I_BORROWED }
                    .sumOf { it.amount - it.paidAmount }
                PeopleSummary(
                    contactName = name,
                    contactKey = list.firstOrNull()?.contactKey,
                    net = toReceive - toPay,
                    toReceive = toReceive,
                    toPay = toPay,
                    dueAfterSalary = list.any { !it.settled && it.dueAfterSalary },
                    debts = list.sortedByDescending { it.createdAt }
                )
            }.sortedByDescending { kotlin.math.abs(it.net) }
        }

    companion object {
        fun monthKeyNow(): String {
            val d = java.time.LocalDate.now()
            return "%04d-%02d".format(d.year, d.monthValue)
        }
        fun monthKey(millis: Long): String {
            val d = java.time.Instant.ofEpochMilli(millis)
                .atZone(java.time.ZoneId.systemDefault()).toLocalDate()
            return "%04d-%02d".format(d.year, d.monthValue)
        }

        val Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : androidx.lifecycle.ViewModel> create(
                modelClass: Class<T>,
                extras: androidx.lifecycle.viewmodel.CreationExtras
            ): T {
                val app = extras[ViewModelProvider.AndroidViewModelFactory.APPLICATION_KEY] as Application
                return MainViewModel(app) as T
            }
        }
    }
}
