package com.gilesdesenvolvimento.mycarapp

import android.content.Intent
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.AlarmManager
import android.app.PendingIntent
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.provider.CalendarContract
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        io.flutter.plugin.common.MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mycarapp/calendar"
        ).setMethodCallHandler { call, result ->
            if (call.method != "addAllDayEvent") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val title = call.argument<String>("title") ?: "MyCarApp Manutenção"
            val description = call.argument<String>("description") ?: ""
            val start = call.argument<Number>("date")?.toLong()
            if (start == null) {
                result.error("INVALID_DATE", "Data da manutenção não informada.", null)
                return@setMethodCallHandler
            }
            val intent = Intent(Intent.ACTION_INSERT).setData(CalendarContract.Events.CONTENT_URI)
                .putExtra(CalendarContract.Events.TITLE, title)
                .putExtra(CalendarContract.Events.DESCRIPTION, description)
                .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, start)
                .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, start + 86_400_000L)
                .putExtra(CalendarContract.Events.ALL_DAY, true)
            if (intent.resolveActivity(packageManager) == null) {
                result.error("NO_CALENDAR", "Nenhum aplicativo de agenda disponível.", null)
                return@setMethodCallHandler
            }
            startActivity(intent)
            result.success(null)
        }

        io.flutter.plugin.common.MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mycarapp/notifications"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
                    ) {
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4102)
                    }
                    result.success(null)
                }
                "show" -> {
                    val title = call.argument<String>("title") ?: "MyCarApp"
                    val message = call.argument<String>("message") ?: ""
                    showNotification(title, message)
                    result.success(null)
                }
                "scheduleMaintenance" -> {
                    val id = call.argument<String>("id") ?: System.currentTimeMillis().toString()
                    val date = call.argument<Number>("date")?.toLong()
                    val message = call.argument<String>("message") ?: "Manutenção programada"
                    if (date == null) {
                        result.error("INVALID_DATE", "Data não informada.", null)
                    } else {
                        val reminder = maxOf(System.currentTimeMillis() + 5_000L, date - 7 * 86_400_000L)
                        val intent = Intent(this, MaintenanceNotificationReceiver::class.java)
                            .putExtra("message", message)
                        val pending = PendingIntent.getBroadcast(
                            this,
                            id.hashCode(),
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        val alarm = getSystemService(AlarmManager::class.java)
                        // Um lembrete de manutenção não exige horário exato. A janela evita
                        // a permissão especial de alarmes exatos no Android 12 ou superior.
                        alarm.setWindow(
                            AlarmManager.RTC_WAKEUP,
                            reminder,
                            60 * 60 * 1000L,
                            pending
                        )
                        result.success(null)
                    }
                }
                "setPreferences" -> {
                    val preferences = getSharedPreferences("notification_preferences", MODE_PRIVATE)
                    preferences.edit()
                        .putBoolean("updates", call.argument<Boolean>("updates") ?: true)
                        .putBoolean("maintenance", call.argument<Boolean>("maintenance") ?: true)
                        .putBoolean("fuelLow", call.argument<Boolean>("fuelLow") ?: true)
                        .putBoolean("overfill", call.argument<Boolean>("overfill") ?: true)
                        .apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun showNotification(title: String, message: String) {
        val manager = getSystemService(NotificationManager::class.java)
        val channelId = "mycarapp_alerts"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(channelId, "Alertas do MyCarApp", NotificationManager.IMPORTANCE_DEFAULT)
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            android.app.Notification.Builder(this, channelId)
        } else {
            @Suppress("DEPRECATION")
            android.app.Notification.Builder(this)
        }
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(android.app.Notification.BigTextStyle().bigText(message))
            .setAutoCancel(true)
            .build()
        manager.notify(System.currentTimeMillis().toInt(), notification)
    }
}
