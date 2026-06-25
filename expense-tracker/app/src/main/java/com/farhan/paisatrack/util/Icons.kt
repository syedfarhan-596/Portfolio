package com.farhan.paisatrack.util

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.Category
import androidx.compose.material.icons.filled.Checkroom
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.FamilyRestroom
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.LocalHospital
import androidx.compose.material.icons.filled.Movie
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.Savings
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material.icons.filled.SportsEsports
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Train
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector

object IconMap {
    val all: List<Pair<String, ImageVector>> = listOf(
        "category" to Icons.Filled.Category,
        "restaurant" to Icons.Filled.Restaurant,
        "checkroom" to Icons.Filled.Checkroom,
        "family_restroom" to Icons.Filled.FamilyRestroom,
        "groups" to Icons.Filled.Groups,
        "shopping_cart" to Icons.Filled.ShoppingCart,
        "shopping_bag" to Icons.Filled.ShoppingBag,
        "directions_car" to Icons.Filled.DirectionsCar,
        "train" to Icons.Filled.Train,
        "receipt_long" to Icons.Filled.ReceiptLong,
        "local_hospital" to Icons.Filled.LocalHospital,
        "movie" to Icons.Filled.Movie,
        "sports" to Icons.Filled.SportsEsports,
        "school" to Icons.Filled.School,
        "payments" to Icons.Filled.Payments,
        "undo" to Icons.AutoMirrored.Filled.Undo,
        "card_giftcard" to Icons.Filled.CardGiftcard,
        "account_balance" to Icons.Filled.AccountBalance,
        "wallet" to Icons.Filled.AccountBalanceWallet,
        "credit_card" to Icons.Filled.CreditCard,
        "savings" to Icons.Filled.Savings,
        "star" to Icons.Filled.Star
    )

    private val map = all.toMap()

    fun icon(name: String?): ImageVector = map[name] ?: Icons.Filled.Category

    fun parseColor(hex: String): Color = try {
        Color(android.graphics.Color.parseColor(hex))
    } catch (e: Exception) {
        Color(0xFF6C5CE7)
    }

    val palette = listOf(
        "#6C5CE7", "#0984E3", "#00B894", "#00CEC9", "#FDCB6E",
        "#E17055", "#D63031", "#E84393", "#A29BFE", "#FF7675",
        "#636E72", "#2D3436", "#FAB1A0", "#55EFC4"
    )
}
