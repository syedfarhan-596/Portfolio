package com.farhan.paisatrack.ui.components

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.ContactsContract
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.core.content.ContextCompat
import androidx.compose.ui.platform.LocalContext

/**
 * Returns a lambda that, when invoked, asks for READ_CONTACTS (if needed) and
 * opens the system contact picker. The chosen contact's display name + lookup
 * key are returned via [onPicked].
 */
@Composable
fun rememberContactPicker(onPicked: (name: String, key: String?) -> Unit): () -> Unit {
    val context = LocalContext.current

    val pickLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.PickContact()
    ) { uri: Uri? ->
        if (uri != null) {
            val proj = arrayOf(
                ContactsContract.Contacts.DISPLAY_NAME,
                ContactsContract.Contacts.LOOKUP_KEY
            )
            context.contentResolver.query(uri, proj, null, null, null)?.use { c ->
                if (c.moveToFirst()) {
                    val name = c.getString(0) ?: "Unknown"
                    val key = runCatching { c.getString(1) }.getOrNull()
                    onPicked(name, key)
                }
            }
        }
    }

    val permLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) pickLauncher.launch(null)
    }

    return remember {
        {
            val granted = ContextCompat.checkSelfPermission(
                context, Manifest.permission.READ_CONTACTS
            ) == PackageManager.PERMISSION_GRANTED
            if (granted) pickLauncher.launch(null)
            else permLauncher.launch(Manifest.permission.READ_CONTACTS)
        }
    }
}
