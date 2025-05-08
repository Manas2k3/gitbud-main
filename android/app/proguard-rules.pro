# Keep Razorpay classes
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Keep Paisa (InApp Client)
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }

# Keep Proguard annotations
-keep class proguard.annotation.** { *; }
-keepclassmembers class * {
    @proguard.annotation.Keep *;
    @proguard.annotation.KeepClassMembers *;
}

# Keep ZEGO SDK classes
-keep class **.zego.** { *; }

# Keep ITGSA SDK (Karaoke, MediaClient, etc.)
-keep class com.itgsa.opensdk.** { *; }
-dontwarn com.itgsa.opensdk.**

# Suppress missing Java classes used by Jackson (not available on Android)
-dontwarn java.beans.**
-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry
