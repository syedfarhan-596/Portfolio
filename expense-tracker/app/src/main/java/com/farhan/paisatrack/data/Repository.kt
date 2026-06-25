package com.farhan.paisatrack.data

import kotlinx.coroutines.flow.Flow

data class AccountBalance(val account: Account, val balance: Double)

data class PeopleSummary(
    val contactName: String,
    val contactKey: String?,
    /** positive = they owe you, negative = you owe them */
    val net: Double,
    val toReceive: Double,
    val toPay: Double,
    val dueAfterSalary: Boolean,
    val debts: List<Debt>
)

class Repository(private val db: AppDatabase) {

    val accountDao = db.accountDao()
    val categoryDao = db.categoryDao()
    val txnDao = db.txnDao()
    val debtDao = db.debtDao()

    fun accounts(): Flow<List<Account>> = accountDao.active()
    fun allAccounts(): Flow<List<Account>> = accountDao.all()
    fun categories(): Flow<List<Category>> = categoryDao.all()
    fun categoriesByType(type: TxnType): Flow<List<Category>> = categoryDao.byType(type)
    fun confirmedTxns(): Flow<List<Txn>> = txnDao.confirmed()
    fun pendingTxns(): Flow<List<Txn>> = txnDao.pending()
    fun debts(): Flow<List<Debt>> = debtDao.all()

    suspend fun accountById(id: Long) = accountDao.byId(id)
    suspend fun txnById(id: Long) = txnDao.byId(id)
    suspend fun debtById(id: Long) = debtDao.byId(id)

    suspend fun upsertAccount(a: Account) = accountDao.insert(a)
    suspend fun updateAccount(a: Account) = accountDao.update(a)
    suspend fun deleteAccount(a: Account) = accountDao.delete(a)

    suspend fun upsertCategory(c: Category) = categoryDao.insert(c)
    suspend fun updateCategory(c: Category) = categoryDao.update(c)
    suspend fun deleteCategory(c: Category) = categoryDao.delete(c)

    suspend fun upsertTxn(t: Txn) = txnDao.insert(t)
    suspend fun updateTxn(t: Txn) = txnDao.update(t)
    suspend fun deleteTxn(t: Txn) = txnDao.delete(t)
    suspend fun deleteTxnById(id: Long) = txnDao.deleteById(id)
    suspend fun refExists(ref: String) = txnDao.countByRef(ref) > 0

    suspend fun upsertDebt(d: Debt) = debtDao.insert(d)
    suspend fun updateDebt(d: Debt) = debtDao.update(d)
    suspend fun deleteDebt(d: Debt) = debtDao.delete(d)

    /** Compute live balance for one account from confirmed transactions. */
    fun computeBalance(account: Account, txns: List<Txn>): Double {
        var bal = account.openingBalance
        for (t in txns) {
            if (t.status != TxnStatus.CONFIRMED) continue
            when (t.type) {
                TxnType.INCOME -> if (t.accountId == account.id) bal += t.amount
                TxnType.EXPENSE -> if (t.accountId == account.id) bal -= t.amount
                TxnType.TRANSFER -> {
                    if (t.accountId == account.id) bal -= t.amount
                    if (t.toAccountId == account.id) bal += t.amount
                }
            }
        }
        return bal
    }

    companion object {
        suspend fun seedIfEmpty(db: AppDatabase) {
            val repo = Repository(db)
            if (repo.accountDao.count() == 0) {
                val accs = listOf(
                    Account(name = "Bank 1", type = AccountType.BANK, colorHex = "#0984E3", icon = "account_balance", sortOrder = 0),
                    Account(name = "Bank 2", type = AccountType.BANK, colorHex = "#00B894", icon = "account_balance", sortOrder = 1),
                    Account(name = "Bank 3", type = AccountType.BANK, colorHex = "#6C5CE7", icon = "account_balance", sortOrder = 2),
                    Account(name = "Cash", type = AccountType.CASH, colorHex = "#FDCB6E", icon = "payments", sortOrder = 3),
                    Account(name = "SBI PhonePe Credit Card", type = AccountType.CREDIT_CARD, colorHex = "#E17055", icon = "credit_card", includeInTotal = false, sortOrder = 4)
                )
                accs.forEach { repo.accountDao.insert(it) }
            }
            if (repo.categoryDao.count() == 0) {
                val cats = listOf(
                    Category(name = "Food", type = TxnType.EXPENSE, icon = "restaurant", colorHex = "#E17055", isDefault = true, sortOrder = 0),
                    Category(name = "Clothing", type = TxnType.EXPENSE, icon = "checkroom", colorHex = "#0984E3", isDefault = true, sortOrder = 1),
                    Category(name = "Family", type = TxnType.EXPENSE, icon = "family_restroom", colorHex = "#00B894", isDefault = true, sortOrder = 2),
                    Category(name = "Friends / Outing", type = TxnType.EXPENSE, icon = "groups", colorHex = "#6C5CE7", isDefault = true, sortOrder = 3),
                    Category(name = "Groceries", type = TxnType.EXPENSE, icon = "shopping_cart", colorHex = "#00CEC9", isDefault = true, sortOrder = 4),
                    Category(name = "Transport", type = TxnType.EXPENSE, icon = "directions_car", colorHex = "#FDCB6E", isDefault = true, sortOrder = 5),
                    Category(name = "Bills", type = TxnType.EXPENSE, icon = "receipt_long", colorHex = "#D63031", isDefault = true, sortOrder = 6),
                    Category(name = "Shopping", type = TxnType.EXPENSE, icon = "shopping_bag", colorHex = "#E84393", isDefault = true, sortOrder = 7),
                    Category(name = "Health", type = TxnType.EXPENSE, icon = "local_hospital", colorHex = "#FF7675", isDefault = true, sortOrder = 8),
                    Category(name = "Entertainment", type = TxnType.EXPENSE, icon = "movie", colorHex = "#A29BFE", isDefault = true, sortOrder = 9),
                    Category(name = "Other", type = TxnType.EXPENSE, icon = "category", colorHex = "#636E72", isDefault = true, sortOrder = 10),
                    Category(name = "Salary", type = TxnType.INCOME, icon = "payments", colorHex = "#00B894", isDefault = true, sortOrder = 0),
                    Category(name = "Refund / Repayment", type = TxnType.INCOME, icon = "undo", colorHex = "#0984E3", isDefault = true, sortOrder = 1),
                    Category(name = "Cashback / Rewards", type = TxnType.INCOME, icon = "card_giftcard", colorHex = "#6C5CE7", isDefault = true, sortOrder = 2),
                    Category(name = "Other Income", type = TxnType.INCOME, icon = "category", colorHex = "#636E72", isDefault = true, sortOrder = 3)
                )
                cats.forEach { repo.categoryDao.insert(it) }
            }
        }
    }
}
