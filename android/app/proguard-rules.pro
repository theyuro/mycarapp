# O app usa somente o reconhecedor de texto latino. O plugin referencia
# reconhecedores opcionais que não são empacotados nesta versão.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# --- WorkManager / Room / App Startup -----------------------------------------
# Crash 1.3.0 (7): "Failed to create an instance of androidx.work.impl.WorkDatabase".
# O WorkManager chega como dependência transitiva do google_mobile_ads
# (play-services-ads-api -> androidx.work:work-runtime) e é inicializado pelo
# androidx.startup.InitializationProvider na abertura do app.

# O Room localiza a implementação gerada do banco por reflexão
# (Room.getGeneratedImplementation -> Class.forName("<Nome>_Impl").newInstance()).
# Sem referência direta no código, o R8 remove a classe ou o construtor sem argumentos.
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}

# WorkDatabase_Impl é o banco interno do WorkManager, criado pela regra acima;
# mantido explicitamente por ser exatamente a classe ausente no stack trace.
-keep class androidx.work.impl.WorkDatabase_Impl { *; }

# Workers, InputMerger e demais classes do WorkManager são instanciados por nome
# (reflexão) a partir do que foi persistido no banco; manter o pacote inteiro
# evita que o R8 remova ou renomeie classes resolvidas só em tempo de execução.
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# O InitializationProvider lê os Initializers declarados no AndroidManifest
# (meta-data) e os instancia por reflexão com o construtor sem argumentos
# (ex.: androidx.work.WorkManagerInitializer).
-keep class * implements androidx.startup.Initializer {
    <init>();
}
