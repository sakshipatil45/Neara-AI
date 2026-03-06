package com.example.customer_app

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Build
import android.telephony.SmsManager
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.example.customer_app/sos_shortcut"
        private const val SHORTCUT_ID = "sos_shortcut"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // Flutter calls this to pin the SOS shortcut to the home screen
                    "pinSosShortcut" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val pinned = pinSosShortcutIfNeeded()
                            result.success(pinned)
                        } else {
                            result.success(false)
                        }
                    }

                    // Flutter calls this on startup to check if launched via shortcut
                    "checkSosIntent" -> {
                        val openSos = intent?.getBooleanExtra("open_sos", false) ?: false
                        result.success(openSos)
                    }

                    // Flutter calls this to send SMS silently in the background
                    "sendSms" -> {
                        val phone = call.argument<String>("phone") ?: ""
                        val message = call.argument<String>("message") ?: ""
                        if (phone.isNotEmpty() && message.isNotEmpty()) {
                            sendSmsSilently(phone, message)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ── Pinned Shortcut ───────────────────────────────────────────────────────

    @RequiresApi(Build.VERSION_CODES.O)
    private fun pinSosShortcutIfNeeded(): Boolean {
        val shortcutManager = getSystemService(Context.SHORTCUT_SERVICE) as ShortcutManager
        if (!shortcutManager.isRequestPinShortcutSupported) return false

        val alreadyPinned = shortcutManager.pinnedShortcuts.any { it.id == SHORTCUT_ID }
        if (alreadyPinned) return false

        val shortcutIntent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            putExtra("open_sos", true)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        val shortcut = ShortcutInfo.Builder(this, SHORTCUT_ID)
            .setShortLabel("SOS")
            .setLongLabel("Emergency SOS")
            .setIcon(Icon.createWithResource(this, R.drawable.sos_icon))
            .setIntent(shortcutIntent)
            .build()

        val callbackIntent = shortcutManager.createShortcutResultIntent(shortcut)
        val successCallback = PendingIntent.getBroadcast(
            this, 0, callbackIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        shortcutManager.requestPinShortcut(shortcut, successCallback.intentSender)
        return true
    }

    // ── Silent Background SMS ─────────────────────────────────────────────────

    @Suppress("DEPRECATION")
    private fun sendSmsSilently(phone: String, message: String) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val smsManager = applicationContext.getSystemService(SmsManager::class.java)
                // Split into parts if message exceeds 160 chars
                val parts = smsManager.divideMessage(message)
                smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
            } else {
                val smsManager = SmsManager.getDefault()
                val parts = smsManager.divideMessage(message)
                smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
