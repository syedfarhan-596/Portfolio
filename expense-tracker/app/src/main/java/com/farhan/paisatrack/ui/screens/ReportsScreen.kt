package com.farhan.paisatrack.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.farhan.paisatrack.data.TxnType
import com.farhan.paisatrack.ui.MainViewModel
import com.farhan.paisatrack.ui.components.SectionCard
import com.farhan.paisatrack.ui.theme.ExpenseRed
import com.farhan.paisatrack.ui.theme.IncomeGreen
import com.farhan.paisatrack.util.Format
import com.farhan.paisatrack.util.IconMap

@Composable
fun ReportsScreen(vm: MainViewModel) {
    val txns by vm.confirmedTxns.collectAsStateWithLifecycle()
    val categories by vm.allCategories.collectAsStateWithLifecycle()
    val accounts by vm.accounts.collectAsStateWithLifecycle()
    val catById = categories.associateBy { it.id }
    val accById = accounts.associateBy { it.id }

    val months = remember(txns) {
        txns.map { Format.monthKey(it.dateTime) to Format.month(it.dateTime) }
            .distinct()
            .sortedByDescending { it.first }
    }
    var selectedMonth by remember(months) { mutableStateOf(months.firstOrNull()?.first) }

    val monthTxns = txns.filter { selectedMonth == null || Format.monthKey(it.dateTime) == selectedMonth }
    val expense = monthTxns.filter { it.type == TxnType.EXPENSE }
    val income = monthTxns.filter { it.type == TxnType.INCOME }
    val totalExpense = expense.sumOf { it.amount }
    val totalIncome = income.sumOf { it.amount }

    val byCategory = expense.groupBy { it.categoryId }
        .map { (cid, list) -> cid to list.sumOf { it.amount } }
        .sortedByDescending { it.second }

    val byAccount = expense.groupBy { it.accountId }
        .map { (aid, list) -> aid to list.sumOf { it.amount } }
        .sortedByDescending { it.second }

    Column(
        Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Text("Reports", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)

        if (months.isNotEmpty()) {
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(months) { (key, label) ->
                    FilterChip(
                        selected = selectedMonth == key,
                        onClick = { selectedMonth = key },
                        label = { Text(label) }
                    )
                }
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            BigStat(Modifier.weight(1f), "Income", Format.money(totalIncome), IncomeGreen)
            BigStat(Modifier.weight(1f), "Expense", Format.money(totalExpense), ExpenseRed)
        }

        SectionCard {
            Text("Net this period", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(6.dp))
            val net = totalIncome - totalExpense
            Text(
                Format.money(net),
                fontWeight = FontWeight.Bold,
                fontSize = 26.sp,
                color = if (net >= 0) IncomeGreen else ExpenseRed
            )
        }

        if (byCategory.isNotEmpty() && totalExpense > 0) {
            SectionCard {
                Text("Spending by category", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(12.dp))
                byCategory.forEach { (cid, amount) ->
                    val cat = cid?.let { catById[it] }
                    val frac = (amount / totalExpense).toFloat()
                    BreakdownBar(
                        label = cat?.name ?: "Uncategorized",
                        amount = amount,
                        fraction = frac,
                        color = IconMap.parseColor(cat?.colorHex ?: "#636E72")
                    )
                    Spacer(Modifier.height(10.dp))
                }
            }
        }

        if (byAccount.isNotEmpty() && totalExpense > 0) {
            SectionCard {
                Text("Spending by account", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(12.dp))
                byAccount.forEach { (aid, amount) ->
                    val acc = accById[aid]
                    val frac = (amount / totalExpense).toFloat()
                    BreakdownBar(
                        label = acc?.name ?: "Unknown",
                        amount = amount,
                        fraction = frac,
                        color = IconMap.parseColor(acc?.colorHex ?: "#6C5CE7")
                    )
                    Spacer(Modifier.height(10.dp))
                }
            }
        }

        if (txns.isEmpty()) {
            SectionCard {
                Text(
                    "Add some transactions to see your reports here.",
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        Spacer(Modifier.height(80.dp))
    }
}

@Composable
private fun BigStat(modifier: Modifier, label: String, value: String, color: Color) {
    androidx.compose.material3.Card(
        modifier = modifier,
        shape = RoundedCornerShape(18.dp),
        colors = androidx.compose.material3.CardDefaults.cardColors(containerColor = color.copy(alpha = 0.12f))
    ) {
        Column(Modifier.padding(16.dp)) {
            Text(label, fontSize = 13.sp)
            Text(value, fontWeight = FontWeight.Bold, fontSize = 20.sp, color = color)
        }
    }
}

@Composable
private fun BreakdownBar(label: String, amount: Double, fraction: Float, color: Color) {
    Column {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(label, fontWeight = FontWeight.Medium, fontSize = 14.sp)
            Text(
                "${Format.money(amount)}  ·  ${(fraction * 100).toInt()}%",
                fontSize = 13.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Spacer(Modifier.height(6.dp))
        Box(
            Modifier
                .fillMaxWidth()
                .height(10.dp)
                .clip(RoundedCornerShape(6.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant)
        ) {
            Box(
                Modifier
                    .fillMaxWidth(fraction.coerceIn(0.02f, 1f))
                    .height(10.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(color)
            )
        }
    }
}
