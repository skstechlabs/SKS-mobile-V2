package com.spiritual.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.WallpaperManager
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

class MainActivity: FlutterActivity() {
    private val SECURITY_CHANNEL = "com.spiritual.app/security"
    private val RINGTONE_CHANNEL = "com.spiritual.app/ringtone"
    private val WALLPAPER_CHANNEL = "com.spiritual.app/wallpaper"
    private var isSecureMode = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Security channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecureMode" -> {
                    enableSecureMode()
                    result.success(true)
                }
                "disableSecureMode" -> {
                    disableSecureMode()
                    result.success(true)
                }
                "checkScreenRecording" -> {
                    result.success(isSecureMode)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Ringtone channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RINGTONE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setRingtone" -> {
                    val path = call.argument<String>("path")
                    val title = call.argument<String>("title") ?: "Ringtone"
                    if (path != null) {
                        val success = setRingtone(path, title, RingtoneManager.TYPE_RINGTONE)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is required", null)
                    }
                }
                "setNotification" -> {
                    val path = call.argument<String>("path")
                    val title = call.argument<String>("title") ?: "Notification"
                    if (path != null) {
                        val success = setRingtone(path, title, RingtoneManager.TYPE_NOTIFICATION)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is required", null)
                    }
                }
                "setAlarm" -> {
                    val path = call.argument<String>("path")
                    val title = call.argument<String>("title") ?: "Alarm"
                    if (path != null) {
                        val success = setRingtone(path, title, RingtoneManager.TYPE_ALARM)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is required", null)
                    }
                }
                "setAppNotification" -> {
                    val path = call.argument<String>("path")
                    val title = call.argument<String>("title") ?: "App Notification"
                    if (path != null) {
                        val success = setAppNotificationSound(path, title)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is required", null)
                    }
                }
                "openSettings" -> {
                    openSystemSettings()
                    result.success(true)
                }
                "checkPermission" -> {
                    val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.System.canWrite(this)
                    } else {
                        true
                    }
                    result.success(hasPermission)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Wallpaper channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WALLPAPER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setWallpaper" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        val success = setWallpaper(path)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun setWallpaper(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) {
                println("❌ Wallpaper file does not exist: $filePath")
                return false
            }

            // Decode the image
            val originalBitmap = BitmapFactory.decodeFile(file.absolutePath)
            if (originalBitmap == null) {
                println("❌ Failed to decode wallpaper image")
                return false
            }

            val wallpaperManager = WallpaperManager.getInstance(applicationContext)
            
            // Get screen dimensions
            val displayMetrics = resources.displayMetrics
            val screenWidth = displayMetrics.widthPixels
            val screenHeight = displayMetrics.heightPixels
            
            println("📱 Screen size: ${screenWidth}x${screenHeight}")
            println("🖼️ Original image size: ${originalBitmap.width}x${originalBitmap.height}")
            
            // Calculate scaling to fit entire image on screen (letterbox/pillarbox if needed)
            // This ensures the entire photo is visible without cropping
            val imageAspect = originalBitmap.width.toFloat() / originalBitmap.height.toFloat()
            val screenAspect = screenWidth.toFloat() / screenHeight.toFloat()
            
            val scaledBitmap = if (imageAspect > screenAspect) {
                // Image is wider than screen - fit to width (letterbox top/bottom)
                val scaledWidth = screenWidth
                val scaledHeight = (screenWidth / imageAspect).toInt()
                android.graphics.Bitmap.createScaledBitmap(originalBitmap, scaledWidth, scaledHeight, true)
            } else {
                // Image is taller than screen - fit to height (pillarbox left/right)
                val scaledHeight = screenHeight
                val scaledWidth = (screenHeight * imageAspect).toInt()
                android.graphics.Bitmap.createScaledBitmap(originalBitmap, scaledWidth, scaledHeight, true)
            }
            
            println("✨ Scaled image size: ${scaledBitmap.width}x${scaledBitmap.height}")
            
            // Create a canvas with screen dimensions and black background
            val finalBitmap = android.graphics.Bitmap.createBitmap(screenWidth, screenHeight, android.graphics.Bitmap.Config.ARGB_8888)
            val canvas = android.graphics.Canvas(finalBitmap)
            
            // Fill with black background (or you can use any color)
            canvas.drawColor(android.graphics.Color.BLACK)
            
            // Calculate position to center the image
            val left = (screenWidth - scaledBitmap.width) / 2f
            val top = (screenHeight - scaledBitmap.height) / 2f
            
            // Draw the scaled image centered on the canvas
            canvas.drawBitmap(scaledBitmap, left, top, null)
            
            println("🎨 Final wallpaper size: ${finalBitmap.width}x${finalBitmap.height}")
            println("📍 Image positioned at: left=$left, top=$top")
            
            // Set wallpaper with proper flags for both lock and home screen
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Set for both home and lock screen
                wallpaperManager.setBitmap(finalBitmap, null, true, WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK)
            } else {
                wallpaperManager.setBitmap(finalBitmap)
            }
            
            // Clean up
            if (scaledBitmap != originalBitmap) {
                originalBitmap.recycle()
            }
            scaledBitmap.recycle()
            
            println("✅ Wallpaper set successfully - entire image visible without cropping")
            true
        } catch (e: Exception) {
            println("❌ Error setting wallpaper: ${e.message}")
            e.printStackTrace()
            false
        }
    }

    private fun setRingtone(filePath: String, title: String, type: Int): Boolean {
        return try {
            // Check if we have permission to write settings
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (!Settings.System.canWrite(this)) {
                    // Request permission
                    val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                    intent.data = Uri.parse("package:$packageName")
                    startActivity(intent)
                    return false
                }
            }

            val file = File(filePath)
            if (!file.exists()) {
                println("❌ Ringtone file does not exist: $filePath")
                return false
            }

            // Delete existing entry if it exists
            val existingUri = MediaStore.Audio.Media.getContentUriForPath(file.absolutePath)
            contentResolver.delete(
                existingUri!!,
                MediaStore.MediaColumns.DATA + "=?",
                arrayOf(file.absolutePath)
            )

            // Insert into MediaStore
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DATA, file.absolutePath)
                put(MediaStore.MediaColumns.TITLE, title)
                put(MediaStore.MediaColumns.MIME_TYPE, "audio/mpeg")
                put(MediaStore.MediaColumns.SIZE, file.length())
                put(MediaStore.Audio.Media.IS_RINGTONE, type == RingtoneManager.TYPE_RINGTONE)
                put(MediaStore.Audio.Media.IS_NOTIFICATION, type == RingtoneManager.TYPE_NOTIFICATION)
                put(MediaStore.Audio.Media.IS_ALARM, type == RingtoneManager.TYPE_ALARM)
                put(MediaStore.Audio.Media.IS_MUSIC, false)
            }

            val uri = MediaStore.Audio.Media.getContentUriForPath(file.absolutePath)
            val newUri = contentResolver.insert(uri!!, values)

            if (newUri != null) {
                RingtoneManager.setActualDefaultRingtoneUri(this, type, newUri)
                println("✅ Ringtone set successfully: $title (type: $type)")
                return true
            }

            println("❌ Failed to insert ringtone into MediaStore")
            false
        } catch (e: Exception) {
            println("❌ Error setting ringtone: ${e.message}")
            e.printStackTrace()
            false
        }
    }

    private fun setAppNotificationSound(filePath: String, title: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) {
                println("❌ Notification sound file does not exist: $filePath")
                return false
            }

            // First, add to MediaStore
            val existingUri = MediaStore.Audio.Media.getContentUriForPath(file.absolutePath)
            contentResolver.delete(
                existingUri!!,
                MediaStore.MediaColumns.DATA + "=?",
                arrayOf(file.absolutePath)
            )

            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DATA, file.absolutePath)
                put(MediaStore.MediaColumns.TITLE, title)
                put(MediaStore.MediaColumns.MIME_TYPE, "audio/mpeg")
                put(MediaStore.MediaColumns.SIZE, file.length())
                put(MediaStore.Audio.Media.IS_RINGTONE, false)
                put(MediaStore.Audio.Media.IS_NOTIFICATION, true)
                put(MediaStore.Audio.Media.IS_ALARM, false)
                put(MediaStore.Audio.Media.IS_MUSIC, false)
            }

            val uri = MediaStore.Audio.Media.getContentUriForPath(file.absolutePath)
            val soundUri = contentResolver.insert(uri!!, values)

            if (soundUri == null) {
                println("❌ Failed to insert notification sound into MediaStore")
                return false
            }

            // Create/Update notification channel with custom sound for Android O and above
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                
                // Delete existing channels to update sound
                val existingChannels = listOf(
                    "default_channel",
                    "reminders_channel",
                    "events_channel",
                    "general_channel"
                )
                
                existingChannels.forEach { channelId ->
                    try {
                        notificationManager.deleteNotificationChannel(channelId)
                    } catch (e: Exception) {
                        println("⚠️ Could not delete channel $channelId: ${e.message}")
                    }
                }
                
                // Create audio attributes
                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .build()
                
                // Create notification channels with custom sound
                val channels = listOf(
                    NotificationChannel(
                        "default_channel",
                        "General Notifications",
                        NotificationManager.IMPORTANCE_DEFAULT
                    ).apply {
                        description = "General app notifications"
                        setSound(soundUri, audioAttributes)
                        enableVibration(true)
                    },
                    NotificationChannel(
                        "reminders_channel",
                        "Meditation Reminders",
                        NotificationManager.IMPORTANCE_HIGH
                    ).apply {
                        description = "Meditation and practice reminders"
                        setSound(soundUri, audioAttributes)
                        enableVibration(true)
                    },
                    NotificationChannel(
                        "events_channel",
                        "Event Notifications",
                        NotificationManager.IMPORTANCE_DEFAULT
                    ).apply {
                        description = "Event updates and reminders"
                        setSound(soundUri, audioAttributes)
                        enableVibration(true)
                    },
                    NotificationChannel(
                        "general_channel",
                        "App Updates",
                        NotificationManager.IMPORTANCE_LOW
                    ).apply {
                        description = "General app updates and information"
                        setSound(soundUri, audioAttributes)
                        enableVibration(false)
                    }
                )
                
                channels.forEach { channel ->
                    notificationManager.createNotificationChannel(channel)
                    println("✅ Created notification channel: ${channel.id} with custom sound")
                }
            }

            println("✅ App notification sound set successfully for all channels")
            true
        } catch (e: Exception) {
            println("❌ Error setting app notification sound: ${e.message}")
            e.printStackTrace()
            false
        }
    }

    private fun openSystemSettings() {
        try {
            val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        } catch (e: Exception) {
            println("❌ Error opening settings: ${e.message}")
        }
    }

    private fun enableSecureMode() {
        if (!isSecureMode) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
            isSecureMode = true
            println("🔒 FLAG_SECURE enabled - Screenshots and screen recording blocked")
        }
    }

    private fun disableSecureMode() {
        if (isSecureMode) {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            isSecureMode = false
            println("🔓 FLAG_SECURE disabled")
        }
    }

    override fun onResume() {
        super.onResume()
        // Re-enable secure mode when app resumes
        if (isSecureMode) {
            enableSecureMode()
        }
    }
}
