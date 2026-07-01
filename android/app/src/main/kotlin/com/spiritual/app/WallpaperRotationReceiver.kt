package com.spiritual.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.WallpaperManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import java.net.URL

/**
 * BroadcastReceiver that fires every 15 minutes (via AlarmManager) to rotate
 * the home-screen wallpaper. Works even when the app is in the background or killed.
 *
 * Also handles BOOT_COMPLETED so the rotation survives device reboots.
 *
 * SharedPreferences keys must match WallpaperService in Dart:
 *   flutter.wallpaper_rotation_enabled   → Boolean
 *   flutter.wallpaper_current_index      → Int
 *   flutter.wallpaper_last_update        → String (epoch ms)
 *   flutter.wallpaper_cached_urls        → JSON array of URL strings
 */
class WallpaperRotationReceiver : BroadcastReceiver() {

    companion object {
        private const val PREFS_NAME      = "FlutterSharedPreferences"
        private const val KEY_ENABLED     = "flutter.wallpaper_rotation_enabled"
        private const val KEY_INDEX       = "flutter.wallpaper_current_index"
        private const val KEY_LAST_UPDATE = "flutter.wallpaper_last_update"
        private const val KEY_CACHED_URLS = "flutter.wallpaper_cached_urls"
        private const val INTERVAL_MS     = 15 * 60 * 1000L   // 15 minutes
        private const val REQUEST_CODE    = 1001               // unique request code

        /** Schedule (or reschedule) the next wallpaper rotation alarm. */
        fun schedule(context: Context) {
            val pi = getPendingIntent(context)
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(pi) // always cancel first to avoid duplicates

            val triggerAt = System.currentTimeMillis() + INTERVAL_MS

            try {
                when {
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
                        // Android 12+ (API 31): USE_EXACT_ALARM is declared in manifest
                        // which grants exact alarms without user interaction.
                        // canScheduleExactAlarms() guards against the rare case where it
                        // was revoked by the user in Settings.
                        if (am.canScheduleExactAlarms()) {
                            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                            println("✅ Exact wallpaper alarm scheduled (Android 12+)")
                        } else {
                            // Fallback: inexact but still fires within a reasonable window
                            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                            println("✅ Inexact wallpaper alarm scheduled (exact alarm not granted)")
                        }
                    }
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                        // Android 6–11: setExactAndAllowWhileIdle works without special permission
                        am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                        println("✅ Exact wallpaper alarm scheduled (Android 6–11)")
                    }
                    else -> {
                        // Android 5 and below
                        am.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                        println("✅ Exact wallpaper alarm scheduled (pre-Android 6)")
                    }
                }
            } catch (e: SecurityException) {
                // Last resort: inexact alarm — better than nothing
                println("⚠️ Exact alarm denied, falling back to inexact: ${e.message}")
                try {
                    am.set(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                } catch (e2: Exception) {
                    println("❌ Could not schedule any alarm: ${e2.message}")
                }
            }
        }

        /** Cancel any scheduled wallpaper rotation alarm. */
        fun cancel(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(getPendingIntent(context))
            println("✅ Wallpaper alarm cancelled")
        }

        private fun getPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, WallpaperRotationReceiver::class.java)
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            else
                PendingIntent.FLAG_UPDATE_CURRENT
            return PendingIntent.getBroadcast(context, REQUEST_CODE, intent, flags)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action

        // On device reboot: reschedule the alarm if rotation is enabled.
        // Do NOT try to set wallpaper here — we have no network yet on boot.
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val enabled = prefs.getBoolean(KEY_ENABLED, false)
            if (enabled) {
                schedule(context)
                println("✅ WallpaperRotationReceiver: rescheduled after boot")
            }
            return
        }

        // Regular 15-minute alarm
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean(KEY_ENABLED, false)

        if (!enabled) {
            println("⚠️ WallpaperRotationReceiver: rotation disabled, skipping")
            return
        }

        println("⏰ WallpaperRotationReceiver: rotating wallpaper")

        // goAsync() lets us do async work in a BroadcastReceiver safely
        val pendingResult = goAsync()

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val urlsJson = prefs.getString(KEY_CACHED_URLS, null)
                if (urlsJson.isNullOrEmpty()) {
                    println("⚠️ No cached wallpaper URLs — cannot rotate")
                    return@launch
                }

                val urls = JSONArray(urlsJson)
                if (urls.length() == 0) {
                    println("⚠️ Wallpaper URL list is empty")
                    return@launch
                }

                val currentIndex = prefs.getInt(KEY_INDEX, 0)
                val nextIndex = currentIndex % urls.length()
                val imageUrl = urls.getString(nextIndex)

                println("🖼️ Downloading wallpaper $nextIndex / ${urls.length()}: $imageUrl")

                // Download image on IO thread
                val bytes = try {
                    URL(imageUrl).openConnection().apply {
                        connectTimeout = 15_000
                        readTimeout = 30_000
                    }.getInputStream().readBytes()
                } catch (e: Exception) {
                    println("❌ Download failed: ${e.message}")
                    return@launch
                }

                val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                    ?: run { println("❌ Failed to decode image"); return@launch }

                // Scale to screen size (FIT_CENTER with black letterbox)
                val dm = context.resources.displayMetrics
                val targetW = dm.widthPixels
                val targetH = dm.heightPixels

                val imageAspect = bitmap.width.toFloat() / bitmap.height.toFloat()
                val screenAspect = targetW.toFloat() / targetH.toFloat()

                val scaledW: Int
                val scaledH: Int
                if (imageAspect > screenAspect) {
                    scaledW = targetW
                    scaledH = (targetW / imageAspect).toInt().coerceAtLeast(1)
                } else {
                    scaledH = targetH
                    scaledW = (targetH * imageAspect).toInt().coerceAtLeast(1)
                }

                val scaled = android.graphics.Bitmap.createScaledBitmap(bitmap, scaledW, scaledH, true)
                val canvasBmp = android.graphics.Bitmap.createBitmap(
                    targetW, targetH, android.graphics.Bitmap.Config.ARGB_8888)
                val canvas = android.graphics.Canvas(canvasBmp)
                canvas.drawColor(android.graphics.Color.BLACK)
                val left = (targetW - scaledW) / 2f
                val top  = (targetH - scaledH) / 2f
                canvas.drawBitmap(scaled, left, top, null)

                // Set wallpaper — can be called from any thread (WallpaperManager is thread-safe)
                try {
                    val wm = WallpaperManager.getInstance(context)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        val rect = android.graphics.Rect(0, 0, targetW, targetH)
                        // FLAG_SYSTEM only — don't touch lock screen wallpaper
                        wm.setBitmap(canvasBmp, rect, true, WallpaperManager.FLAG_SYSTEM)
                    } else {
                        wm.setBitmap(canvasBmp)
                    }

                    // Persist updated index and timestamp
                    prefs.edit()
                        .putInt(KEY_INDEX, nextIndex + 1)
                        .putString(KEY_LAST_UPDATE, System.currentTimeMillis().toString())
                        .apply()

                    println("✅ Wallpaper rotated to index $nextIndex")
                } catch (e: Exception) {
                    println("❌ setWallpaper error: ${e.message}")
                } finally {
                    bitmap.recycle()
                    if (scaled != bitmap) scaled.recycle()
                    canvasBmp.recycle()
                }

            } catch (e: Exception) {
                println("❌ WallpaperRotationReceiver error: ${e.message}")
            } finally {
                // Always reschedule the next alarm, even on error
                schedule(context)
                // Release the BroadcastReceiver so the system can reclaim resources
                pendingResult.finish()
            }
        }
    }
}
