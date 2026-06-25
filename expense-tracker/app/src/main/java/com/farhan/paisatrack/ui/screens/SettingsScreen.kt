package com.farhan.paisatrack.ui.screens

import android.Manifest
import android.os.Build
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Category
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Sms
import androidx.compose.material.icons.filled.Wallet
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.farhan.paisatrack.ui.MainViewModel
import com.farhan.paisatrack.ui.components.IconBadge
import com.farhan.paisatrack.ui.components.LabeledDropdown
import com.farhan.paisatrack.ui.components.SectionCard
import com.farhan.paisatrack.ui.theme.Amber
import com.farhan.paisatrack.ui.theme.Mint
import com.farhan.paisatrack.ui.theme.Sky
import com.farhan.paisatrack.ui.theme.Violet

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    vm: MainViewModel,
    isDark: Boolean,
    onToggleTheme: () -> Unit,
    onManageAccounts: () -> Unit,
    onManageCategories: () -> Unit
) {
    val context = LocalContext.current
    val accounts by vm.accounts.collectAsStateWithLifecycle()

    var reminderOn by remember { mutableStateOf(vm.prefs.reminderEnabled) }
    var reminderHour by remember { mutableIntStateOf(vm.prefs.reminderHour) }
    var reminderMinute by remember { mutableIntStateOf(vm.prefs.reminderMinute) }
    var smsOn by remember { mutableStateOf(vm.prefs.smsCaptureEnabled) }
    var defaultUpi by remember { mutableStateOf(vm.prefs.defaultUpiAccountId) }
    var showTimeDialog by remember { mutableStateOf(false) }

    val notifPermLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { }
    val smsPermLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { result ->
        val granted = result.values.all { it }
        if (granted) {
            vm.importSmsInbox { added ->
                Toast.makeText(context, "Imported $added transactions from SMS", Toast.LENGTH_LONG).show()
            }
        } else {
            Toast.makeText(context, "SMS permission needed to read transactions", Toast.LENGTH_SHORT).show()
        }
    }

    Column(
        Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text("Settings", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)

        // Daily reminder
        SectionCard {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconBadge(Icons.Filled.Notifications, Violet)
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text("Daily reminder", fontWeight = FontWeight.SemiBold)
                    Text("Nudge me to log expenses", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Switch(checked = reminderOn, onCheckedChange = {
                    reminderOn = it
                    vm.setReminder(it, reminderHour, reminderMinute)
                    if (it && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        notifPermLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                    }
                })
            }
            if (reminderOn) {
                Spacer(Modifier.height(8.dp))
                Row(
                    Modifier.fillMaxWidth().clickable { showTimeDialog = true },
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Reminder time")
                    Text(
                        "%02d:%02d".format(reminderHour, reminderMinute),
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }

        // SMS capture
        SectionCard {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconBadge(Icons.Filled.Sms, Mint)
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text("Auto-capture from SMS", fontWeight = FontWeight.SemiBold)
                    Text("Detect UPI / bank transactions automatically", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Switch(checked = smsOn, onCheckedChange = {
                    smsOn = it
                    vm.setSmsCapture(it)
                    if (it) {
                        smsPermLauncherRequestOnly(smsPermLauncher)
                    }
                })
            }
            Spacer(Modifier.height(10.dp))
            Row(
                Modifier.fillMaxWidth().clickable {
                    smsPermLauncher.launch(arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS))
                },
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Filled.Download, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                Spacer(Modifier.width(8.dp))
                Text("Scan SMS inbox now", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.SemiBold)
            }
        }

        // Default UPI account
        SectionCard {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconBadge(Icons.Filled.Wallet, Sky)
                Spacer(Modifier.width(12.dp))
                Text("Default account for detected UPI", fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            }
            Spacer(Modifier.height(10.dp))
            LabeledDropdown(
                label = "Account",
                options = accounts,
                selected = accounts.firstOrNull { it.id == defaultUpi },
                optionLabel = { it.name },
                onSelect = {
                    defaultUpi = it.id
                    vm.setDefaultUpiAccount(it.id)
                }
            )
        }

        // Manage
        NavRow("Manage accounts", "Add or edit your banks, cash & cards", Icons.Filled.Wallet, Amber, onManageAccounts)
        NavRow("Manage categories", "Customize your expense & income types", Icons.Filled.Category, Violet, onManageCategories)

        // Theme
        SectionCard {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconBadge(Icons.Filled.DarkMode, MaterialTheme.colorScheme.onSurface)
                Spacer(Modifier.width(12.dp))
                Text("Dark theme", fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                Switch(checked = isDark, onCheckedChange = { onToggleTheme() })
            }
        }

        SectionCard {
            Text("🔒 100% on your device", fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(4.dp))
            Text(
                "All your data is stored locally in this app. Nothing is uploaded to any server. " +
                    "If you uninstall the app, your data is removed — keep a device backup if needed.",
                fontSize = 13.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Spacer(Modifier.height(80.dp))
    }

    if (showTimeDialog) {
        val state = rememberTimePickerState(initialHour = reminderHour, initialMinute = reminderMinute, is24Hour = true)
        AlertDialog(
            onDismissRequest = { showTimeDialog = false },
            confirmButton = {
                TextButton(onClick = {
                    reminderHour = state.hour
                    reminderMinute = state.minute
                    vm.setReminder(reminderOn, reminderHour, reminderMinute)
                    showTimeDialog = false
                }) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { showTimeDialog = false }) { Text("Cancel") } },
            text = { Box(Modifier.wrapContentSize()) { TimePicker(state = state) } }
        )
    }
}

private fun smsPermLauncherRequestOnly(
    launcher: androidx.activity.result.ActivityResultLauncher<Array<String>>
) {
    launcher.launch(arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS))
}

@Composable
private fun NavRow(
    title: String,
    subtitle: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    color: androidx.compose.ui.graphics.Color,
    onClick: () -> Unit
) {
    SectionCard(modifier = Modifier.clickable { onClick() }) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconBadge(icon, color)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.SemiBold)
                Text(subtitle, fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
