package com.gnahz.schedu

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import com.gnahz.schedu.appwidget.DailyCourseWidgetReceiver
import com.gnahz.schedu.widget.FlutterWebViewFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    companion object {
        const val MAIN_CHANNEL = "com.gnahz.schedu/main"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.gnahz.schedu/flutter_webview",
            FlutterWebViewFactory(flutterEngine.dartExecutor.binaryMessenger)
        )
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MAIN_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "addDailyWidget" -> handleAddDailyWidget(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleAddDailyWidget(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error("UNSUPPORTED", "该功能需要Android 8.0及以上系统", null)
            return
        }

        val appWidgetManager = AppWidgetManager.getInstance(this)
        if (!appWidgetManager.isRequestPinAppWidgetSupported) {
            result.error("UNSUPPORTED", "当前桌面不支持固定小组件", null)
            return
        }

        // 小米系统需申请com.android.launcher.permission.INSTALL_SHORTCUT权限
        if (Build.MANUFACTURER.equals("Xiaomi", ignoreCase = true)) {
            //TODO: 事真多
        }

        val provider = ComponentName(this, DailyCourseWidgetReceiver::class.java)
        val success = appWidgetManager.requestPinAppWidget(provider, null, null)
        if (success) {
            result.success(true)
        } else {
            result.error("FAILED", "系统无法发起添加小组件请求", null)
        }
    }
}
