package com.farhan.paisatrack.data

import androidx.room.TypeConverter

class Converters {
    @TypeConverter fun toAccountType(v: String) = AccountType.valueOf(v)
    @TypeConverter fun fromAccountType(v: AccountType) = v.name

    @TypeConverter fun toTxnType(v: String) = TxnType.valueOf(v)
    @TypeConverter fun fromTxnType(v: TxnType) = v.name

    @TypeConverter fun toTxnSource(v: String) = TxnSource.valueOf(v)
    @TypeConverter fun fromTxnSource(v: TxnSource) = v.name

    @TypeConverter fun toTxnStatus(v: String) = TxnStatus.valueOf(v)
    @TypeConverter fun fromTxnStatus(v: TxnStatus) = v.name

    @TypeConverter fun toDebtDirection(v: String) = DebtDirection.valueOf(v)
    @TypeConverter fun fromDebtDirection(v: DebtDirection) = v.name

    @TypeConverter fun toInvestmentType(v: String) = InvestmentType.valueOf(v)
    @TypeConverter fun fromInvestmentType(v: InvestmentType) = v.name
}
