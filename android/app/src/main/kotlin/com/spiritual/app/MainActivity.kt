package com.spiritual.app

import android.content.ContentValues
import android.content.Intent
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
                "openSettings" -> {
                    openSystemSettings()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
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
                println("File does not exist: $filePath")
                return false
            }

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
                println("✅ Ringtone set successfully: $title")
                return true
            }

            false
        } catch (e: Exception) {
            println("❌ Error setting ringtone: ${e.message}")
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
            println("Error opening settings: ${e.message}")
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
