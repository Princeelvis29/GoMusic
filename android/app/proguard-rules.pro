# 1. Keep WorkManager and Room database classes (From our previous fix)
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class androidx.sqlite.** { *; }
-keep class androidx.startup.** { *; }
-keep class * extends androidx.work.Worker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# 2. Keep Audio Service and ExoPlayer (just_audio) classes
-keep class com.ryanheise.** { *; }
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }
-keep class androidx.media3.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# 3. Keep Audio Query classes
-keep class com.lucasjosino.on_audio_query.** { *; }

# 4. Keep Google Mobile Ads (AdMob) classes just to be safe
-keep class com.google.android.gms.ads.** { *; }