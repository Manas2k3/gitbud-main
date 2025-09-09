# ================================
# ✨ Flutter & Icon Fixes
# ================================

# Keep Flutter embedding and plugins
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant

# Keep Material icons and related classes
-keep class com.google.android.material.** { *; }

# Fix for MaterialIcons missing in release
-keep class androidx.** { *; }

# ================================
# ⚙️ Third-party SDKs
# ================================

# Razorpay
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# ZEGO SDK
-keep class **.zego.** { *; }

# ITGSA SDK (Media, Karaoke, etc.)
-keep class com.itgsa.opensdk.** { *; }
-dontwarn com.itgsa.opensdk.**

# for in app image cropping
-keep class com.yalantis.ucrop.** { *; }


# Paisa (Google InApp Client)
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }

# ================================
# 🔒 Annotations & Plugin Stuff
# ================================

# Keep classes/members annotated with @Keep
-keep class proguard.annotation.** { *; }
-keepclassmembers class * {
    @proguard.annotation.Keep *;
    @proguard.annotation.KeepClassMembers *;
}

# ================================
# 🛡️ Prevent R8 Crash (Play Core)
# ================================

# Ignore missing classes from deferred components / dynamic delivery
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.** 

# Suppress warnings for unused Java desktop APIs (common)
-dontwarn java.beans.**
-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry
