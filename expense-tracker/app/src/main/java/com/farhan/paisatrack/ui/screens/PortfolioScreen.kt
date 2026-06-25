package com.farhan.paisatrack.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
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
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
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
import com.farhan.paisatrack.data.Investment
import com.farhan.paisatrack.ui.MainViewModel
import com.farhan.paisatrack.ui.components.EmptyState
import com.farhan.paisatrack.ui.theme.ExpenseRed
import com.farhan.paisatrack.ui.theme.IncomeGreen
import com.farhan.paisatrack.ui.theme.Mint
import com.farhan.paisatrack.ui.theme.Violet
import com.farhan.paisatrack.util.Format

@Composable
fun PortfolioScreen(
    vm: MainViewModel,
    onAdd: () -> Unit,
    onOpen: (Long) -> Unit
) {
    val port by vm.portfolio.collectAsStateWithLifecycle()
    val investments by vm.investments.collectAsStateWithLifecycle()
    val active = investments.filter { !it.sold }
    val sold = investments.filter { it.sold }

    LazyColumn(
        modifier = Modifier.fillMaxWidth(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp, 8.dp, 16.dp, 96.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text("Portfolio", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        }
        item { PortfolioHeader(port.invested, port.currentValue, port.gain, port.gainPct) }

        if (active.isEmpty()) {
            item {
                EmptyState(
                    icon = Icons.AutoMirrored.Filled.TrendingUp,
                    title = "No investments yet",
                    subtitle = "Tap + to add a stock, mutual fund, gold or any asset. The amount is deducted from the account you choose."
                )
            }
        } else {
            item { Text("Holdings", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold) }
            items(active, key = { "a${it.id}" }) { inv ->
                HoldingCard(inv) { onOpen(inv.id) }
            }
        }

        if (sold.isNotEmpty()) {
            item { Text("Sold / Redeemed", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold) }
            items(sold, key = { "s${it.id}" }) { inv ->
                HoldingCard(inv) { onOpen(inv.id) }
            }
        }
    }
}

@Composable
private fun PortfolioHeader(invested: Double, current: Double, gain: Double, gainPct: Double) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent)
    ) {
        Box(
            Modifier
                .background(Brush.linearGradient(listOf(Mint, Violet)))
                .padding(20.dp)
        ) {
            Column {
                Text("Current value", color = Color.White.copy(alpha = 0.85f), fontSize = 13.sp)
                Spacer(Modifier.height(6.dp))
                Text(Format.money(current), color = Color.White, fontSize = 32.sp, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(16.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Column {
                        Text("Invested", color = Color.White.copy(alpha = 0.8f), fontSize = 12.sp)
                        Text(Format.money(invested), color = Color.White, fontWeight = FontWeight.SemiBold)
                    }
                    Column(horizontalAlignment = Alignment.End) {
                        Text("Returns", color = Color.White.copy(alpha = 0.8f), fontSize = 12.sp)
                        Text(
                            "${if (gain >= 0) "+" else ""}${Format.money(gain)} (${"%.1f".format(gainPct)}%)",
                            color = Color.White,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun HoldingCard(inv: Investment, onClick: () -> Unit) {
    val current = inv.currentValue ?: inv.investedAmount
    val gain = current - inv.investedAmount
    Card(
        modifier = Modifier.fillMaxWidth().clickable { onClick() },
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(inv.name, fontWeight = FontWeight.SemiBold)
                Text(
                    inv.type.name.lowercase().replaceFirstChar { it.uppercase() }.replace("_", " ") +
                        (if (inv.quantity > 0) " · ${inv.quantity.toString().removeSuffix(".0")} units" else ""),
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(Format.money(current), fontWeight = FontWeight.Bold)
                AnimatedVisibility(visible = !inv.sold, enter = fadeIn(), exit = fadeOut()) {
                    Text(
                        "${if (gain >= 0) "+" else ""}${Format.money(gain)}",
                        fontSize = 12.sp,
                        color = if (gain >= 0) IncomeGreen else ExpenseRed
                    )
                }
            }
        }
    }
}
