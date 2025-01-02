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
