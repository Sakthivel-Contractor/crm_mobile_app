# Flutter and most plugins ship their own consumer R8 rules.

# shared_preferences_android >= 2.5 is called from Dart through JNI: classes
# and methods are looked up by name and by exact JVM signature. It ships no
# keep rules, so without these R8 renames the Kotlin types in those
# signatures (e.g. kotlin.coroutines.Continuation) and every SharedPreferences
# call fails in release builds — the app then can't read its saved server
# URL, language or settings.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.Unit { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.enums.EnumEntries { *; }
-keep class kotlin.jvm.internal.DefaultConstructorMarker { *; }
