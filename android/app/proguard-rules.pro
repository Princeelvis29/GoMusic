# Keep WorkManager and Room database classes from being stripped by R8 in Release Mode
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class androidx.sqlite.** { *; }
-keep class androidx.startup.** { *; }

# Keep all classes that implement Worker
-keep class * extends androidx.work.Worker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}