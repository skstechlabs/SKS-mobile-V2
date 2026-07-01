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
import java.io.File
import java.net.URL

/**
 * BroadcastReceiver that fires every 15 minutes (via AlarmManager) to rotate
 * the wallpaper. This works even when the app is in the background or killed.
 *
 * SharedPreferences keys must match WallpaperService in Dart:
 *   wallpaper_rotation_enabled
 *   wallpaper_current_index
 *   wallpaper_last_update
 *   wallpaper_cached_list   (JSON array of URL strings)
 */
class WallpaperRotationReceiver : BroadcastReceiver() {

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_ENABLED = "flutter.wallpaper_rotation_enabled"
        private const val KEY_INDEX = "flutter.wallpaper_current_index"
        private const val KEY_LAST_UPDATE = "flutter.wallpaper_last_update"
        private const val KEY_CACHED_URLS = "flutter.wallpaper_cached_urls"
        private const val INTERVAL_MS = 15 * 60 * 1000L // 15 minutes
    }

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean(KEY_ENABLED, false)

        if (!enabled) {
            println("⚠️ WallpaperRotationReceiver: rotation disabled, skipping")
            return
        }

        println("⏰ WallpaperRotationReceiver: rotating wallpaper")

        // Run network + wallpaper work on IO thread
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val urlsJson = prefs.getString(KEY_CACHED_URLS, null)
                if (urlsJson.isNullOrEmpty()) {
                    println("⚠️ No cached wallpaper URLs")
                    return@launch
                }

                val urls = JSONArray(urlsJson)
                if (urls.length() == 0) return@launch

                val currentIndex = prefs.getInt(KEY_INDEX, 0)
                val nextIndex = currentIndex % urls.length()
                val imageUrl = urls.getString(nextIndex)

                println("🖼️ Setting wallpaper $nextIndex: $imageUrl")

                // Download image
                val bytes = URL(imageUrl).readBytes()
                val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                    ?: run { println("❌ Failed to decode image"); return@launch }

                // Scale and set wallpaper
                val wm = WallpaperManager.getInstance(context)
                val dm = context.resources.displayMetrics
                val targetW = dm.widthPixels
                val targetH = dm.heightPixels

                val imageAspect = bitmap.width.toFloat() / bitmap.height.toFloat()
                val screenAspect = targetW.toFloat() / targetH.toFloat()

                val scaledW: Int
                val scaledH: Int
                if (imageAspect > screenAspect) {
                    scaledW = targetW
                    scaledH = (targetW / imageAspect).toInt()
                } else {
                    scaledH = targetH
                    scaledW = (targetH * imageAspect).toInt()
                }

                val scaled = android.graphics.Bitmap.createScaledBitmap(bitmap, scaledW, scaledH, true)
                val canvas_bmp = android.graphics.Bitmap.createBitmap(targetW, targetH, android.graphics.Bitmap.Config.ARGB_8888)
                val canvas = android.graphics.Canvas(canvas_bmp)
                canvas.drawColor(android.graphics.Color.BLACK)
                val left = (targetW - scaledW) / 2f
                val top = (targetH - scaledH) / 2f
                canvas.drawBitmap(scaled, left, top, null)

                withContext(Dispatchers.Main) {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            val rect = android.graphics.Rect(0, 0, targetW, targetH)
                            // Only FLAG_SYSTEM — do NOT set FLAG_LOCK so that other apps
                            // (e.g. WhatsApp) that read the lock screen wallpaper are unaffected.
                            wm.setBitmap(canvas_bmp, rect, true, WallpaperManager.FLAG_SYSTEM)
                        } else {
                            wm.setBitmap(canvas_bmp)
                        }

                        // Update prefs
                        prefs.edit()
                            .putInt(KEY_INDEX, nextIndex + 1)
                            .putString(KEY_LAST_UPDATE, System.currentTimeMillis().toString())
                            .apply()

                        println("✅ Wallpaper rotated to index $nextIndex")
                    } catch (e: Exception) {
                        println("❌ setWallpaper error: ${e.message}")
                    }
                }

                bitmap.recycle()
                scaled.recycle()

            } catch (e: Exception) {
                println("❌ WallpaperRotationReceiver error: ${e.message}")
            } finally {
                // Reschedule next alarm
                reschedule(context)
            }
        }
    }

    private fun reschedule(context: Context) {
        val intent = Intent(context, WallpaperRotationReceiver::class.java)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else
            PendingIntent.FLAG_UPDATE_CURRENT
        val pi = PendingIntent.getBroadcast(context, 0, intent, flags)

        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerAt = System.currentTimeMillis() + INTERVAL_MS

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        } else {
            am.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        }
        println("🔄 Next wallpaper rotation scheduled in 15 minutes")
    }
}
