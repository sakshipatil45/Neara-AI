package com.example.customer_app

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Build
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
                    "pinSosShortcut" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val pinned = pinSosShortcutIfNeeded()
                            result.success(pinned)
                        } else {
                            result.success(false)
                        }
                    }
                    "checkSosIntent" -> {
                        val openSos = intent?.getBooleanExtra("open_sos", false) ?: false
                        result.success(openSos)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Checks if the SOS pinned shortcut currently exists on any launcher.
     * If it does NOT exist (never created, or removed by user), we request
     * pinning again.  If it already exists, we skip to avoid duplicates.
     *
     * Returns true if a pin request was sent, false if shortcut already exists.
     */
    @RequiresApi(Build.VERSION_CODES.O)
    private fun pinSosShortcutIfNeeded(): Boolean {
        val shortcutManager = getSystemService(Context.SHORTCUT_SERVICE) as ShortcutManager

        if (!shortcutManager.isRequestPinShortcutSupported) return false

        // Check if the shortcut already exists in the pinned list
        val alreadyPinned = shortcutManager.pinnedShortcuts.any { it.id == SHORTCUT_ID }
        if (alreadyPinned) return false   // exists — do nothing

        // Build the intent that fires when the pinned shortcut is tapped
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
}
