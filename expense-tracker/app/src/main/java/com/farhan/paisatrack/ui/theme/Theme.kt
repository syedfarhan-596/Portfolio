package com.farhan.paisatrack.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

val Violet = Color(0xFF6C5CE7)
val VioletDark = Color(0xFF5849C2)
val Mint = Color(0xFF00B894)
val Coral = Color(0xFFE17055)
val Sky = Color(0xFF0984E3)
val Amber = Color(0xFFFDCB6E)
val Rose = Color(0xFFE84393)
val IncomeGreen = Color(0xFF1AAD7E)
val ExpenseRed = Color(0xFFE65A4F)

private val LightColors = lightColorScheme(
    primary = Violet,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFE9E5FF),
    onPrimaryContainer = Color(0xFF24105E),
    secondary = Mint,
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFCFF5E9),
    onSecondaryContainer = Color(0xFF00382A),
    tertiary = Sky,
    background = Color(0xFFF6F6FB),
    onBackground = Color(0xFF1A1A24),
    surface = Color.White,
    onSurface = Color(0xFF1A1A24),
    surfaceVariant = Color(0xFFEDECF4),
    onSurfaceVariant = Color(0xFF5A5A6E),
    outline = Color(0xFFC9C8D6),
    error = ExpenseRed
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFFB7AEFF),
    onPrimary = Color(0xFF22124F),
    primaryContainer = Color(0xFF463A8C),
    onPrimaryContainer = Color(0xFFE9E5FF),
    secondary = Color(0xFF6FE0C0),
    onSecondary = Color(0xFF003828),
    secondaryContainer = Color(0xFF005140),
    onSecondaryContainer = Color(0xFFCFF5E9),
    tertiary = Color(0xFF7EC2FF),
    background = Color(0xFF121218),
    onBackground = Color(0xFFE9E8F0),
    surface = Color(0xFF1C1C26),
    onSurface = Color(0xFFE9E8F0),
    surfaceVariant = Color(0xFF2A2A38),
    onSurfaceVariant = Color(0xFFB6B5C7),
    outline = Color(0xFF45445A),
    error = Color(0xFFFF8A80)
)

private val AppTypography = Typography(
    headlineLarge = Typography().headlineLarge.copy(fontWeight = FontWeight.Bold),
    headlineMedium = Typography().headlineMedium.copy(fontWeight = FontWeight.Bold),
    titleLarge = Typography().titleLarge.copy(fontWeight = FontWeight.SemiBold),
    titleMedium = Typography().titleMedium.copy(fontWeight = FontWeight.SemiBold),
    labelLarge = Typography().labelLarge.copy(fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
)

@Composable
fun PaisaTrackTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        typography = AppTypography,
        content = content
    )
}
