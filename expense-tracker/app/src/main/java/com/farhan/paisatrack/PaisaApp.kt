package com.farhan.paisatrack

import android.app.Application
import com.farhan.paisatrack.data.AppDatabase
import com.farhan.paisatrack.data.Repository
import com.farhan.paisatrack.util.Notifications
import com.farhan.paisatrack.work.ReminderScheduler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class PaisaApp : Application() {

    val database: AppDatabase by lazy { AppDatabase.get(this) }
    val repository: Repository by lazy { Repository(database) }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onCreate() {
        super.onCreate()
        Notifications.ensureChannels(this)
        scope.launch {
            Repository.seedIfEmpty(database)
        }
        ReminderScheduler.schedule(this)
    }
}
