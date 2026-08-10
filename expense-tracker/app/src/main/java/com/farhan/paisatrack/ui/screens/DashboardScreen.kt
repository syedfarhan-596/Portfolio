package com.farhan.paisatrack.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.ExperimentalFoundationApi
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
import androidx.compose.material.icons.automirrored.filled.TrendingDown
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.farhan.paisatrack.data.AccountType
import com.farhan.paisatrack.data.TxnType
import com.farhan.paisatrack.ui.MainViewModel
import com.farhan.paisatrack.ui.components.IconBadge
import com.farhan.paisatrack.ui.components.SectionCard
import com.farhan.paisatrack.ui.theme.ExpenseRed
import com.farhan.paisatrack.ui.theme.IncomeGreen
import com.farhan.paisatrack.ui.theme.Violet
import com.farhan.paisatrack.ui.theme.VioletDark
import com.farhan.paisatrack.util.Format
import com.farhan.paisatrack.util.IconMap

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun DashboardScreen(
    vm: MainViewModel,
    onAddTxn: () -> Unit,
    onOpenTxn: (Long) -> Unit,
    onSeeAllTxns: () -> Unit,
    onSeePeople: () -> Unit,
    onOpenSettings: () -> Unit,
    onPayCard: (Long) -> Unit,
    onOpenAccount: (Long) -> Unit
) {
    val dash by vm.dashboard.collectAsStateWithLifecycle()
    val txns by vm.confirmedTxns.collectAsStateWithLifecycle()
    val pending by vm.pendingTxns.collectAsStateWithLifecycle()
    val accounts by vm.accounts.collectAsStateWithLifecycle()
    val categories by vm.allCategories.collectAsStateWithLifecycle()

    val catById = categories.associateBy { it.id }
    val accById = accounts.associateBy { it.id }

    LazyColumn(
        modifier = Modifier.fillMaxWidth(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp, 8.dp, 16.dp, 96.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(
                        "Hello, Farhan 👋",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text("Your money at a glance", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                }
                IconButton(onClick = onOpenSettings) {
                    Icon(Icons.Filled.Settings, contentDescription = "Settings")
                }
            }
        }

        item { NetWorthCard(dash) }

        item {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatTile(
                    modifier = Modifier.weight(1f),
                    label = "To receive",
                    value = Format.money(dash.toReceive),
                    color = IncomeGreen,
                    icon = Icons.AutoMirrored.Filled.TrendingUp,
                    onClick = onSeePeople
                )
                StatTile(
                    modifier = Modifier.weight(1f),
                    label = "To pay",
                    value = Format.money(dash.toPay),
                    color = ExpenseRed,
                    icon = Icons.AutoMirrored.Filled.TrendingDown,
                    onClick = onSeePeople
                )
            }
        }

        item {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatTile(
                    modifier = Modifier.weight(1f),
                    label = "This month spent",
                    value = Format.money(dash.monthExpense),
                    color = ExpenseRed,
                    icon = Icons.AutoMirrored.Filled.TrendingDown
                )
                StatTile(
                    modifier = Modifier.weight(1f),
                    label = "This month in",
                    value = Format.money(dash.monthIncome),
                    color = IncomeGreen,
                    icon = Icons.AutoMirrored.Filled.TrendingUp
                )
            }
        }

        if (pending.isNotEmpty()) {
            item {
                Text("Detected from SMS — confirm", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            }
            items(pending, key = { "p${it.id}" }) { t ->
                PendingTxnCard(
                    modifier = Modifier.animateItemPlacement(),
                    title = if (t.merchant.isNotBlank()) t.merchant else "Unknown",
                    subtitle = "${Format.dateTime(t.dateTime)}  ·  tap to categorize",
                    amount = t.amount,
                    isIncome = t.type == TxnType.INCOME,
                    onConfirm = { onOpenTxn(t.id) },
                    onDismiss = { vm.dismissPending(t) }
                )
            }
        }

        item {
            SectionHeader("Accounts", actionLabel = null, onAction = null)
        }
        items(dash.balances, key = { "acc${it.account.id}" }) { ab ->
            AccountRow(
                modifier = Modifier.animateItemPlacement(),
                accountId = ab.account.id,
                name = ab.account.name,
                icon = IconMap.icon(ab.account.icon),
                color = IconMap.parseColor(ab.account.colorHex),
                balance = ab.balance,
                isCredit = ab.account.type == AccountType.CREDIT_CARD,
                onPayCard = onPayCard,
                onClick = onOpenAccount
            )
        }

        item {
            SectionHeader("Recent activity", actionLabel = "See all", onAction = onSeeAllTxns)
        }
        if (txns.isEmpty()) {
            item {
                SectionCard {
                    Text(
                        "No transactions yet. Tap + to add your first one, or scan your SMS inbox in Settings.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        } else {
            items(txns.take(6), key = { "t${it.id}" }) { t ->
                val cat = t.categoryId?.let { catById[it] }
                TransactionRow(
                    modifier = Modifier.animateItemPlacement(),
                    title = when {
                        t.contactName != null -> t.contactName!!
                        t.merchant.isNotBlank() -> t.merchant
                        cat != null -> cat.name
                        else -> t.type.name.lowercase().replaceFirstChar { it.uppercase() }
                    },
                    subtitle = buildString {
                        append(cat?.name ?: t.type.name.lowercase().replaceFirstChar { it.uppercase() })
                        accById[t.accountId]?.let { append(" · ${it.name}") }
                    },
                    note = t.note,
                    amount = t.amount,
                    type = t.type,
                    icon = IconMap.icon(cat?.icon ?: "category"),
                    color = IconMap.parseColor(cat?.colorHex ?: "#636E72"),
                    dateText = Format.day(t.dateTime),
                    onClick = { onOpenTxn(t.id) }
                )
            }
        }
    }
}

@Composable
private fun NetWorthCard(dash: com.farhan.paisatrack.ui.DashboardState) {
    val animatedLiquid by animateFloatAsState(
        targetValue = dash.liquidTotal.toFloat(),
        animationSpec = tween(700),
        label = "liquid"
    )
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent)
    ) {
        Box(
            Modifier
                .background(Brush.linearGradient(listOf(Violet, VioletDark)))
                .padding(20.dp)
        ) {
            Column {
                Text("Available balance (cash + banks)", color = Color.White.copy(alpha = 0.85f), fontSize = 13.sp)
                Spacer(Modifier.height(6.dp))
                Text(
                    Format.money(animatedLiquid.toDouble()),
                    color = Color.White,
                    fontSize = 34.sp,
                    fontWeight = FontWeight.Bold
                )
                Spacer(Modifier.height(16.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    MiniStat("Net worth", Format.moneyShort(dash.netWorth))
                    MiniStat("Invested", Format.moneyShort(dash.investedValue))
                    MiniStat("Card due", Format.moneyShort(dash.creditOutstanding))
                }
            }
        }
    }
}

@Composable
private fun MiniStat(label: String, value: String) {
    Column {
        Text(label, color = Color.White.copy(alpha = 0.8f), fontSize = 12.sp)
        Text(value, color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
    }
}

@Composable
private fun StatTile(
    modifier: Modifier = Modifier,
    label: String,
    value: String,
    color: Color,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: (() -> Unit)? = null
) {
    Card(
        modifier = modifier.then(if (onClick != null) Modifier.clickable { onClick() } else Modifier),
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

@Composable
fun SectionHeader(title: String, actionLabel: String?, onAction: (() -> Unit)?) {
    Row(
        Modifier.fillMaxWidth().padding(top = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        if (actionLabel != null && onAction != null) {
            Text(
                actionLabel,
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.clickable { onAction() }
            )
        }
    }
}

@Composable
private fun AccountRow(
    modifier: Modifier = Modifier,
    accountId: Long,
    name: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    color: Color,
    balance: Double,
    isCredit: Boolean,
    onPayCard: (Long) -> Unit,
    onClick: (Long) -> Unit
) {
    SectionCard(modifier = modifier.clickable { onClick(accountId) }) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconBadge(icon = icon, tint = color)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(name, fontWeight = FontWeight.SemiBold)
                Text(
                    if (isCredit) "Outstanding" else "Balance",
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    Format.money(if (isCredit) -balance else balance),
                    fontWeight = FontWeight.Bold,
                    color = if (isCredit && balance > 0) ExpenseRed else MaterialTheme.colorScheme.onSurface
                )
                if (isCredit) {
                    TextButton(
                        onClick = { onPayCard(accountId) },
                        contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 8.dp, vertical = 0.dp)
                    ) {
                        Text("Pay bill", fontSize = 13.sp)
                    }
                }
            }
        }
    }
}

@Composable
private fun PendingTxnCard(
    modifier: Modifier = Modifier,
    title: String,
    subtitle: String,
    amount: Double,
    isIncome: Boolean,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    Card(
        modifier = modifier.fillMaxWidth().clickable { onConfirm() },
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
    ) {
        Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onPrimaryContainer)
                Text(subtitle, fontSize = 12.sp, color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f))
            }
            Text(
                (if (isIncome) "+" else "-") + Format.money(amount),
                fontWeight = FontWeight.Bold,
                color = if (isIncome) IncomeGreen else ExpenseRed
            )
            IconButton(onClick = onConfirm) {
                Icon(Icons.Filled.CheckCircle, contentDescription = "Confirm", tint = IncomeGreen)
            }
            IconButton(onClick = onDismiss) {
                Icon(Icons.Filled.Close, contentDescription = "Dismiss", tint = MaterialTheme.colorScheme.onPrimaryContainer)
            }
        }
    }
}
