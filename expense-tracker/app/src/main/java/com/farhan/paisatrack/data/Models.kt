package com.farhan.paisatrack.data

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

enum class AccountType { BANK, CASH, CREDIT_CARD, WALLET }

enum class TxnType { EXPENSE, INCOME, TRANSFER }

enum class TxnSource { MANUAL, SMS, UPI, IMPORT }

enum class TxnStatus { CONFIRMED, PENDING }

enum class DebtDirection { I_LENT, I_BORROWED }

@Entity(tableName = "accounts")
data class Account(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val name: String,
    val type: AccountType,
    val openingBalance: Double = 0.0,
    val colorHex: String = "#6C5CE7",
    val icon: String = "account_balance",
    val creditLimit: Double? = null,
    val includeInTotal: Boolean = true,
    val archived: Boolean = false,
    val sortOrder: Int = 0
)

@Entity(tableName = "categories")
data class Category(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val name: String,
    val type: TxnType = TxnType.EXPENSE,
    val icon: String = "category",
    val colorHex: String = "#00B894",
    val sortOrder: Int = 0,
    val isDefault: Boolean = false
)

@Entity(
    tableName = "transactions",
    indices = [Index("accountId"), Index("categoryId"), Index("dateTime"), Index("status")]
)
data class Txn(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val type: TxnType,
    val amount: Double,
    val accountId: Long,
    val toAccountId: Long? = null,
    val categoryId: Long? = null,
    val note: String = "",
    val merchant: String = "",
    val dateTime: Long,
    val source: TxnSource = TxnSource.MANUAL,
    val status: TxnStatus = TxnStatus.CONFIRMED,
    val contactName: String? = null,
    val contactKey: String? = null,
    val upiRef: String? = null,
    val rawSms: String? = null,
    val debtId: Long? = null
)

@Entity(tableName = "debts", indices = [Index("settled")])
data class Debt(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val contactName: String,
    val contactKey: String? = null,
    val direction: DebtDirection,
    val amount: Double,
    val paidAmount: Double = 0.0,
    val note: String = "",
    val createdAt: Long,
    val dueAfterSalary: Boolean = false,
    val settled: Boolean = false,
    val settledAt: Long? = null,
    val accountId: Long? = null
)
