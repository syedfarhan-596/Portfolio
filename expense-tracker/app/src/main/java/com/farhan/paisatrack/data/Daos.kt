package com.farhan.paisatrack.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface AccountDao {
    @Query("SELECT * FROM accounts ORDER BY sortOrder, id")
    fun all(): Flow<List<Account>>

    @Query("SELECT * FROM accounts WHERE archived = 0 ORDER BY sortOrder, id")
    fun active(): Flow<List<Account>>

    @Query("SELECT * FROM accounts WHERE id = :id")
    suspend fun byId(id: Long): Account?

    @Query("SELECT id FROM accounts WHERE archived = 0 ORDER BY sortOrder, id LIMIT 1")
    suspend fun firstActiveId(): Long?

    @Query("SELECT COUNT(*) FROM accounts")
    suspend fun count(): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(a: Account): Long

    @Update suspend fun update(a: Account)
    @Delete suspend fun delete(a: Account)
}

@Dao
interface CategoryDao {
    @Query("SELECT * FROM categories ORDER BY sortOrder, name")
    fun all(): Flow<List<Category>>

    @Query("SELECT * FROM categories WHERE type = :type ORDER BY sortOrder, name")
    fun byType(type: TxnType): Flow<List<Category>>

    @Query("SELECT COUNT(*) FROM categories")
    suspend fun count(): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(c: Category): Long

    @Update suspend fun update(c: Category)
    @Delete suspend fun delete(c: Category)
}

@Dao
interface TxnDao {
    @Query("SELECT * FROM transactions WHERE status = 'CONFIRMED' ORDER BY dateTime DESC")
    fun confirmed(): Flow<List<Txn>>

    @Query("SELECT * FROM transactions WHERE status = 'PENDING' ORDER BY dateTime DESC")
    fun pending(): Flow<List<Txn>>

    @Query("SELECT * FROM transactions ORDER BY dateTime DESC")
    fun all(): Flow<List<Txn>>

    @Query("SELECT * FROM transactions WHERE id = :id")
    suspend fun byId(id: Long): Txn?

    @Query("SELECT COUNT(*) FROM transactions WHERE upiRef = :ref AND upiRef IS NOT NULL")
    suspend fun countByRef(ref: String): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(t: Txn): Long

    @Update suspend fun update(t: Txn)
    @Delete suspend fun delete(t: Txn)

    @Query("DELETE FROM transactions WHERE id = :id")
    suspend fun deleteById(id: Long)
}

@Dao
interface DebtDao {
    @Query("SELECT * FROM debts ORDER BY settled, createdAt DESC")
    fun all(): Flow<List<Debt>>

    @Query("SELECT * FROM debts WHERE id = :id")
    suspend fun byId(id: Long): Debt?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(d: Debt): Long

    @Update suspend fun update(d: Debt)
    @Delete suspend fun delete(d: Debt)
}
