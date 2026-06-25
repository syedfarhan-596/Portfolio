package com.farhan.paisatrack.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.farhan.paisatrack.data.TxnType
import com.farhan.paisatrack.ui.MainViewModel
import com.farhan.paisatrack.ui.components.EmptyState
import com.farhan.paisatrack.util.Format
import com.farhan.paisatrack.util.IconMap

@Composable
fun TransactionsScreen(
    vm: MainViewModel,
    onAddTxn: () -> Unit,
    onOpenTxn: (Long) -> Unit
) {
    val txns by vm.confirmedTxns.collectAsStateWithLifecycle()
    val accounts by vm.accounts.collectAsStateWithLifecycle()
    val categories by vm.allCategories.collectAsStateWithLifecycle()
    val catById = categories.associateBy { it.id }
    val accById = accounts.associateBy { it.id }

    var query by remember { mutableStateOf("") }
    var filter by remember { mutableStateOf<TxnType?>(null) }

    val filtered = txns.filter { t ->
        (filter == null || t.type == filter) &&
            (query.isBlank() || listOfNotNull(
                t.merchant, t.note, t.contactName, catById[t.categoryId]?.name
            ).any { it.contains(query, ignoreCase = true) })
    }

    val grouped = filtered.groupBy { Format.date(it.dateTime) }

    LazyColumn(
        modifier = Modifier.fillMaxWidth(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp, 8.dp, 16.dp, 96.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        item {
            Text("Activity", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        }
        item {
            OutlinedTextField(
                value = query,
                onValueChange = { query = it },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("Search merchant, note, person…") },
                leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
                singleLine = true
            )
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(selected = filter == null, onClick = { filter = null }, label = { Text("All") })
                FilterChip(selected = filter == TxnType.EXPENSE, onClick = { filter = TxnType.EXPENSE }, label = { Text("Expense") })
                FilterChip(selected = filter == TxnType.INCOME, onClick = { filter = TxnType.INCOME }, label = { Text("Income") })
                FilterChip(selected = filter == TxnType.TRANSFER, onClick = { filter = TxnType.TRANSFER }, label = { Text("Transfer") })
            }
        }

        if (filtered.isEmpty()) {
            item {
                EmptyState(
                    icon = Icons.AutoMirrored.Filled.ReceiptLong,
                    title = "Nothing here yet",
                    subtitle = "Add a transaction with the + button, or import from SMS in Settings."
                )
            }
        }

        grouped.forEach { (date, list) ->
            item(key = "h$date") {
                val dayTotal = list.sumOf { if (it.type == TxnType.INCOME) it.amount else -it.amount }
                Row(Modifier.fillMaxWidth().padding(top = 6.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text(date, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(Format.money(dayTotal), fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            items(list, key = { "t${it.id}" }) { t ->
                val cat = t.categoryId?.let { catById[it] }
                TransactionRow(
                    title = when {
                        t.contactName != null -> t.contactName!!
                        t.merchant.isNotBlank() -> t.merchant
                        cat != null -> cat.name
                        else -> t.type.name.lowercase().replaceFirstChar { it.uppercase() }
                    },
                    subtitle = buildString {
                        append(cat?.name ?: t.type.name.lowercase().replaceFirstChar { it.uppercase() })
                        accById[t.accountId]?.let { append(" · ${it.name}") }
                        if (t.type == TxnType.TRANSFER) accById[t.toAccountId]?.let { append(" → ${it.name}") }
                    },
                    note = t.note,
                    amount = t.amount,
                    type = t.type,
                    icon = IconMap.icon(cat?.icon ?: "category"),
                    color = IconMap.parseColor(cat?.colorHex ?: "#636E72"),
                    dateText = Format.time(t.dateTime),
                    onClick = { onOpenTxn(t.id) }
                )
            }
        }
    }
}
