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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.farhan.paisatrack.data.Debt
import com.farhan.paisatrack.data.DebtDirection
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.farhan.paisatrack.ui.MainViewModel
import com.farhan.paisatrack.ui.components.DateTimeField
import com.farhan.paisatrack.ui.components.LabeledDropdown
import com.farhan.paisatrack.ui.components.rememberContactPicker

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddDebtScreen(
    vm: MainViewModel,
    debtId: Long?,
    onDone: () -> Unit
) {
    var direction by remember { mutableStateOf(DebtDirection.I_LENT) }
    var amount by remember { mutableStateOf("") }
    var note by remember { mutableStateOf("") }
    var contactName by remember { mutableStateOf<String?>(null) }
    var contactKey by remember { mutableStateOf<String?>(null) }
    var createdAt by remember { mutableLongStateOf(System.currentTimeMillis()) }
    var dueAfterSalary by remember { mutableStateOf(false) }
    var existing by remember { mutableStateOf<Debt?>(null) }
    var paymentText by remember { mutableStateOf("") }
    val accounts by vm.accounts.collectAsStateWithLifecycle()
    var payAccountId by remember { mutableStateOf<Long?>(null) }

    LaunchedEffect(debtId) {
        if (debtId != null) {
            vm.debtById(debtId)?.let { d ->
                existing = d
                direction = d.direction
                amount = d.amount.toString().removeSuffix(".0")
                note = d.note
                contactName = d.contactName
                contactKey = d.contactKey
                createdAt = d.createdAt
                dueAfterSalary = d.dueAfterSalary
            }
        }
    }

    val pickContact = rememberContactPicker { name, key ->
        contactName = name
        contactKey = key
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (debtId == null) "Add lending / borrowing" else "Edit entry") },
                navigationIcon = {
                    IconButton(onClick = onDone) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (existing != null) {
                        IconButton(onClick = {
                            existing?.let { vm.deleteDebt(it) }
                            onDone()
                        }) { Icon(Icons.Filled.Delete, contentDescription = "Delete") }
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
                val dirs = listOf(DebtDirection.I_LENT to "I lent (they owe me)", DebtDirection.I_BORROWED to "I borrowed (I owe)")
                dirs.forEachIndexed { index, (d, label) ->
                    SegmentedButton(
                        selected = direction == d,
                        onClick = { direction = d },
                        shape = SegmentedButtonDefaults.itemShape(index, dirs.size),
                        label = { Text(label, maxLines = 2) }
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

            if (contactName == null) {
                OutlinedButton(onClick = pickContact, modifier = Modifier.fillMaxWidth()) {
                    Icon(Icons.Filled.PersonAdd, contentDescription = null)
                    Text("  Pick person from contacts")
                }
            } else {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    AssistChip(
                        onClick = pickContact,
                        label = { Text(contactName ?: "") },
                        leadingIcon = { Icon(Icons.Filled.Person, contentDescription = null) }
                    )
                    IconButton(onClick = { contactName = null; contactKey = null }) {
                        Icon(Icons.Filled.Close, contentDescription = "Remove")
                    }
                }
            }
            OutlinedTextField(
                value = contactName ?: "",
                onValueChange = { contactName = it.ifBlank { null } },
                label = { Text("Or type a name") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            DateTimeField(millis = createdAt, onChange = { createdAt = it })

            OutlinedTextField(
                value = note,
                onValueChange = { note = it },
                label = { Text("What is it for? (note)") },
                modifier = Modifier.fillMaxWidth()
            )

            Row(verticalAlignment = Alignment.CenterVertically) {
                Checkbox(checked = dueAfterSalary, onCheckedChange = { dueAfterSalary = it })
                Text("Remind / pay after salary")
            }

            existing?.let { d ->
                Text(
                    "Paid so far: ${com.farhan.paisatrack.util.Format.money(d.paidAmount)} of ${com.farhan.paisatrack.util.Format.money(d.amount)}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                LabeledDropdown(
                    label = if (d.direction == DebtDirection.I_LENT) "Receive into account" else "Pay from account",
                    options = accounts,
                    selected = accounts.firstOrNull { it.id == (payAccountId ?: accounts.firstOrNull()?.id) },
                    optionLabel = { it.name },
                    onSelect = { payAccountId = it.id }
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    OutlinedTextField(
                        value = paymentText,
                        onValueChange = { paymentText = it.filter { c -> c.isDigit() || c == '.' } },
                        label = { Text("Record payment") },
                        keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        singleLine = true,
                        modifier = Modifier.weight(1f)
                    )
                    Button(onClick = {
                        val p = paymentText.toDoubleOrNull() ?: 0.0
                        val acc = payAccountId ?: accounts.firstOrNull()?.id
                        if (p > 0) { vm.recordPayment(d, p, acc); onDone() }
                    }) { Text("Add") }
                }
            }

            Spacer(Modifier.height(4.dp))
            Button(
                onClick = {
                    val amt = amount.toDoubleOrNull() ?: return@Button
                    if (amt <= 0) return@Button
                    val name = contactName?.takeIf { it.isNotBlank() } ?: "Someone"
                    val debt = (existing ?: Debt(
                        contactName = name,
                        direction = direction,
                        amount = amt,
                        createdAt = createdAt
                    )).copy(
                        contactName = name,
                        contactKey = contactKey,
                        direction = direction,
                        amount = amt,
                        note = note,
                        createdAt = createdAt,
                        dueAfterSalary = dueAfterSalary
                    )
                    vm.saveDebt(debt)
                    onDone()
                },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                enabled = (amount.toDoubleOrNull() ?: 0.0) > 0.0
            ) {
                Text(if (debtId == null) "Save" else "Update", fontWeight = FontWeight.SemiBold)
            }
        }
    }
}
