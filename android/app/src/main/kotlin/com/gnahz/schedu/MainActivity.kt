package com.gnahz.schedu

import com.gnahz.schedu.widget.FlutterWebViewFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.gnahz.schedu/flutter_webview",
            FlutterWebViewFactory(flutterEngine.dartExecutor.binaryMessenger)
        )
    }

}
