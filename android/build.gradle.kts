import javax.xml.parsers.DocumentBuilderFactory

allprojects {
    // 与 settings.gradle.kts 一致，仅阿里云镜像
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/jcenter") }
    }
}

// 旧版 Flutter 插件未声明 namespace 时，AGP 8+ 会配置失败；从 AndroidManifest 的 package 自动补齐
subprojects {
    plugins.withId("com.android.library") {
        val androidExt =
            extensions.findByName("android") ?: return@withId
        val currentNs =
            runCatching {
                androidExt.javaClass.getMethod("getNamespace").invoke(androidExt) as String?
            }.getOrNull()
        if (!currentNs.isNullOrBlank()) return@withId

        val manifestFile = layout.projectDirectory.file("src/main/AndroidManifest.xml").asFile
        if (!manifestFile.exists()) return@withId

        val pkg =
            runCatching {
                DocumentBuilderFactory.newInstance().newDocumentBuilder()
                    .parse(manifestFile).documentElement.getAttribute("package")
            }.getOrNull()
        if (pkg.isNullOrBlank()) return@withId

        runCatching {
            androidExt.javaClass.getMethod("setNamespace", String::class.java)
                .invoke(androidExt, pkg)
        }
    }
}

// 旧插件若 compileSdk 过低，合并资源时可能缺少 android:attr/lStar（API 31+），与主工程对齐到 34
subprojects {
    afterEvaluate {
        if (!plugins.hasPlugin("com.android.library")) return@afterEvaluate
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        val targetSdk = 34
        runCatching {
            val get =
                androidExt.javaClass.methods.find { it.name == "getCompileSdk" }
                    ?: androidExt.javaClass.methods.find { it.name == "getCompileSdkVersion" }
            val cur =
                when (val v = get?.invoke(androidExt)) {
                    is Int -> v
                    is Number -> v.toInt()
                    else -> 0
                }
            if (cur >= targetSdk) return@runCatching
            val set =
                androidExt.javaClass.methods.find {
                    it.name == "setCompileSdk" &&
                        it.parameterTypes.size == 1 &&
                        it.parameterTypes[0] == Integer.TYPE
                } ?: androidExt.javaClass.methods.find {
                    it.name == "setCompileSdkVersion" &&
                        it.parameterTypes.size == 1 &&
                        it.parameterTypes[0] == Integer.TYPE
                }
            set?.invoke(androidExt, targetSdk)
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
