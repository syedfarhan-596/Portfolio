package com.farhan.paisatrack.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.farhan.paisatrack.data.Account
import com.farhan.paisatrack.util.Format

@Composable
fun SettleDialog(
    title: String,
    remaining: Double,
    accountActionLabel: String,
    accounts: List<Account>,
    onDismiss: () -> Unit,
    onConfirm: (amount: Double, accountId: Long?) -> Unit
) {
    var amount by remember { mutableStateOf(if (remaining > 0) remaining.toString().removeSuffix(".0") else "") }
    var accountId by remember { mutableStateOf(accounts.firstOrNull()?.id) }

    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = {
                val a = amount.toDoubleOrNull() ?: return@TextButton
                if (a > 0) onConfirm(a, accountId)
            }) { Text("Confirm") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
        title = { Text(title) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Remaining: ${Format.money(remaining)}", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(selected = false, onClick = { amount = (remaining * 0.5).toString().removeSuffix(".0") }, label = { Text("50%") })
                    FilterChip(selected = false, onClick = { amount = remaining.toString().removeSuffix(".0") }, label = { Text("Full (100%)") })
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
                    label = accountActionLabel,
                    options = accounts,
                    selected = accounts.firstOrNull { it.id == accountId },
                    optionLabel = { it.name },
                    onSelect = { accountId = it.id }
                )
            }
        }
    )
}
