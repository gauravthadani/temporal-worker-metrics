plugins {
    java
    application
    id("com.github.johnrengelman.shadow") version "8.1.1"
}

group = "io.temporal.samples"
version = "1.0.0"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(17))
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("io.temporal:temporal-sdk:1.35.0")
    implementation("org.slf4j:slf4j-api:2.0.13")
    implementation("ch.qos.logback:logback-classic:1.5.6")
}

application {
    mainClass.set("io.temporal.samples.helloworld.WorkerMain")
}

tasks.named<com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar>("shadowJar") {
    archiveBaseName.set("worker")
    archiveClassifier.set("")
    archiveVersion.set("")
    manifest {
        attributes["Main-Class"] = "io.temporal.samples.helloworld.WorkerMain"
    }
    mergeServiceFiles()
}

tasks.register<com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar>("starterJar") {
    dependsOn("classes")
    archiveBaseName.set("starter")
    archiveClassifier.set("")
    archiveVersion.set("")
    from(sourceSets.main.get().output)
    configurations = listOf(project.configurations.runtimeClasspath.get())
    manifest {
        attributes["Main-Class"] = "io.temporal.samples.helloworld.StarterMain"
    }
    mergeServiceFiles()
}

tasks.named("build") {
    dependsOn("shadowJar", "starterJar")
}
