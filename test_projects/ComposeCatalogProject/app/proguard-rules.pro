# Default Proguard rules for ComposeCatalogProject
-keepattributes *Annotation*
-keepclassmembers class * {
    @androidx.annotation.Keep <methods>;
}
