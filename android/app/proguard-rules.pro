# Keep notification resources
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keep class * extends java.lang.Enum

# Keep notification icons
-keep class **.R$drawable
-keep class **.R$mipmap
-keep class **.R$raw

# Keep notification channel
-keep class * extends android.app.NotificationChannel
-keep class * extends android.app.NotificationManager 