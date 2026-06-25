package com.farhan.paisatrack.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.farhan.paisatrack.data.Debt
import com.farhan.paisatrack.data.DebtDirection
import com.farhan.paisatrack.ui.MainViewModel
import com.farhan.paisatrack.ui.components.EmptyState
import com.farhan.paisatrack.ui.components.SettleDialog
import com.farhan.paisatrack.ui.theme.ExpenseRed
import com.farhan.paisatrack.ui.theme.IncomeGreen
import com.farhan.paisatrack.util.Format

@Composable
fun PeopleScreen(
    vm: MainViewModel,
    onAddDebt: () -> Unit,
    onOpenDebt: (Long) -> Unit
) {
    val people by vm.people.collectAsStateWithLifecycle()
    val accounts by vm.accounts.collectAsStateWithLifecycle()
    val totalReceive = people.sumOf { it.toReceive }
    val totalPay = people.sumOf { it.toPay }
    var settleTarget by remember { mutableStateOf<Debt?>(null) }

    LazyColumn(
        modifier = Modifier.fillMaxWidth(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp, 8.dp, 16.dp, 96.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text("People & Lending", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                SummaryTile(Modifier.weight(1f), "You'll receive", Format.money(totalReceive), IncomeGreen)
                SummaryTile(Modifier.weight(1f), "You'll pay", Format.money(totalPay), ExpenseRed)
            }
        }
        item {
            Button(onClick = onAddDebt, modifier = Modifier.fillMaxWidth()) {
                Icon(Icons.Filled.Add, contentDescription = null)
                Text("  Add lending / borrowing")
            }
        }

        if (people.all { it.toReceive == 0.0 && it.toPay == 0.0 }) {
            item {
                EmptyState(
                    icon = Icons.Filled.Group,
                    title = "No active dues",
                    subtitle = "Record money you lent or borrowed, or split an expense with a friend from the Add screen."
                )
            }
        }

        items(people.filter { it.toReceive > 0 || it.toPay > 0 }, key = { it.contactName }) { person ->
            PersonCard(person, onOpenDebt, onSettle = { settleTarget = it })
        }
    }

    settleTarget?.let { d ->
        val isLent = d.direction == DebtDirection.I_LENT
        SettleDialog(
            title = if (isLent) "Receive from ${d.contactName}" else "Pay ${d.contactName}",
            remaining = d.amount - d.paidAmount,
            accountActionLabel = if (isLent) "Receive into account" else "Pay from account",
            accounts = accounts,
            onDismiss = { settleTarget = null },
            onConfirm = { amount, accountId ->
                vm.recordPayment(d, amount, accountId)
                settleTarget = null
            }
        )
    }
}

@Composable
private fun PersonCard(
    person: com.farhan.paisatrack.data.PeopleSummary,
    onOpenDebt: (Long) -> Unit,
    onSettle: (Debt) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    Modifier
                        .clip(RoundedCornerShape(12.dp))
                        .background(MaterialTheme.colorScheme.primaryContainer)
                        .padding(horizontal = 12.dp, vertical = 8.dp)
                ) {
                    Text(
                        person.contactName.take(2).uppercase(),
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(person.contactName, fontWeight = FontWeight.SemiBold)
                    Text(
                        if (person.net >= 0) "owes you" else "you owe",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Text(
                    Format.money(kotlin.math.abs(person.net)),
                    fontWeight = FontWeight.Bold,
                    color = if (person.net >= 0) IncomeGreen else ExpenseRed
                )
            }

            if (person.dueAfterSalary) {
                Spacer(Modifier.height(8.dp))
                AssistChip(
                    onClick = {},
                    label = { Text("Pay after salary") },
                    leadingIcon = { Icon(Icons.Filled.Schedule, contentDescription = null) },
                    colors = AssistChipDefaults.assistChipColors(
                        containerColor = MaterialTheme.colorScheme.tertiary.copy(alpha = 0.12f)
                    )
                )
            }

            person.debts.filter { !it.settled }.forEach { d ->
                Spacer(Modifier.height(10.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f).clickable { onOpenDebt(d.id) }) {
                        Text(
                            (if (d.direction == DebtDirection.I_LENT) "Lent" else "Borrowed") +
                                " · ${Format.money(d.amount - d.paidAmount)} left",
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Medium
                        )
                        if (d.note.isNotBlank()) {
                            Text(d.note, fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Text(Format.date(d.createdAt), fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    OutlinedButton(onClick = { onSettle(d) }) {
                        Text("Settle")
                    }
                }
            }
        }
    }
}

@Composable
private fun SummaryTile(modifier: Modifier, label: String, value: String, color: androidx.compose.ui.graphics.Color) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = color.copy(alpha = 0.12f))
    ) {
        Column(Modifier.padding(16.dp)) {
            Text(label, fontSize = 13.sp, color = MaterialTheme.colorScheme.onSurface)
            Text(value, fontWeight = FontWeight.Bold, fontSize = 20.sp, color = color)
        }
    }
}
