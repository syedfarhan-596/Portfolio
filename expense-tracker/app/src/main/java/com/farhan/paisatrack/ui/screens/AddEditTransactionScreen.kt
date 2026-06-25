package com.farhan.paisatrack.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
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
import com.farhan.paisatrack.data.Debt
import com.farhan.paisatrack.data.DebtDirection
import com.farhan.paisatrack.data.Txn
import com.farhan.paisatrack.data.TxnStatus
import com.farhan.paisatrack.data.TxnType
import com.farhan.paisatrack.ui.MainViewModel
import com.farhan.paisatrack.ui.components.DateTimeField
import com.farhan.paisatrack.ui.components.LabeledDropdown
import com.farhan.paisatrack.ui.components.rememberContactPicker

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditTransactionScreen(
    vm: MainViewModel,
    txnId: Long?,
    onDone: () -> Unit
) {
    val accounts by vm.accounts.collectAsStateWithLifecycle()
    val categories by vm.allCategories.collectAsStateWithLifecycle()

    var type by remember { mutableStateOf(TxnType.EXPENSE) }
    var amount by remember { mutableStateOf("") }
    var accountId by remember { mutableStateOf<Long?>(null) }
    var toAccountId by remember { mutableStateOf<Long?>(null) }
    var categoryId by remember { mutableStateOf<Long?>(null) }
    var dateTime by remember { mutableLongStateOf(System.currentTimeMillis()) }
    var note by remember { mutableStateOf("") }
    var merchant by remember { mutableStateOf("") }
    var contactName by remember { mutableStateOf<String?>(null) }
    var contactKey by remember { mutableStateOf<String?>(null) }
    var splitEnabled by remember { mutableStateOf(false) }
    var splitAmount by remember { mutableStateOf("") }
    var loaded by remember { mutableStateOf(txnId == null) }
    var existing by remember { mutableStateOf<Txn?>(null) }

    LaunchedEffect(txnId) {
        if (txnId != null) {
            vm.txnById(txnId)?.let { t ->
                existing = t
                type = t.type
                amount = if (t.amount == 0.0) "" else t.amount.toString().removeSuffix(".0")
                accountId = t.accountId
                toAccountId = t.toAccountId
                categoryId = t.categoryId
                dateTime = t.dateTime
                note = t.note
                merchant = t.merchant
                contactName = t.contactName
                contactKey = t.contactKey
            }
            loaded = true
        }
    }

    LaunchedEffect(accounts) {
        if (accountId == null && accounts.isNotEmpty()) accountId = accounts.first().id
    }
    LaunchedEffect(categories, type) {
        val opts = categories.filter { it.type == type }
        if ((categoryId == null || opts.none { it.id == categoryId }) && type != TxnType.TRANSFER) {
            categoryId = opts.firstOrNull()?.id
        }
    }

    val pickContact = rememberContactPicker { name, key ->
        contactName = name
        contactKey = key
    }

    val categoryOptions = categories.filter { it.type == type }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (txnId == null) "Add transaction" else "Edit transaction") },
                navigationIcon = {
                    IconButton(onClick = onDone) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (existing != null) {
                        IconButton(onClick = {
                            existing?.let { vm.deleteTxn(it) }
                            onDone()
                        }) {
                            Icon(Icons.Filled.Delete, contentDescription = "Delete")
                        }
                    }
                }
            )
        }
    ) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                val types = listOf(TxnType.EXPENSE, TxnType.INCOME, TxnType.TRANSFER)
                types.forEachIndexed { index, t ->
                    SegmentedButton(
                        selected = type == t,
                        onClick = { type = t },
                        shape = SegmentedButtonDefaults.itemShape(index, types.size),
                        label = { Text(t.name.lowercase().replaceFirstChar { it.uppercase() }) }
                    )
                }
            }

            OutlinedTextField(
                value = amount,
                onValueChange = { amount = it.filter { c -> c.isDigit() || c == '.' } },
                label = { Text("Amount (₹)") },
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Decimal),
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            LabeledDropdown(
                label = if (type == TxnType.TRANSFER) "From account" else "Account",
                options = accounts,
                selected = accounts.firstOrNull { it.id == accountId },
                optionLabel = { it.name },
                onSelect = { accountId = it.id }
            )

            if (type == TxnType.TRANSFER) {
                LabeledDropdown(
                    label = "To account",
                    options = accounts.filter { it.id != accountId },
                    selected = accounts.firstOrNull { it.id == toAccountId },
                    optionLabel = { it.name },
                    onSelect = { toAccountId = it.id }
                )
            } else {
                LabeledDropdown(
                    label = "Category",
                    options = categoryOptions,
                    selected = categoryOptions.firstOrNull { it.id == categoryId },
                    optionLabel = { it.name },
                    onSelect = { categoryId = it.id }
                )
            }

            DateTimeField(millis = dateTime, onChange = { dateTime = it })

            if (type != TxnType.TRANSFER) {
                OutlinedTextField(
                    value = merchant,
                    onValueChange = { merchant = it },
                    label = { Text("Merchant / paid to") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                // Contact attachment
                if (contactName == null) {
                    OutlinedButton(onClick = pickContact, modifier = Modifier.fillMaxWidth()) {
                        Icon(Icons.Filled.PersonAdd, contentDescription = null)
                        Spacer(Modifier.height(0.dp))
                        Text("  Attach a person (friend / contact)")
                    }
                } else {
                    Row(Modifier.fillMaxWidth(), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                        AssistChip(
                            onClick = pickContact,
                            label = { Text(contactName ?: "") },
                            leadingIcon = { Icon(Icons.Filled.Person, contentDescription = null) }
                        )
                        IconButton(onClick = { contactName = null; contactKey = null }) {
                            Icon(Icons.Filled.Close, contentDescription = "Remove person")
                        }
                    }
                }
            }

            OutlinedTextField(
                value = note,
                onValueChange = { note = it },
                label = { Text("Note (optional)") },
                modifier = Modifier.fillMaxWidth()
            )

            // Lending / split block
            if (type == TxnType.EXPENSE) {
                Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                    Checkbox(checked = splitEnabled, onCheckedChange = { splitEnabled = it })
                    Column {
                        Text("Someone owes me part of this", fontWeight = FontWeight.SemiBold)
                        Text(
                            "Track a friend's share / money you lent here",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                if (splitEnabled) {
                    OutlinedTextField(
                        value = splitAmount,
                        onValueChange = { splitAmount = it.filter { c -> c.isDigit() || c == '.' } },
                        label = { Text("Amount they owe me (₹)") },
                        keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    if (contactName == null) {
                        Text(
                            "Tip: attach a person above so this is linked to them.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.error
                        )
                    }
                }
            }

            Spacer(Modifier.height(4.dp))
            Button(
                onClick = {
                    val amt = amount.toDoubleOrNull() ?: return@Button
                    if (amt <= 0) return@Button
                    val accId = accountId ?: return@Button
                    if (type == TxnType.TRANSFER && toAccountId == null) return@Button

                    val txn = (existing ?: Txn(type = type, amount = amt, accountId = accId, dateTime = dateTime)).copy(
                        type = type,
                        amount = amt,
                        accountId = accId,
                        toAccountId = if (type == TxnType.TRANSFER) toAccountId else null,
                        categoryId = if (type == TxnType.TRANSFER) null else categoryId,
                        note = note,
                        merchant = merchant,
                        dateTime = dateTime,
                        status = TxnStatus.CONFIRMED,
                        contactName = contactName,
                        contactKey = contactKey
                    )
                    vm.saveTxn(txn)

                    if (splitEnabled) {
                        val owe = splitAmount.toDoubleOrNull() ?: 0.0
                        if (owe > 0) {
                            vm.saveDebt(
                                Debt(
                                    contactName = contactName ?: "Someone",
                                    contactKey = contactKey,
                                    direction = DebtDirection.I_LENT,
                                    amount = owe,
                                    note = if (note.isBlank()) merchant else note,
                                    createdAt = dateTime,
                                    accountId = accId
                                )
                            )
                        }
                    }
                    onDone()
                },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                enabled = loaded && (amount.toDoubleOrNull() ?: 0.0) > 0.0
            ) {
                Text(if (txnId == null) "Save transaction" else "Update", fontWeight = FontWeight.SemiBold)
            }
        }
    }
}
