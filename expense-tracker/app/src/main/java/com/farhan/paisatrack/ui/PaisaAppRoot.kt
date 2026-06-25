package com.farhan.paisatrack.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.farhan.paisatrack.ui.screens.AccountsScreen
import com.farhan.paisatrack.ui.screens.AddDebtScreen
import com.farhan.paisatrack.ui.screens.AddEditTransactionScreen
import com.farhan.paisatrack.ui.screens.CategoriesScreen
import com.farhan.paisatrack.ui.screens.DashboardScreen
import com.farhan.paisatrack.ui.screens.PeopleScreen
import com.farhan.paisatrack.ui.screens.ReportsScreen
import com.farhan.paisatrack.ui.screens.SettingsScreen
import com.farhan.paisatrack.ui.screens.TransactionsScreen

private data class Dest(val route: String, val label: String, val icon: ImageVector)

private val bottomDests = listOf(
    Dest("home", "Home", Icons.Filled.Home),
    Dest("txns", "Activity", Icons.AutoMirrored.Filled.ReceiptLong),
    Dest("people", "People", Icons.Filled.Group),
    Dest("reports", "Reports", Icons.Filled.BarChart),
    Dest("more", "Settings", Icons.Filled.Settings)
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaisaApproot(isDark: Boolean, onToggleTheme: () -> Unit) {
    val nav = rememberNavController()
    val vm: MainViewModel = viewModel(factory = MainViewModel.Factory)

    val backStack by nav.currentBackStackEntryAsState()
    val currentRoute = backStack?.destination?.route
    val showBottomBar = currentRoute in bottomDests.map { it.route }
    val showFab = currentRoute == "home" || currentRoute == "txns"

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    bottomDests.forEach { dest ->
                        val selected = backStack?.destination?.hierarchy?.any { it.route == dest.route } == true
                        NavigationBarItem(
                            selected = selected,
                            onClick = {
                                nav.navigate(dest.route) {
                                    popUpTo(nav.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            icon = { Icon(dest.icon, contentDescription = dest.label) },
                            label = { Text(dest.label) }
                        )
                    }
                }
            }
        },
        floatingActionButton = {
            if (showFab) {
                FloatingActionButton(onClick = { nav.navigate("addTxn") }) {
                    Icon(Icons.Filled.Add, contentDescription = "Add transaction")
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = nav,
            startDestination = "home",
            modifier = Modifier.padding(padding)
        ) {
            composable("home") {
                DashboardScreen(
                    vm = vm,
                    onAddTxn = { nav.navigate("addTxn") },
                    onOpenTxn = { id -> nav.navigate("addTxn?id=$id") },
                    onSeeAllTxns = { nav.navigate("txns") },
                    onSeePeople = { nav.navigate("people") }
                )
            }
            composable("txns") {
                TransactionsScreen(
                    vm = vm,
                    onAddTxn = { nav.navigate("addTxn") },
                    onOpenTxn = { id -> nav.navigate("addTxn?id=$id") }
                )
            }
            composable("people") {
                PeopleScreen(
                    vm = vm,
                    onAddDebt = { nav.navigate("addDebt") },
                    onOpenDebt = { id -> nav.navigate("addDebt?id=$id") }
                )
            }
            composable("reports") { ReportsScreen(vm = vm) }
            composable("more") {
                SettingsScreen(
                    vm = vm,
                    isDark = isDark,
                    onToggleTheme = onToggleTheme,
                    onManageAccounts = { nav.navigate("accounts") },
                    onManageCategories = { nav.navigate("categories") }
                )
            }
            composable(
                "addTxn?id={id}",
                arguments = listOf(androidx.navigation.navArgument("id") {
                    type = androidx.navigation.NavType.LongType; defaultValue = -1L
                })
            ) { entry ->
                val id = entry.arguments?.getLong("id") ?: -1L
                AddEditTransactionScreen(vm = vm, txnId = if (id > 0) id else null, onDone = { nav.popBackStack() })
            }
            composable(
                "addDebt?id={id}",
                arguments = listOf(androidx.navigation.navArgument("id") {
                    type = androidx.navigation.NavType.LongType; defaultValue = -1L
                })
            ) { entry ->
                val id = entry.arguments?.getLong("id") ?: -1L
                AddDebtScreen(vm = vm, debtId = if (id > 0) id else null, onDone = { nav.popBackStack() })
            }
            composable("accounts") { AccountsScreen(vm = vm, onBack = { nav.popBackStack() }) }
            composable("categories") { CategoriesScreen(vm = vm, onBack = { nav.popBackStack() }) }
        }
    }
}
