package com.farhan.paisatrack.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Event
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.farhan.paisatrack.util.Format
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZoneOffset

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DateTimeField(
    millis: Long,
    onChange: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    var showDate by remember { mutableStateOf(false) }
    var showTime by remember { mutableStateOf(false) }

    Box(modifier.fillMaxWidth()) {
        OutlinedTextField(
            value = Format.dateTime(millis),
            onValueChange = {},
            readOnly = true,
            enabled = false,
            label = { Text("Date & time") },
            leadingIcon = { Icon(Icons.Filled.Event, contentDescription = null) },
            modifier = Modifier.fillMaxWidth()
        )
        // transparent overlay to capture clicks across the whole field
        Box(Modifier.matchParentSize().clickable { showDate = true })
    }

    if (showDate) {
        val state = rememberDatePickerState(initialSelectedDateMillis = millis)
        DatePickerDialog(
            onDismissRequest = { showDate = false },
            confirmButton = {
                TextButton(onClick = {
                    showDate = false
                    val picked = state.selectedDateMillis ?: millis
                    // keep existing time, replace date
                    val old = LocalDateTime.ofInstant(Instant.ofEpochMilli(millis), ZoneId.systemDefault())
                    val newDate = LocalDateTime.ofInstant(Instant.ofEpochMilli(picked), ZoneOffset.UTC)
                    val combined = newDate.toLocalDate().atTime(old.hour, old.minute)
                    onChange(combined.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli())
                    showTime = true
                }) { Text("Next") }
            },
            dismissButton = { TextButton(onClick = { showDate = false }) { Text("Cancel") } }
        ) {
            DatePicker(state = state)
        }
    }

    if (showTime) {
        val ldt = LocalDateTime.ofInstant(Instant.ofEpochMilli(millis), ZoneId.systemDefault())
        val timeState = rememberTimePickerState(initialHour = ldt.hour, initialMinute = ldt.minute, is24Hour = false)
        AlertDialog(
            onDismissRequest = { showTime = false },
            confirmButton = {
                TextButton(onClick = {
                    showTime = false
                    val combined = ldt.toLocalDate().atTime(timeState.hour, timeState.minute)
                    onChange(combined.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli())
                }) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { showTime = false }) { Text("Cancel") } },
            text = { Box(Modifier.wrapContentSize()) { TimePicker(state = timeState) } }
        )
    }
}
