package com.spiritual.app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.WallpaperManager
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {

    private val SECURITY_CHANNEL = "com.spiritual.app/security"
    private val RINGTONE_CHANNEL  = "com.spiritual.app/ringtone"
    private val WALLPAPER_CHANNEL = "com.spiritual.app/wallpaper"
    private var isSecureMode = false

    companion object {
        // Channel ID used by OneSignal for push notifications.
        // Must match:
        //   - AndroidManifest: com.onesignal.NotificationChannelId
        //   - Backend notificationService.js: android_channel_id
        // Versioned so Android recreates it with the new sound after an update.
        const val ONESIGNAL_CHANNEL_ID   = "sks_notifications_v2"
        const val ONESIGNAL_CHANNEL_NAME = "SKS Notifications"
    }

    // ── Lifecycle ──────────────────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createSksNotificationChannel()
    }

    override fun onResume() {
        super.onResume()
        if (isSecureMode) enableSecureMode()
    }

    // ── OneSignal notification channel ────────────────────────────────────────

    /**
     * Creates (or recreates) the SKS notification channel with the Sivoham ringtone.
     *
     * Android does NOT allow changing a channel's sound after it is created.
     * We delete the old channel first so the new sound takes effect.
     * The versioned ID (sks_notifications_v2) ensures a clean slate after updates.
     */
    private fun createSksNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Delete previous versions so the sound is always up to date
        nm.deleteNotificationChannel("sks_notifications")    // v1
        nm.deleteNotificationChannel(ONESIGNAL_CHANNEL_ID)   // v2 (recreate below)

        val soundUri = Uri.parse("android.resource://$packageName/raw/sivoham_ringtone")

        val audioAttr = AudioAttributes.Builder()
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .build()

        val channel = NotificationChannel(
            ONESIGNAL_CHANNEL_ID,
            ONESIGNAL_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "SKS spiritual updates and course notifications"
            setSound(soundUri, audioAttr)
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 250, 250, 250)
            enableLights(true)
            lightColor = 0xFFFF6F00.toInt() // saffron orange
        }

        nm.createNotificationChannel(channel)

        // Also create the reminders channel (used by flutter_local_notifications)
        val remindersChannel = NotificationChannel(
            "reminders_channel",
            "Daily Reminders",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Daily spiritual practice reminders"
            setSound(soundUri, audioAttr)
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 250, 250, 250)
            enableLights(true)
            lightColor = 0xFFFF6F00.toInt()
        }
        nm.createNotificationChannel(remindersChannel)

        println("✅ SKS notification channels created with Sivoham ringtone")
    }

    // ── Flutter engine / method channels ──────────────────────────────────────

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupSecurityChannel(flutterEngine)
        setupRingtoneChannel(flutterEngine)
        setupWallpaperChannel(flutterEngine)
    }

    private fun setupSecurityChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableSecureMode"    -> { enableSecureMode();  result.success(true) }
                    "disableSecureMode"   -> { disableSecureMode(); result.success(true) }
                    "checkScreenRecording" -> result.success(isSecureMode)
                    else                  -> result.notImplemented()
                }
            }
    }

    private fun setupRingtoneChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RINGTONE_CHANNEL)
            .setMethodCallHandler { call, result ->
                val path  = call.argument<String>("path")
                val title = call.argument<String>("title") ?: "Sivoham"
                when (call.method) {
                    "setRingtone" -> {
                        if (path == null) { result.error("INVALID_ARGUMENT", "path required", null); return@setMethodCallHandler }
                        result.success(setSystemSound(path, title, RingtoneManager.TYPE_RINGTONE))
                    }
                    "setNotification" -> {
                        if (path == null) { result.error("INVALID_ARGUMENT", "path required", null); return@setMethodCallHandler }
                        result.success(setSystemSound(path, title, RingtoneManager.TYPE_NOTIFICATION))
                    }
                    "setAlarm" -> {
                        if (path == null) { result.error("INVALID_ARGUMENT", "path required", null); return@setMethodCallHandler }
                        result.success(setSystemSound(path, title, RingtoneManager.TYPE_ALARM))
                    }
                    "setAppNotification" -> {
                        if (path == null) { result.error("INVALID_ARGUMENT", "path required", null); return@setMethodCallHandler }
                        result.success(setAppNotificationSound(path, title))
                    }
                    // ── Check if Sivoham is currently set ──────────────────────
                    "checkRingtone"      -> result.success(isSivohamSet(RingtoneManager.TYPE_RINGTONE))
                    "checkNotification"  -> result.success(isSivohamSet(RingtoneManager.TYPE_NOTIFICATION))
                    "checkAlarm"         -> result.success(isSivohamSet(RingtoneManager.TYPE_ALARM))
                    "checkAppNotification" -> result.success(isSivohamAppNotificationSet())
                    // ── Reset to system default ────────────────────────────────
                    "resetRingtone"      -> result.success(resetSystemSound(RingtoneManager.TYPE_RINGTONE))
                    "resetNotification"  -> result.success(resetSystemSound(RingtoneManager.TYPE_NOTIFICATION))
                    "resetAlarm"         -> result.success(resetSystemSound(RingtoneManager.TYPE_ALARM))
                    "resetAppNotification" -> result.success(resetAppNotificationSound())
                    "openSettings"   -> { openSystemSettings(); result.success(true) }
                    "checkPermission" -> {
                        val ok = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            Settings.System.canWrite(this) else true
                        result.success(ok)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setupWallpaperChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WALLPAPER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setWallpaper" -> {
                        val path = call.argument<String>("path")
                        if (path == null) { result.error("INVALID_ARGUMENT", "path required", null); return@setMethodCallHandler }
                        result.success(setWallpaper(path))
                    }
                    "scheduleWallpaperAlarm" -> {
                        val intervalMs = call.argument<Long>("intervalMs") ?: (15 * 60 * 1000L)
                        scheduleWallpaperAlarm(intervalMs)
                        result.success(true)
                    }
                    "cancelWallpaperAlarm" -> {
                        cancelWallpaperAlarm()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ── Wallpaper AlarmManager ─────────────────────────────────────────────────

    private fun getWallpaperPendingIntent(): PendingIntent {
        val intent = Intent(this, WallpaperRotationReceiver::class.java)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else
            PendingIntent.FLAG_UPDATE_CURRENT
        return PendingIntent.getBroadcast(this, 0, intent, flags)
    }

    private fun scheduleWallpaperAlarm(intervalMs: Long) {
        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = getWallpaperPendingIntent()
        am.cancel(pi) // cancel any existing alarm first

        val triggerAt = System.currentTimeMillis() + intervalMs
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        } else {
            am.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        }
        println("✅ Wallpaper alarm scheduled in ${intervalMs / 60000} minutes")
    }

    private fun cancelWallpaperAlarm() {
        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(getWallpaperPendingIntent())
        println("✅ Wallpaper alarm cancelled")
    }

    // ── Ringtone / system sound ────────────────────────────────────────────────

    /**
     * Sets a system sound (ringtone / notification / alarm) using the modern
     * MediaStore API that works on Android 10+ (API 29+).
     *
     * The old approach using MediaStore.Audio.Media.getContentUriForPath() and
     * MediaStore.MediaColumns.DATA is deprecated and broken on Android 10+.
     */
    private fun setSystemSound(filePath: String, title: String, type: Int): Boolean {
        return try {
            // 1. Check WRITE_SETTINGS permission (required for ringtone/notification/alarm)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.System.canWrite(this)) {
                val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                    .setData(Uri.parse("package:$packageName"))
                startActivity(intent)
                return false
            }

            val sourceFile = File(filePath)
            if (!sourceFile.exists()) {
                println("❌ Sound file not found: $filePath")
                return false
            }

            val isRingtone     = type == RingtoneManager.TYPE_RINGTONE
            val isNotification = type == RingtoneManager.TYPE_NOTIFICATION
            val isAlarm        = type == RingtoneManager.TYPE_ALARM

            // Determine the correct folder for this sound type
            val relativePath = when {
                isAlarm        -> "Alarms/"
                isNotification -> "Notifications/"
                else           -> "Ringtones/"
            }

            val soundUri: Uri

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+: use MediaStore without DATA column
                val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)

                // Delete existing entries with the same title AND same folder to avoid duplicates
                // Use both TITLE and RELATIVE_PATH to be precise
                contentResolver.delete(
                    collection,
                    "${MediaStore.MediaColumns.TITLE} = ? AND ${MediaStore.MediaColumns.RELATIVE_PATH} = ?",
                    arrayOf(title, relativePath)
                )

                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, "$title.mp3")
                    put(MediaStore.MediaColumns.TITLE, title)
                    put(MediaStore.MediaColumns.MIME_TYPE, "audio/mpeg")
                    put(MediaStore.Audio.Media.IS_RINGTONE,     if (isRingtone)     1 else 0)
                    put(MediaStore.Audio.Media.IS_NOTIFICATION, if (isNotification) 1 else 0)
                    put(MediaStore.Audio.Media.IS_ALARM,        if (isAlarm)        1 else 0)
                    put(MediaStore.Audio.Media.IS_MUSIC, 0)
                    put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                }

                val newUri = contentResolver.insert(collection, values)
                    ?: run { println("❌ MediaStore insert failed"); return false }

                // Write audio bytes
                contentResolver.openOutputStream(newUri)?.use { out ->
                    FileInputStream(sourceFile).use { it.copyTo(out) }
                }

                soundUri = newUri
            } else {
                // Android 9 and below: legacy approach
                @Suppress("DEPRECATION")
                val collection = MediaStore.Audio.Media.getContentUriForPath(filePath)!!

                contentResolver.delete(
                    collection,
                    "${MediaStore.MediaColumns.DATA} = ?",
                    arrayOf(filePath)
                )

                val values = ContentValues().apply {
                    @Suppress("DEPRECATION")
                    put(MediaStore.MediaColumns.DATA, filePath)
                    put(MediaStore.MediaColumns.TITLE, title)
                    put(MediaStore.MediaColumns.MIME_TYPE, "audio/mpeg")
                    put(MediaStore.MediaColumns.SIZE, sourceFile.length())
                    put(MediaStore.Audio.Media.IS_RINGTONE,     if (isRingtone)     1 else 0)
                    put(MediaStore.Audio.Media.IS_NOTIFICATION, if (isNotification) 1 else 0)
                    put(MediaStore.Audio.Media.IS_ALARM,        if (isAlarm)        1 else 0)
                    put(MediaStore.Audio.Media.IS_MUSIC, 0)
                }

                soundUri = contentResolver.insert(collection, values)
                    ?: run { println("❌ MediaStore insert failed (legacy)"); return false }
            }

            RingtoneManager.setActualDefaultRingtoneUri(this, type, soundUri)
            println("✅ System sound set: $title (type=$type, path=$relativePath, uri=$soundUri)")
            true
        } catch (e: Exception) {
            println("❌ setSystemSound error: ${e.message}")
            e.printStackTrace()
            false
        }
    }

    /**
     * Sets the app notification sound by recreating the SKS notification channel
     * with the new sound URI. Also updates the system notification sound.
     */
    private fun setAppNotificationSound(filePath: String, title: String): Boolean {
        return try {
            val sourceFile = File(filePath)
            if (!sourceFile.exists()) {
                println("❌ Notification sound file not found: $filePath")
                return false
            }

            // First insert into MediaStore to get a content URI
            val soundUri: Uri

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                contentResolver.delete(collection, "${MediaStore.MediaColumns.TITLE} = ?", arrayOf(title))

                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, "$title.mp3")
                    put(MediaStore.MediaColumns.TITLE, title)
                    put(MediaStore.MediaColumns.MIME_TYPE, "audio/mpeg")
                    put(MediaStore.Audio.Media.IS_NOTIFICATION, 1)
                    put(MediaStore.Audio.Media.IS_RINGTONE, 0)
                    put(MediaStore.Audio.Media.IS_ALARM, 0)
                    put(MediaStore.Audio.Media.IS_MUSIC, 0)
                    put(MediaStore.MediaColumns.RELATIVE_PATH, "Notifications/")
                }

                val newUri = contentResolver.insert(collection, values)
                    ?: run { println("❌ MediaStore insert failed"); return false }

                contentResolver.openOutputStream(newUri)?.use { out ->
                    FileInputStream(sourceFile).use { it.copyTo(out) }
                }
                soundUri = newUri
            } else {
                @Suppress("DEPRECATION")
                val collection = MediaStore.Audio.Media.getContentUriForPath(filePath)!!
                contentResolver.delete(collection, "${MediaStore.MediaColumns.DATA} = ?", arrayOf(filePath))

                val values = ContentValues().apply {
                    @Suppress("DEPRECATION")
                    put(MediaStore.MediaColumns.DATA, filePath)
                    put(MediaStore.MediaColumns.TITLE, title)
                    put(MediaStore.MediaColumns.MIME_TYPE, "audio/mpeg")
                    put(MediaStore.MediaColumns.SIZE, sourceFile.length())
                    put(MediaStore.Audio.Media.IS_NOTIFICATION, 1)
                    put(MediaStore.Audio.Media.IS_RINGTONE, 0)
                    put(MediaStore.Audio.Media.IS_ALARM, 0)
                    put(MediaStore.Audio.Media.IS_MUSIC, 0)
                }
                soundUri = contentResolver.insert(collection, values)
                    ?: run { println("❌ MediaStore insert failed (legacy)"); return false }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val audioAttr = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .build()

                // Recreate the SKS channel with the new sound
                nm.deleteNotificationChannel(ONESIGNAL_CHANNEL_ID)
                val channel = NotificationChannel(
                    ONESIGNAL_CHANNEL_ID,
                    ONESIGNAL_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "SKS spiritual updates and course notifications"
                    setSound(soundUri, audioAttr)
                    enableVibration(true)
                }
                nm.createNotificationChannel(channel)
                println("✅ App notification channel updated with new sound")
            }

            println("✅ App notification sound set: $title")
            true
        } catch (e: Exception) {
            println("❌ setAppNotificationSound error: ${e.message}")
            e.printStackTrace()
            false
        }
    }

    // ── Wallpaper ──────────────────────────────────────────────────────────────

    /**
     * Sets the wallpaper scaled to fit the screen without stretching.
     * Uses FIT_CENTER: scales the image to fit within the screen dimensions
     * while preserving aspect ratio. Black bars appear on sides/top if needed,
     * but the image is never distorted.
     */
    private fun setWallpaper(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) { println("❌ Wallpaper file not found: $filePath"); return false }

            val originalBitmap = BitmapFactory.decodeFile(file.absolutePath)
                ?: run { println("❌ Failed to decode wallpaper"); return false }

            val wallpaperManager = WallpaperManager.getInstance(applicationContext)
            val dm = resources.displayMetrics
            val targetW = dm.widthPixels
            val targetH = dm.heightPixels

            println("📱 Screen: ${targetW}×${targetH}")
            println("🖼️  Original: ${originalBitmap.width}×${originalBitmap.height}")

            // FIT_CENTER: scale to fit within screen, preserve aspect ratio, center it
            val imageAspect = originalBitmap.width.toFloat() / originalBitmap.height.toFloat()
            val screenAspect = targetW.toFloat() / targetH.toFloat()

            val scaledW: Int
            val scaledH: Int
            if (imageAspect > screenAspect) {
                // Image is wider — fit to width, letterbox top/bottom
                scaledW = targetW
                scaledH = (targetW / imageAspect).toInt()
            } else {
                // Image is taller — fit to height, pillarbox left/right
                scaledH = targetH
                scaledW = (targetH * imageAspect).toInt()
            }

            val scaled = android.graphics.Bitmap.createScaledBitmap(originalBitmap, scaledW, scaledH, true)

            // Create canvas with screen size, black background, image centered
            val canvas_bmp = android.graphics.Bitmap.createBitmap(targetW, targetH, android.graphics.Bitmap.Config.ARGB_8888)
            val canvas = android.graphics.Canvas(canvas_bmp)
            canvas.drawColor(android.graphics.Color.BLACK)
            val left = (targetW - scaledW) / 2f
            val top = (targetH - scaledH) / 2f
            canvas.drawBitmap(scaled, left, top, null)

            println("✨ Scaled: ${scaledW}×${scaledH}, centered at (${left.toInt()},${top.toInt()})")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                val screenRect = android.graphics.Rect(0, 0, targetW, targetH)
                wallpaperManager.setBitmap(canvas_bmp, screenRect, true,
                    WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK)
            } else {
                wallpaperManager.setBitmap(canvas_bmp)
            }

            if (scaled != originalBitmap) originalBitmap.recycle()
            scaled.recycle()

            println("✅ Wallpaper set — fit to screen, no stretching")
            true
        } catch (e: Exception) {
            println("❌ setWallpaper error: ${e.message}")
            e.printStackTrace()
            false
        }
    }

    // ── Settings / secure mode ─────────────────────────────────────────────────

    /**
     * Returns true if the current system sound for [type] contains "Sivoham" in its title/URI.
     */
    private fun isSivohamSet(type: Int): Boolean {
        return try {
            val uri = RingtoneManager.getActualDefaultRingtoneUri(this, type) ?: return false
            // Check URI string first (works for some devices)
            val uriStr = uri.toString().lowercase()
            if (uriStr.contains("sivoham")) return true
            // Check the title via RingtoneManager (more reliable)
            val ringtone = RingtoneManager.getRingtone(this, uri)
            val title = ringtone?.getTitle(this)?.lowercase() ?: ""
            if (title.contains("sivoham")) return true
            // Also query MediaStore by URI to get the title
            try {
                val cursor = contentResolver.query(uri, arrayOf(MediaStore.MediaColumns.TITLE), null, null, null)
                cursor?.use {
                    if (it.moveToFirst()) {
                        val mediaTitle = it.getString(0)?.lowercase() ?: ""
                        if (mediaTitle.contains("sivoham")) return true
                    }
                }
            } catch (ignored: Exception) {}
            false
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Returns true if the SKS notification channel currently uses the Sivoham sound.
     */
    private fun isSivohamAppNotificationSet(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = nm.getNotificationChannel(ONESIGNAL_CHANNEL_ID) ?: return false
            val soundUri = channel.sound ?: return false
            soundUri.toString().lowercase().contains("sivoham")
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Resets a system sound type back to the Android default.
     */
    private fun resetSystemSound(type: Int): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.System.canWrite(this)) {
                startActivity(Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).setData(Uri.parse("package:$packageName")))
                return false
            }
            // Setting null resets to the system default
            RingtoneManager.setActualDefaultRingtoneUri(this, type, null)
            println("✅ System sound reset to default (type=$type)")
            true
        } catch (e: Exception) {
            println("❌ resetSystemSound error: ${e.message}")
            false
        }
    }

    /**
     * Resets the app notification channel sound back to the Sivoham ringtone
     * (which is the SKS default). "Disable" here means restore to system default sound.
     */
    private fun resetAppNotificationSound(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.deleteNotificationChannel(ONESIGNAL_CHANNEL_ID)
            // Recreate with default system notification sound (null = system default)
            val audioAttr = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()
            val channel = NotificationChannel(
                ONESIGNAL_CHANNEL_ID,
                ONESIGNAL_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "SKS spiritual updates and course notifications"
                setSound(null, audioAttr) // null = system default
                enableVibration(true)
            }
            nm.createNotificationChannel(channel)
            println("✅ App notification sound reset to system default")
            true
        } catch (e: Exception) {
            println("❌ resetAppNotificationSound error: ${e.message}")
            false
        }
    }

    private fun openSystemSettings() {
        try {
            startActivity(
                Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                    .setData(Uri.parse("package:$packageName"))
            )
        } catch (e: Exception) { println("❌ openSystemSettings: ${e.message}") }
    }

    private fun enableSecureMode() {
        if (!isSecureMode) {
            window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
            isSecureMode = true
        }
    }

    private fun disableSecureMode() {
        if (isSecureMode) {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            isSecureMode = false
        }
    }
}
