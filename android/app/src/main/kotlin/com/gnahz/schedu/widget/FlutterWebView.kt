package com.gnahz.schedu.widget

import android.content.Context
import android.graphics.Bitmap
import android.net.http.SslError
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.webkit.ConsoleMessage
import android.webkit.CookieManager
import android.webkit.SslErrorHandler
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.BuildConfig
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

private const val VIEW_TYPE = "com.gnahz.schedu/flutter_webview"

class FlutterWebViewFactory(private val messenger: BinaryMessenger) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any?>
        return FlutterWebViewPlatformView(context, messenger, viewId, params)
    }
}

private class FlutterWebViewPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    params: Map<String, Any?>?
) : PlatformView {

    private val defaultUserAgent = WebSettings.getDefaultUserAgent(context)
    private val methodChannel = MethodChannel(messenger, "${VIEW_TYPE}_$viewId")
    private val extraHeaders = mapOf("X-Requested-With" to "")

    private val webView = WebView(context).apply webview@ {
        settings.apply {
            javaScriptEnabled = true
            javaScriptCanOpenWindowsAutomatically = true
            useWideViewPort = true
            loadWithOverviewMode = true
            cacheMode = WebSettings.LOAD_DEFAULT
            domStorageEnabled = true
            databaseEnabled = true
            builtInZoomControls = true
            displayZoomControls = false
            layoutAlgorithm = WebSettings.LayoutAlgorithm.NORMAL
            loadsImagesAutomatically = true
            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            userAgentString = defaultUserAgent
        }
        CookieManager.getInstance().apply {
            setAcceptCookie(true)
            setAcceptThirdPartyCookies(this@webview, true)
        }
        webViewClient = object : WebViewClient() {
            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                sendEvent("onPageStarted", mapOf("url" to url))
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                sendEvent(
                    "onPageFinished",
                    mapOf(
                        "url" to url,
                        "title" to view?.title
                    )
                )
            }

            override fun onReceivedError(
                view: WebView?,
                request: WebResourceRequest?,
                error: WebResourceError?
            ) {
                val description = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    error?.description?.toString() ?: "Unknown error"
                } else {
                    "Unknown error"
                }
                sendEvent(
                    "onWebResourceError",
                    mapOf("description" to description)
                )
            }

            override fun onReceivedSslError(
                view: WebView?,
                handler: SslErrorHandler?,
                error: SslError?
            ) {
                handler?.proceed()
            }

            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                request?.url?.toString()?.let {
                    Log.d("Test", "shouldOverrideUrlLoading: $it")
                    if (it.startsWith("http://") || it.startsWith("https://")) {
                        view?.loadUrl(it, extraHeaders)
                    }
                }
                return true
            }

        }
        webChromeClient = object : WebChromeClient() {
            override fun onProgressChanged(view: WebView?, newProgress: Int) {
                var progress = 0.0
                if (newProgress > 0) {
                    progress = newProgress / 100.0
                }
                sendEvent("onProgress", mapOf("progress" to progress))
                super.onProgressChanged(view, newProgress)
            }
        }
    }

    init {
        methodChannel.setMethodCallHandler(::onMethodCall)
        params?.get("url")?.toString()?.let {
            webView.loadUrl(it, extraHeaders)
        }
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadUrl" -> {
                val url = (call.arguments as? Map<*, *>)?.get("url") as? String
                if (!url.isNullOrEmpty()) {
                    webView.loadUrl(url, extraHeaders)
                }
                result.success(null)
            }

            "reload" -> {
                webView.reload()
                result.success(null)
            }

            "canGoBack" -> result.success(webView.canGoBack())
            "canGoForward" -> result.success(webView.canGoForward())

            "goBack" -> {
                webView.goBack()
                result.success(null)
            }

            "goForward" -> {
                webView.goForward()
                result.success(null)
            }

            "runJavascript" -> {
                val script = (call.arguments as? Map<*, *>)?.get("script") as? String ?: ""
                webView.evaluateJavascript(script) {
                    result.success(it)
                }
            }

            "getTitle" -> result.success(webView.title)
            "clearLocalStorage" -> {
                webView.clearHistory()
                webView.clearCache(true)
                result.success(null)
            }

            "clearCookies" -> {
                CookieManager.getInstance().removeAllCookies { result.success(null) }
            }

            "setUserAgent" -> {
                val userAgent = (call.arguments as? Map<*, *>)?.get("userAgent") as? String
                webView.settings.userAgentString = userAgent ?: defaultUserAgent
                webView.reload()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun sendEvent(method: String, arguments: Any?) {
        Handler(Looper.getMainLooper()).post {
            try {
                methodChannel.invokeMethod(method, arguments)
            } catch (e: Exception) {
                Log.w("FlutterWebView", "Failed to send event: $method", e)
            }
        }
    }

    override fun getView(): WebView = webView

    override fun dispose() {
        methodChannel.setMethodCallHandler(null)
        webView.apply {
            loadUrl("about:blank")
            stopLoading()
            webChromeClient = null
            removeAllViews()
            destroy()
        }
    }
}