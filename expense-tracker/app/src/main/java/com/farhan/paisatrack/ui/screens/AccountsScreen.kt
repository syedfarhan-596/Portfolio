package com.farhan.paisatrack.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.farhan.paisatrack.data.Account
import com.farhan.paisatrack.data.AccountType
import com.farhan.paisatrack.ui.MainViewModel
import com.farhan.paisatrack.ui.components.ColorPickerRow
import com.farhan.paisatrack.ui.components.IconBadge
import com.farhan.paisatrack.ui.components.IconPickerRow
import com.farhan.paisatrack.ui.components.LabeledDropdown
import com.farhan.paisatrack.ui.components.SectionCard
import com.farhan.paisatrack.util.Format
import com.farhan.paisatrack.util.IconMap

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountsScreen(vm: MainViewModel, onBack: () -> Unit, onOpenAccount: (Long) -> Unit) {
    val balances by vm.balances.collectAsStateWithLifecycle()
    var editing by remember { mutableStateOf<Account?>(null) }
    var showDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Accounts") },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { editing = null; showDialog = true }) {
                Icon(Icons.Filled.Add, contentDescription = "Add account")
            }
        }
    ) { padding ->
        LazyColumn(
            Modifier.fillMaxSize().padding(padding),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp, 8.dp, 16.dp, 96.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            items(balances, key = { it.account.id }) { ab ->
                SectionCard(modifier = Modifier.clickable { onOpenAccount(ab.account.id) }) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        IconBadge(IconMap.icon(ab.account.icon), IconMap.parseColor(ab.account.colorHex))
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text(ab.account.name, fontWeight = FontWeight.SemiBold)
                            Text(
                                ab.account.type.name.lowercase().replaceFirstChar { it.uppercase() }.replace("_", " "),
                                fontSize = 12.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        val isCard = ab.account.type == AccountType.CREDIT_CARD
                        Text(
                            Format.money(if (isCard) -ab.balance else ab.balance),
                            fontWeight = FontWeight.Bold,
                            color = if (isCard && ab.balance > 0) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface
                        )
                        IconButton(onClick = { editing = ab.account; showDialog = true }) {
                            Icon(Icons.Filled.Edit, contentDescription = "Edit ${ab.account.name}")
                        }
                    }
                }
            }
        }
    }

    if (showDialog) {
        AccountEditorDialog(
            account = editing,
            onDismiss = { showDialog = false },
            onSave = { vm.saveAccount(it); showDialog = false },
            onDelete = editing?.let { acc -> { vm.deleteAccount(acc); showDialog = false } }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountEditorDialog(
    account: Account?,
    onDismiss: () -> Unit,
    onSave: (Account) -> Unit,
    onDelete: (() -> Unit)?
) {
    var name by remember { mutableStateOf(account?.name ?: "") }
    var type by remember { mutableStateOf(account?.type ?: AccountType.BANK) }
    var opening by remember { mutableStateOf(account?.openingBalance?.toString()?.removeSuffix(".0") ?: "") }
    var color by remember { mutableStateOf(account?.colorHex ?: IconMap.palette.first()) }
    var icon by remember { mutableStateOf(account?.icon ?: "account_balance") }
    var includeInTotal by remember { mutableStateOf(account?.includeInTotal ?: true) }

    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(
                onClick = {
                    if (name.isBlank()) return@TextButton
                    onSave(
                        (account ?: Account(name = name, type = type)).copy(
                            name = name,
                            type = type,
                            openingBalance = opening.toDoubleOrNull() ?: 0.0,
                            colorHex = color,
                            icon = icon,
                            includeInTotal = includeInTotal
                        )
                    )
                }
            ) { Text("Save") }
        },
        dismissButton = {
            Row {
                if (onDelete != null) {
                    TextButton(onClick = onDelete) { Text("Delete", color = MaterialTheme.colorScheme.error) }
                }
                TextButton(onClick = onDismiss) { Text("Cancel") }
            }
        },
        title = { Text(if (account == null) "New account" else "Edit account") },
        text = {
            Column(
                Modifier.verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Name") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                LabeledDropdown(
                    label = "Type",
                    options = AccountType.entries.toList(),
                    selected = type,
                    optionLabel = { it.name.lowercase().replaceFirstChar { c -> c.uppercase() }.replace("_", " ") },
                    onSelect = { type = it }
                )
                OutlinedTextField(
                    value = opening,
                    onValueChange = { opening = it.filter { c -> c.isDigit() || c == '.' || c == '-' } },
                    label = { Text(if (type == AccountType.CREDIT_CARD) "Current outstanding owed (₹)" else "Opening balance (₹)") },
                    keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Text("Color", fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                ColorPickerRow(selected = color, onSelect = { color = it })
                Text("Icon", fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                IconPickerRow(selected = icon, tint = IconMap.parseColor(color), onSelect = { icon = it })
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Switch(checked = includeInTotal, onCheckedChange = { includeInTotal = it })
                    Spacer(Modifier.width(8.dp))
                    Text("Include in available balance")
                }
            }
        }
    )
}
