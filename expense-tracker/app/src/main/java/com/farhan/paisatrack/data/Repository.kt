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
    val investmentDao = db.investmentDao()

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

    fun investments(): Flow<List<Investment>> = investmentDao.all()
    suspend fun investmentById(id: Long) = investmentDao.byId(id)
    suspend fun upsertInvestment(i: Investment) = investmentDao.insert(i)
    suspend fun updateInvestment(i: Investment) = investmentDao.update(i)
    suspend fun deleteInvestment(i: Investment) = investmentDao.delete(i)

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
        // Special category names used by automated flows.
        const val CAT_REPAYMENT = "Refund / Repayment"
        const val CAT_SETTLEMENT = "Debt Settlement"
        const val CAT_CARD_PAYMENT = "Credit Card Payment"
        const val CAT_CARD_POINTS = "Card Points Redeemed"
        const val CAT_INVESTMENT = "Investments"
        const val CAT_INVEST_RETURN = "Investment Returns"
        const val CAT_LENT = "Money Lent"
        const val CAT_BORROWED = "Money Borrowed"

        val defaultCategories: List<Category> = listOf(
            // Expenses
            Category(name = "Food", type = TxnType.EXPENSE, icon = "restaurant", colorHex = "#E17055", isDefault = true, sortOrder = 0),
            Category(name = "Groceries", type = TxnType.EXPENSE, icon = "shopping_cart", colorHex = "#00CEC9", isDefault = true, sortOrder = 1),
            Category(name = "Clothing", type = TxnType.EXPENSE, icon = "checkroom", colorHex = "#0984E3", isDefault = true, sortOrder = 2),
            Category(name = "Family", type = TxnType.EXPENSE, icon = "family_restroom", colorHex = "#00B894", isDefault = true, sortOrder = 3),
            Category(name = "Friends / Outing", type = TxnType.EXPENSE, icon = "groups", colorHex = "#6C5CE7", isDefault = true, sortOrder = 4),
            Category(name = "Transport", type = TxnType.EXPENSE, icon = "directions_car", colorHex = "#FDCB6E", isDefault = true, sortOrder = 5),
            Category(name = "Fuel", type = TxnType.EXPENSE, icon = "local_gas", colorHex = "#D63031", isDefault = true, sortOrder = 6),
            Category(name = "Travel", type = TxnType.EXPENSE, icon = "flight", colorHex = "#0984E3", isDefault = true, sortOrder = 7),
            Category(name = "Bills & Utilities", type = TxnType.EXPENSE, icon = "receipt_long", colorHex = "#D63031", isDefault = true, sortOrder = 8),
            Category(name = "Rent", type = TxnType.EXPENSE, icon = "home", colorHex = "#E17055", isDefault = true, sortOrder = 9),
            Category(name = "Shopping", type = TxnType.EXPENSE, icon = "shopping_bag", colorHex = "#E84393", isDefault = true, sortOrder = 10),
            Category(name = "Health", type = TxnType.EXPENSE, icon = "local_hospital", colorHex = "#FF7675", isDefault = true, sortOrder = 11),
            Category(name = "Entertainment", type = TxnType.EXPENSE, icon = "movie", colorHex = "#A29BFE", isDefault = true, sortOrder = 12),
            Category(name = "Subscriptions", type = TxnType.EXPENSE, icon = "subscriptions", colorHex = "#6C5CE7", isDefault = true, sortOrder = 13),
            Category(name = "Education", type = TxnType.EXPENSE, icon = "school", colorHex = "#0984E3", isDefault = true, sortOrder = 14),
            Category(name = "Personal Care", type = TxnType.EXPENSE, icon = "spa", colorHex = "#E84393", isDefault = true, sortOrder = 15),
            Category(name = "Gifts & Donations", type = TxnType.EXPENSE, icon = "card_giftcard", colorHex = "#FAB1A0", isDefault = true, sortOrder = 16),
            Category(name = "EMI & Loans", type = TxnType.EXPENSE, icon = "savings", colorHex = "#636E72", isDefault = true, sortOrder = 17),
            Category(name = "Insurance", type = TxnType.EXPENSE, icon = "shield", colorHex = "#00B894", isDefault = true, sortOrder = 18),
            Category(name = "Pets", type = TxnType.EXPENSE, icon = "pets", colorHex = "#FDCB6E", isDefault = true, sortOrder = 19),
            Category(name = "Sports & Fitness", type = TxnType.EXPENSE, icon = "sports", colorHex = "#00CEC9", isDefault = true, sortOrder = 20),
            Category(name = CAT_INVESTMENT, type = TxnType.EXPENSE, icon = "trending_up", colorHex = "#1AAD7E", isDefault = true, sortOrder = 21),
            Category(name = CAT_CARD_PAYMENT, type = TxnType.EXPENSE, icon = "credit_card", colorHex = "#E17055", isDefault = true, sortOrder = 22),
            Category(name = CAT_SETTLEMENT, type = TxnType.EXPENSE, icon = "handshake", colorHex = "#A29BFE", isDefault = true, sortOrder = 23),
            Category(name = CAT_LENT, type = TxnType.EXPENSE, icon = "handshake", colorHex = "#0984E3", isDefault = true, sortOrder = 24),
            Category(name = "Other", type = TxnType.EXPENSE, icon = "category", colorHex = "#636E72", isDefault = true, sortOrder = 25),
            // Income
            Category(name = "Salary", type = TxnType.INCOME, icon = "payments", colorHex = "#00B894", isDefault = true, sortOrder = 0),
            Category(name = "Business", type = TxnType.INCOME, icon = "store", colorHex = "#0984E3", isDefault = true, sortOrder = 1),
            Category(name = "Freelance", type = TxnType.INCOME, icon = "work", colorHex = "#6C5CE7", isDefault = true, sortOrder = 2),
            Category(name = CAT_REPAYMENT, type = TxnType.INCOME, icon = "undo", colorHex = "#0984E3", isDefault = true, sortOrder = 3),
            Category(name = "Cashback / Rewards", type = TxnType.INCOME, icon = "card_giftcard", colorHex = "#6C5CE7", isDefault = true, sortOrder = 4),
            Category(name = CAT_CARD_POINTS, type = TxnType.INCOME, icon = "star", colorHex = "#FDCB6E", isDefault = true, sortOrder = 5),
            Category(name = CAT_INVEST_RETURN, type = TxnType.INCOME, icon = "trending_up", colorHex = "#1AAD7E", isDefault = true, sortOrder = 6),
            Category(name = CAT_BORROWED, type = TxnType.INCOME, icon = "handshake", colorHex = "#FDCB6E", isDefault = true, sortOrder = 7),
            Category(name = "Interest", type = TxnType.INCOME, icon = "savings", colorHex = "#00CEC9", isDefault = true, sortOrder = 8),
            Category(name = "Other Income", type = TxnType.INCOME, icon = "category", colorHex = "#636E72", isDefault = true, sortOrder = 9)
        )

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
            // Add any default categories that don't already exist (covers fresh installs and updates).
            val existing = repo.categoryDao.allOnce().map { it.name }.toHashSet()
            defaultCategories.filter { it.name !in existing }.forEach { repo.categoryDao.insert(it) }
        }
    }
}
