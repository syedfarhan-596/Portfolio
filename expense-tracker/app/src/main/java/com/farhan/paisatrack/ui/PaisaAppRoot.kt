package com.farhan.paisatrack.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Home
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
import com.farhan.paisatrack.ui.screens.AddInvestmentScreen
import com.farhan.paisatrack.ui.screens.CategoriesScreen
import com.farhan.paisatrack.ui.screens.DashboardScreen
import com.farhan.paisatrack.ui.screens.PayCreditCardScreen
import com.farhan.paisatrack.ui.screens.PeopleScreen
import com.farhan.paisatrack.ui.screens.PortfolioScreen
import com.farhan.paisatrack.ui.screens.ReportsScreen
import com.farhan.paisatrack.ui.screens.SettingsScreen
import com.farhan.paisatrack.ui.screens.TransactionsScreen

private data class Dest(val route: String, val label: String, val icon: ImageVector)

private val bottomDests = listOf(
    Dest("home", "Home", Icons.Filled.Home),
    Dest("txns", "Activity", Icons.AutoMirrored.Filled.ReceiptLong),
    Dest("people", "People", Icons.Filled.Group),
    Dest("portfolio", "Invest", Icons.AutoMirrored.Filled.TrendingUp),
    Dest("reports", "Reports", Icons.Filled.BarChart)
)

@Composable
fun PaisaApproot(isDark: Boolean, onToggleTheme: () -> Unit) {
    val nav = rememberNavController()
    val vm: MainViewModel = viewModel(factory = MainViewModel.Factory)

    val backStack by nav.currentBackStackEntryAsState()
    val currentRoute = backStack?.destination?.route
    val showBottomBar = currentRoute in bottomDests.map { it.route }
    val fabRoute = when (currentRoute) {
        "home", "txns" -> "addTxn"
        "portfolio" -> "addInvestment"
        else -> null
    }

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
            AnimatedVisibility(
                visible = fabRoute != null,
                enter = scaleIn() + fadeIn(),
                exit = scaleOut() + fadeOut()
            ) {
                androidx.compose.material3.FloatingActionButton(onClick = { fabRoute?.let { nav.navigate(it) } }) {
                    Icon(Icons.Filled.Add, contentDescription = "Add")
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = nav,
            startDestination = "home",
            modifier = Modifier.padding(padding),
            enterTransition = { slideInHorizontally(animationSpec = tween(280)) { it / 6 } + fadeIn(tween(280)) },
            exitTransition = { fadeOut(tween(180)) },
            popEnterTransition = { fadeIn(tween(220)) },
            popExitTransition = { slideOutHorizontally(animationSpec = tween(280)) { it / 6 } + fadeOut(tween(220)) }
        ) {
            composable("home") {
                DashboardScreen(
                    vm = vm,
                    onAddTxn = { nav.navigate("addTxn") },
                    onOpenTxn = { id -> nav.navigate("addTxn?id=$id") },
                    onSeeAllTxns = { nav.navigate("txns") },
                    onSeePeople = { nav.navigate("people") },
                    onOpenSettings = { nav.navigate("settings") },
                    onPayCard = { id -> nav.navigate("payCard?id=$id") }
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
            composable("portfolio") {
                PortfolioScreen(
                    vm = vm,
                    onAdd = { nav.navigate("addInvestment") },
                    onOpen = { id -> nav.navigate("addInvestment?id=$id") }
                )
            }
            composable("reports") { ReportsScreen(vm = vm) }
            composable("settings") {
                SettingsScreen(
                    vm = vm,
                    isDark = isDark,
                    onToggleTheme = onToggleTheme,
                    onBack = { nav.popBackStack() },
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
            composable(
                "addInvestment?id={id}",
                arguments = listOf(androidx.navigation.navArgument("id") {
                    type = androidx.navigation.NavType.LongType; defaultValue = -1L
                })
            ) { entry ->
                val id = entry.arguments?.getLong("id") ?: -1L
                AddInvestmentScreen(vm = vm, investmentId = if (id > 0) id else null, onDone = { nav.popBackStack() })
            }
            composable(
                "payCard?id={id}",
                arguments = listOf(androidx.navigation.navArgument("id") {
                    type = androidx.navigation.NavType.LongType; defaultValue = -1L
                })
            ) { entry ->
                val id = entry.arguments?.getLong("id") ?: -1L
                PayCreditCardScreen(vm = vm, cardId = if (id > 0) id else null, onDone = { nav.popBackStack() })
            }
            composable("accounts") { AccountsScreen(vm = vm, onBack = { nav.popBackStack() }) }
            composable("categories") { CategoriesScreen(vm = vm, onBack = { nav.popBackStack() }) }
        }
    }
}
