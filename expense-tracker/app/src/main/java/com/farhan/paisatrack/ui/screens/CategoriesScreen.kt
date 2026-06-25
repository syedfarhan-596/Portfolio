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
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.farhan.paisatrack.data.Category
import com.farhan.paisatrack.data.TxnType
import com.farhan.paisatrack.ui.MainViewModel
import com.farhan.paisatrack.ui.components.ColorPickerRow
import com.farhan.paisatrack.ui.components.IconBadge
import com.farhan.paisatrack.ui.components.IconPickerRow
import com.farhan.paisatrack.ui.components.SectionCard
import com.farhan.paisatrack.util.IconMap

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CategoriesScreen(vm: MainViewModel, onBack: () -> Unit) {
    val categories by vm.allCategories.collectAsStateWithLifecycle()
    var editing by remember { mutableStateOf<Category?>(null) }
    var showDialog by remember { mutableStateOf(false) }
    var newType by remember { mutableStateOf(TxnType.EXPENSE) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Categories") },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { editing = null; showDialog = true }) {
                Icon(Icons.Filled.Add, contentDescription = "Add category")
            }
        }
    ) { padding ->
        LazyColumn(
            Modifier.fillMaxSize().padding(padding),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp, 8.dp, 16.dp, 96.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            item { SectionTitle("Expense categories") }
            items(categories.filter { it.type == TxnType.EXPENSE }, key = { "e${it.id}" }) { c ->
                CategoryRow(c) { editing = c; showDialog = true }
            }
            item { SectionTitle("Income categories") }
            items(categories.filter { it.type == TxnType.INCOME }, key = { "i${it.id}" }) { c ->
                CategoryRow(c) { editing = c; showDialog = true }
            }
        }
    }

    if (showDialog) {
        CategoryEditorDialog(
            category = editing,
            defaultType = newType,
            onDismiss = { showDialog = false },
            onSave = { vm.saveCategory(it); showDialog = false },
            onDelete = editing?.let { c -> { vm.deleteCategory(c); showDialog = false } }
        )
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(text, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(top = 6.dp))
}

@Composable
private fun CategoryRow(c: Category, onClick: () -> Unit) {
    SectionCard(modifier = Modifier.clickable { onClick() }) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconBadge(IconMap.icon(c.icon), IconMap.parseColor(c.colorHex))
            Spacer(Modifier.width(12.dp))
            Text(c.name, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CategoryEditorDialog(
    category: Category?,
    defaultType: TxnType,
    onDismiss: () -> Unit,
    onSave: (Category) -> Unit,
    onDelete: (() -> Unit)?
) {
    var name by remember { mutableStateOf(category?.name ?: "") }
    var type by remember { mutableStateOf(category?.type ?: defaultType) }
    var color by remember { mutableStateOf(category?.colorHex ?: IconMap.palette.first()) }
    var icon by remember { mutableStateOf(category?.icon ?: "category") }

    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = {
                if (name.isBlank()) return@TextButton
                onSave(
                    (category ?: Category(name = name, type = type)).copy(
                        name = name, type = type, colorHex = color, icon = icon
                    )
                )
            }) { Text("Save") }
        },
        dismissButton = {
            Row {
                if (onDelete != null) {
                    TextButton(onClick = onDelete) { Text("Delete", color = MaterialTheme.colorScheme.error) }
                }
                TextButton(onClick = onDismiss) { Text("Cancel") }
            }
        },
        title = { Text(if (category == null) "New category" else "Edit category") },
        text = {
            Column(
                Modifier.verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Name") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                    val types = listOf(TxnType.EXPENSE, TxnType.INCOME)
                    types.forEachIndexed { index, t ->
                        SegmentedButton(
                            selected = type == t,
                            onClick = { type = t },
                            shape = SegmentedButtonDefaults.itemShape(index, types.size),
                            label = { Text(t.name.lowercase().replaceFirstChar { it.uppercase() }) }
                        )
                    }
                }
                Text("Color", fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                ColorPickerRow(selected = color, onSelect = { color = it })
                Text("Icon", fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                IconPickerRow(selected = icon, tint = IconMap.parseColor(color), onSelect = { icon = it })
            }
        }
    )
}
