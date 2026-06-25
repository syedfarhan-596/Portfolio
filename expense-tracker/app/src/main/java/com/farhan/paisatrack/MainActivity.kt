package com.farhan.paisatrack

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.farhan.paisatrack.ui.PaisaApproot
import com.farhan.paisatrack.ui.theme.PaisaTrackTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent {
            val dark = isSystemInDarkTheme()
            var darkOverride by remember { mutableStateOf<Boolean?>(null) }
            PaisaTrackTheme(darkTheme = darkOverride ?: dark) {
                PaisaApproot(
                    isDark = darkOverride ?: dark,
                    onToggleTheme = { darkOverride = !(darkOverride ?: dark) }
                )
            }
        }
    }
}
