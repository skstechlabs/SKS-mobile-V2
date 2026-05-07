# ─────────────────────────────────────────────────────────────────────────────
# Flutter
# ─────────────────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# ─────────────────────────────────────────────────────────────────────────────
# Google Sign-In (google_sign_in_android 7.x — uses Credential Manager)
# These classes are loaded reflectively and MUST NOT be stripped.
# ─────────────────────────────────────────────────────────────────────────────

# The plugin itself
-keep class io.flutter.plugins.googlesignin.** { *; }

# AndroidX Credential Manager — core
-keep class androidx.credentials.** { *; }
-keep interface androidx.credentials.** { *; }
-dontwarn androidx.credentials.**

# AndroidX Credential Manager — exceptions
-keep class androidx.credentials.exceptions.** { *; }
-dontwarn androidx.credentials.exceptions.**

# Google Identity library (googleid) — provides GoogleIdTokenCredential
-keep class com.google.android.libraries.identity.googleid.** { *; }
-dontwarn com.google.android.libraries.identity.googleid.**

# Google Identity Services — authorization
-keep class com.google.android.gms.auth.api.identity.** { *; }
-dontwarn com.google.android.gms.auth.api.identity.**

# Google Play Services — common
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Android resource lookup for default_web_client_id
# (used by google_sign_in_android to read serverClientId from google-services.json)
-keepclassmembers class **.R$string {
    public static final int default_web_client_id;
}

# ─────────────────────────────────────────────────────────────────────────────
# Firebase
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ─────────────────────────────────────────────────────────────────────────────
# OneSignal
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# ─────────────────────────────────────────────────────────────────────────────
# WebView (MSG91 OTP widget)
# ─────────────────────────────────────────────────────────────────────────────
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}

# ─────────────────────────────────────────────────────────────────────────────
# App entry points
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.spiritual.app.** { *; }
-keep class com.spiritual.app.MainActivity { *; }

# ─────────────────────────────────────────────────────────────────────────────
# Kotlin
# ─────────────────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**

# ─────────────────────────────────────────────────────────────────────────────
# Reflection / annotations (required by many libraries)
# ─────────────────────────────────────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepattributes InnerClasses
-keepattributes EnclosingMethod
