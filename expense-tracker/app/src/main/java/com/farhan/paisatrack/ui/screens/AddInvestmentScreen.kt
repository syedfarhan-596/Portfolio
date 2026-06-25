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
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.farhan.paisatrack.data.Investment
import com.farhan.paisatrack.data.InvestmentType
import com.farhan.paisatrack.ui.MainViewModel
import com.farhan.paisatrack.ui.components.DateTimeField
import com.farhan.paisatrack.ui.components.LabeledDropdown
import com.farhan.paisatrack.ui.components.SettleDialog

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddInvestmentScreen(
    vm: MainViewModel,
    investmentId: Long?,
    onDone: () -> Unit
) {
    val accounts by vm.accounts.collectAsStateWithLifecycle()

    var name by remember { mutableStateOf("") }
    var type by remember { mutableStateOf(InvestmentType.STOCK) }
    var quantity by remember { mutableStateOf("") }
    var invested by remember { mutableStateOf("") }
    var currentValue by remember { mutableStateOf("") }
    var accountId by remember { mutableStateOf<Long?>(null) }
    var date by remember { mutableLongStateOf(System.currentTimeMillis()) }
    var note by remember { mutableStateOf("") }
    var existing by remember { mutableStateOf<Investment?>(null) }
    var showSell by remember { mutableStateOf(false) }

    LaunchedEffect(investmentId) {
        if (investmentId != null) {
            vm.investmentById(investmentId)?.let { i ->
                existing = i
                name = i.name
                type = i.type
                quantity = if (i.quantity == 0.0) "" else i.quantity.toString().removeSuffix(".0")
                invested = i.investedAmount.toString().removeSuffix(".0")
                currentValue = i.currentValue?.toString()?.removeSuffix(".0") ?: ""
                accountId = i.accountId
                date = i.createdAt
                note = i.note
            }
        }
    }
    LaunchedEffect(accounts) {
        if (accountId == null && accounts.isNotEmpty()) accountId = accounts.first().id
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (investmentId == null) "Add investment" else "Edit investment") },
                navigationIcon = {
                    IconButton(onClick = onDone) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") }
                },
                actions = {
                    if (existing != null) {
                        IconButton(onClick = { existing?.let { vm.deleteInvestment(it) }; onDone() }) {
                            Icon(Icons.Filled.Delete, contentDescription = "Delete")
                        }
                    }
                }
            )
        }
    ) { padding ->
        Column(
            Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Name (e.g. Reliance, Nifty 50)") }, singleLine = true, modifier = Modifier.fillMaxWidth())

            LabeledDropdown(
                label = "Type",
                options = InvestmentType.entries.toList(),
                selected = type,
                optionLabel = { it.name.lowercase().replaceFirstChar { c -> c.uppercase() }.replace("_", " ") },
                onSelect = { type = it }
            )

            OutlinedTextField(
                value = invested,
                onValueChange = { invested = it.filter { c -> c.isDigit() || c == '.' } },
                label = { Text("Amount invested (₹)") },
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Decimal),
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = quantity,
                onValueChange = { quantity = it.filter { c -> c.isDigit() || c == '.' } },
                label = { Text("Quantity / units (optional)") },
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Decimal),
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = currentValue,
                onValueChange = { currentValue = it.filter { c -> c.isDigit() || c == '.' } },
                label = { Text("Current value (optional, for returns)") },
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Decimal),
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            if (existing == null) {
                LabeledDropdown(
                    label = "Pay from account",
                    options = accounts,
                    selected = accounts.firstOrNull { it.id == accountId },
                    optionLabel = { it.name },
                    onSelect = { accountId = it.id }
                )
                DateTimeField(millis = date, onChange = { date = it })
            }

            OutlinedTextField(value = note, onValueChange = { note = it }, label = { Text("Note (optional)") }, modifier = Modifier.fillMaxWidth())

            Spacer(Modifier.height(4.dp))
            Button(
                onClick = {
                    val inv = invested.toDoubleOrNull() ?: return@Button
                    if (inv <= 0 || name.isBlank()) return@Button
                    val qty = quantity.toDoubleOrNull() ?: 0.0
                    val cur = currentValue.toDoubleOrNull()
                    val e = existing
                    if (e == null) {
                        vm.buyInvestment(name, type, qty, inv, accountId, note, date, cur)
                    } else {
                        vm.editInvestment(e, name, type, qty, inv, cur, note)
                    }
                    onDone()
                },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                enabled = name.isNotBlank() && (invested.toDoubleOrNull() ?: 0.0) > 0.0
            ) {
                Text(if (investmentId == null) "Add investment" else "Update", fontWeight = FontWeight.SemiBold)
            }

            existing?.let { e ->
                if (!e.sold) {
                    OutlinedButton(onClick = { showSell = true }, modifier = Modifier.fillMaxWidth()) {
                        Text("Sell / Redeem")
                    }
                }
            }
        }
    }

    if (showSell) {
        val e = existing
        SettleDialog(
            title = "Sell ${e?.name ?: ""}",
            remaining = e?.currentValue ?: e?.investedAmount ?: 0.0,
            accountActionLabel = "Credit proceeds to",
            accounts = accounts,
            onDismiss = { showSell = false },
            onConfirm = { amount, accId ->
                e?.let { vm.sellInvestment(it, amount, accId) }
                showSell = false
                onDone()
            }
        )
    }
}
