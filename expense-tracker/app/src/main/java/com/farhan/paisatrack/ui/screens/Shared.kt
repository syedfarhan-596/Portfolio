package com.farhan.paisatrack.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.farhan.paisatrack.data.TxnType
import com.farhan.paisatrack.ui.components.IconBadge
import com.farhan.paisatrack.ui.components.SectionCard
import com.farhan.paisatrack.ui.theme.ExpenseRed
import com.farhan.paisatrack.ui.theme.IncomeGreen
import com.farhan.paisatrack.ui.theme.Sky
import com.farhan.paisatrack.util.Format

@Composable
fun TransactionRow(
    title: String,
    subtitle: String,
    note: String,
    amount: Double,
    type: TxnType,
    icon: ImageVector,
    color: Color,
    dateText: String,
    onClick: () -> Unit
) {
    SectionCard(modifier = Modifier.clickable { onClick() }) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconBadge(icon = icon, tint = color)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text(
                    subtitle,
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                if (note.isNotBlank()) {
                    Text(
                        note,
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
            Spacer(Modifier.width(8.dp))
            Column(horizontalAlignment = Alignment.End) {
                val sign = when (type) {
                    TxnType.INCOME -> "+"
                    TxnType.EXPENSE -> "-"
                    TxnType.TRANSFER -> ""
                }
                Text(
                    sign + Format.money(amount),
                    fontWeight = FontWeight.Bold,
                    color = when (type) {
                        TxnType.INCOME -> IncomeGreen
                        TxnType.EXPENSE -> ExpenseRed
                        TxnType.TRANSFER -> Sky
                    }
                )
                Text(dateText, fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}
