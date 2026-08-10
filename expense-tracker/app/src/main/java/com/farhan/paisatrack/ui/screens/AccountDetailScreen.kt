package com.farhan.paisatrack.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.automirrored.filled.TrendingDown
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.farhan.paisatrack.data.AccountType
import com.farhan.paisatrack.data.TxnType
import com.farhan.paisatrack.ui.MainViewModel
import com.farhan.paisatrack.ui.components.EmptyState
import com.farhan.paisatrack.ui.components.IconBadge
import com.farhan.paisatrack.ui.theme.ExpenseRed
import com.farhan.paisatrack.ui.theme.IncomeGreen
import com.farhan.paisatrack.util.Format
import com.farhan.paisatrack.util.IconMap

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountDetailScreen(
    vm: MainViewModel,
    accountId: Long,
    onBack: () -> Unit,
    onOpenTxn: (Long) -> Unit
) {
    val balances by vm.balances.collectAsStateWithLifecycle()
    val allTxns by vm.confirmedTxns.collectAsStateWithLifecycle()
    val categories by vm.allCategories.collectAsStateWithLifecycle()
    val catById = categories.associateBy { it.id }

    var showEdit by remember { mutableStateOf(false) }

    val ab = balances.firstOrNull { it.account.id == accountId } ?: run {
        // Account was deleted while this screen was open.
        Scaffold(topBar = {
            TopAppBar(
                title = { Text("Account") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") } }
            )
        }) { padding -> Column(Modifier.padding(padding)) {} }
        return
    }
    val account = ab.account
    val isCard = account.type == AccountType.CREDIT_CARD

    val accountTxns = allTxns
        .filter { it.accountId == accountId || it.toAccountId == accountId }
        .sortedByDescending { it.dateTime }

    val nowMonth = MainViewModel.monthKeyNow()
    val monthTxns = accountTxns.filter { MainViewModel.monthKey(it.dateTime) == nowMonth && it.accountId == accountId }
    val monthOut = monthTxns.filter { it.type == TxnType.EXPENSE }.sumOf { it.amount }
    val monthIn = monthTxns.filter { it.type == TxnType.INCOME }.sumOf { it.amount }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(account.name) },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") }
                },
                actions = {
                    IconButton(onClick = { showEdit = true }) {
                        Icon(Icons.Filled.Edit, contentDescription = "Edit account")
                    }
                }
            )
        }
    ) { padding ->
        LazyColumn(
            Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(16.dp, 8.dp, 16.dp, 96.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(20.dp),
                    colors = CardDefaults.cardColors(containerColor = IconMap.parseColor(account.colorHex))
                ) {
                    Column(Modifier.padding(20.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            IconBadge(IconMap.icon(account.icon), androidx.compose.ui.graphics.Color.White)
                            Spacer(Modifier.width(12.dp))
                            Column {
                                Text(
                                    account.type.name.lowercase().replaceFirstChar { it.uppercase() }.replace("_", " "),
                                    color = androidx.compose.ui.graphics.Color.White.copy(alpha = 0.85f),
                                    fontSize = 13.sp
                                )
                                Text(
                                    if (isCard) "Outstanding" else "Balance",
                                    color = androidx.compose.ui.graphics.Color.White.copy(alpha = 0.85f),
                                    fontSize = 13.sp
                                )
                            }
                        }
                        Spacer(Modifier.height(12.dp))
                        Text(
                            Format.money(if (isCard) -ab.balance else ab.balance),
                            color = androidx.compose.ui.graphics.Color.White,
                            fontSize = 32.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }

            item {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    MiniStatTile(
                        modifier = Modifier.weight(1f),
                        label = "This month spent",
                        value = Format.money(monthOut),
                        color = ExpenseRed,
                        icon = Icons.AutoMirrored.Filled.TrendingDown
                    )
                    MiniStatTile(
                        modifier = Modifier.weight(1f),
                        label = if (isCard) "This month paid in" else "This month in",
                        value = Format.money(monthIn),
                        color = IncomeGreen,
                        icon = Icons.AutoMirrored.Filled.TrendingUp
                    )
                }
            }

            item {
                SectionHeader("Transactions (${accountTxns.size})", actionLabel = null, onAction = null)
            }

            if (accountTxns.isEmpty()) {
                item {
                    EmptyState(
                        icon = Icons.AutoMirrored.Filled.ReceiptLong,
                        title = "No transactions yet",
                        subtitle = "Transactions posted to this account will show up here."
                    )
                }
            } else {
                items(accountTxns, key = { it.id }) { t ->
                    val cat = t.categoryId?.let { catById[it] }
                    TransactionRow(
                        title = when {
                            t.contactName != null -> t.contactName!!
                            t.merchant.isNotBlank() -> t.merchant
                            cat != null -> cat.name
                            else -> t.type.name.lowercase().replaceFirstChar { it.uppercase() }
                        },
                        subtitle = cat?.name ?: t.type.name.lowercase().replaceFirstChar { it.uppercase() },
                        note = t.note,
                        amount = t.amount,
                        type = if (t.type == TxnType.TRANSFER && t.toAccountId == accountId) TxnType.INCOME else t.type,
                        icon = IconMap.icon(cat?.icon ?: "category"),
                        color = IconMap.parseColor(cat?.colorHex ?: "#636E72"),
                        dateText = Format.day(t.dateTime),
                        onClick = { onOpenTxn(t.id) }
                    )
                }
            }
        }
    }

    if (showEdit) {
        AccountEditorDialog(
            account = account,
            onDismiss = { showEdit = false },
            onSave = { vm.saveAccount(it); showEdit = false },
            onDelete = { vm.deleteAccount(account); showEdit = false; onBack() }
        )
    }
}

@Composable
private fun MiniStatTile(
    modifier: Modifier = Modifier,
    label: String,
    value: String,
    color: androidx.compose.ui.graphics.Color,
    icon: androidx.compose.ui.graphics.vector.ImageVector
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(Modifier.padding(14.dp)) {
            IconBadge(icon = icon, tint = color, size = 36)
            Spacer(Modifier.height(10.dp))
            Text(label, fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(value, fontWeight = FontWeight.Bold, fontSize = 18.sp)
        }
    }
}
