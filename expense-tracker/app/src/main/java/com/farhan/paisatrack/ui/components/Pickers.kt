package com.farhan.paisatrack.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.farhan.paisatrack.util.IconMap

@Composable
fun ColorPickerRow(selected: String, onSelect: (String) -> Unit) {
    LazyRow(
        horizontalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(10.dp),
        contentPadding = PaddingValues(vertical = 4.dp)
    ) {
        items(IconMap.palette) { hex ->
            val color = IconMap.parseColor(hex)
            Box(
                Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(color)
                    .then(
                        if (hex == selected)
                            Modifier.border(3.dp, MaterialTheme.colorScheme.onSurface, CircleShape)
                        else Modifier
                    )
                    .clickable { onSelect(hex) }
            )
        }
    }
}

@Composable
fun IconPickerRow(selected: String, tint: Color, onSelect: (String) -> Unit) {
    LazyRow(
        horizontalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(10.dp),
        contentPadding = PaddingValues(vertical = 4.dp)
    ) {
        items(IconMap.all) { (name, icon) ->
            Box(
                Modifier
                    .size(44.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(
                        if (name == selected) tint.copy(alpha = 0.22f)
                        else MaterialTheme.colorScheme.surfaceVariant
                    )
                    .then(
                        if (name == selected) Modifier.border(2.dp, tint, RoundedCornerShape(12.dp))
                        else Modifier
                    )
                    .clickable { onSelect(name) },
                contentAlignment = Alignment.Center
            ) {
                Icon(icon, contentDescription = name, tint = if (name == selected) tint else MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}
