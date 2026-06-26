package com.farhan.paisatrack.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.farhan.paisatrack.data.AccountType
import com.farhan.paisatrack.ui.MainViewModel
import com.farhan.paisatrack.ui.components.LabeledDropdown
import com.farhan.paisatrack.ui.components.SectionCard
import com.farhan.paisatrack.util.Format

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PayCreditCardScreen(
    vm: MainViewModel,
    cardId: Long?,
    onDone: () -> Unit
) {
    val balances by vm.balances.collectAsStateWithLifecycle()
    val accounts by vm.accounts.collectAsStateWithLifecycle()

    val cards = accounts.filter { it.type == AccountType.CREDIT_CARD }
    val payFrom = accounts.filter { it.type != AccountType.CREDIT_CARD }

    var selectedCardId by remember(cards) { mutableStateOf(cardId ?: cards.firstOrNull()?.id) }
    var fromAccountId by remember(payFrom) { mutableStateOf(payFrom.firstOrNull()?.id) }
    var bankAmount by remember { mutableStateOf("") }
    var pointsAmount by remember { mutableStateOf("") }

    val outstanding = balances.firstOrNull { it.account.id == selectedCardId }?.balance ?: 0.0

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Pay credit card bill") },
                navigationIcon = {
                    IconButton(onClick = onDone) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") }
                }
            )
        }
    ) { padding ->
        Column(
            Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            if (cards.size > 1) {
                LabeledDropdown(
                    label = "Credit card",
                    options = cards,
                    selected = cards.firstOrNull { it.id == selectedCardId },
                    optionLabel = { it.name },
                    onSelect = { selectedCardId = it.id }
                )
            }

            SectionCard {
                Text("Current outstanding", fontSize = 13.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(Format.money(outstanding), fontWeight = FontWeight.Bold, fontSize = 24.sp, color = MaterialTheme.colorScheme.primary)
            }

            Text("Pay from bank / cash", fontWeight = FontWeight.SemiBold)
            LabeledDropdown(
                label = "Account",
                options = payFrom,
                selected = payFrom.firstOrNull { it.id == fromAccountId },
                optionLabel = { it.name },
                onSelect = { fromAccountId = it.id }
            )
            androidx.compose.material3.OutlinedTextField(
                value = bankAmount,
                onValueChange = { bankAmount = it.filter { c -> c.isDigit() || c == '.' } },
                label = { Text("Amount from account (₹)") },
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Decimal),
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            Text("Pay with reward points", fontWeight = FontWeight.SemiBold)
            androidx.compose.material3.OutlinedTextField(
                value = pointsAmount,
                onValueChange = { pointsAmount = it.filter { c -> c.isDigit() || c == '.' } },
                label = { Text("Amount paid via points (₹ value)") },
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Decimal),
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            val bank = bankAmount.toDoubleOrNull() ?: 0.0
            val points = pointsAmount.toDoubleOrNull() ?: 0.0
            if (bank + points > 0) {
                Text(
                    "Total payment: ${Format.money(bank + points)}",
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(Modifier.height(4.dp))
            Button(
                onClick = {
                    val card = selectedCardId ?: return@Button
                    vm.payCreditCard(card, fromAccountId, bank, points)
                    onDone()
                },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                enabled = selectedCardId != null && (bank + points) > 0.0
            ) {
                Text("Pay bill", fontWeight = FontWeight.SemiBold)
            }
        }
    }
}
