# shared_preferences_android 2.5.0 switched to Pigeon JNI on Android.
# In release builds, R8 can rename Kotlin standard-library classes looked up
# by name (including the Continuation parameter to getAll), causing a
# NoSuchMethodError before runApp() and leaving the splash screen visible.
#
# Keep these JNI-linked Kotlin types while retaining release optimizations.
# Derived from the Pigeon JNI / shared_preferences_android 2.5.0 workaround.
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }
