# What is this?
It's a flutter demo for AgoraMarketPlace SenseTime beauty extensions,that can allow you running on Android and IOS.

AgoraMarketPlace(EN): https://www.agora.io/en/agora-extensions-marketplace/
AgoraMarketPlace(CN): https://www.shengwang.cn/cn/marketplace

# How to use?
1. Download the extensions and resource from [README.md](README.md)
2. Put extension and resource into project like this:
```
├── android
│   |
│   └── libs //extension file for android
│        |
│        └──extension_aar-release.aar // aar file
│   └── build.gradle
├── ios
|    |
|    └──AgoraSenseTimeExtension.framework //extensions framework for iOS
|    └──AgoraSenseTimeExtension.framework.dSYM //extensions framework for iOS
├── lib
|__ Resource
```
3. flutter pub get & flutter run

# How to use my own license and run?
1. Change the applicationId to your own.(Aka BundleIdentifier in Xcode)
```gradle
    defaultConfig {
        // TODO: Change the applicationId to your own, if you have changed your own license.bundle
        applicationId "io.agora.rte.extension.sensetime"

        minSdkVersion flutter.minSdkVersion
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }
```
2. Change license file in Resource/license/SenseMARS_Effects.lic

# PS
If you want to use extension in your own android porject,pls check and add these code to your android/app/src/main/kotlin/com/example/st_flutter/MainActivity.kt
```kotlin
package com.example.st_flutter

import android.os.Bundle
import io.agora.rte.extension.sensetime.ExtensionManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        ExtensionManager.getInstance(null).initialize(this)

        super.onCreate(savedInstanceState)
    }
}

```