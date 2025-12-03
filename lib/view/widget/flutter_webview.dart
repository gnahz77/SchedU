import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

/// 页面加载完成回调
typedef WebViewPageFinishedCallback = void Function(String? url, String? title);

/// 控制 FlutterWebView 的控制器
class FlutterWebViewController {
  final Completer<void> _readyCompleter = Completer<void>();
  MethodChannel? _channel;

  void _setChannel(MethodChannel channel) {
    _channel = channel;
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
  }

  Future<T?> _invoke<T>(String method, [dynamic arguments]) async {
    await _readyCompleter.future;
    final channel = _channel;
    if (channel == null) return null;
    return channel.invokeMethod<T>(method, arguments);
  }

  /// 加载指定 URL
  Future<void> loadUrl(String url) => _invoke('loadUrl', {'url': url});
  /// 刷新当前页面
  Future<void> reload() => _invoke('reload');
  /// 是否可以返回到上一个页面
  Future<bool> canGoBack() async => (await _invoke<bool>('canGoBack')) ?? false;
  /// 是否可以前进到下一个页面
  Future<bool> canGoForward() async => (await _invoke<bool>('canGoForward')) ?? false;
  /// 返回到上一个页面
  Future<void> goBack() => _invoke('goBack');
  /// 前进到下一个页面
  Future<void> goForward() => _invoke('goForward');
  /// 执行 JavaScript 脚本
  Future<String?> runJavaScriptReturningResult(String script) => _invoke<String>('runJavascript', {'script': script});
  /// 获取当前页面标题
  Future<String?> getTitle() => _invoke<String>('getTitle');
  /// 清除本地存储数据
  Future<void> clearLocalStorage() => _invoke('clearLocalStorage');
  /// 清除 Cookie 数据
  Future<void> clearCookies() => _invoke('clearCookies');
  /// 设置 User-Agent
  Future<void> setUserAgent(String? userAgent) => _invoke('setUserAgent', {'userAgent': userAgent});
  /// 设置桌面模式
  Future<void> setDesktopMode(bool enable) => setUserAgent(
        enable
            ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36'
            : null,
      );
}

/// WebView的平台抽象接口
/// 暂时只实现了 Android 平台，其他平台请自行实现并注册
abstract class FlutterWebViewPlatform {
  const FlutterWebViewPlatform();

  static FlutterWebViewPlatform _instance =
      const _AndroidFlutterWebViewPlatform();

  static FlutterWebViewPlatform get instance => _instance;

  static set instance(FlutterWebViewPlatform platform) {
    _instance = platform;
  }

  Widget buildPlatformView({
    Key? key,
    required PlatformViewCreatedCallback onPlatformViewCreated,
    Map<String, dynamic>? params,
  });
}

/// Android 平台的 FlutterWebView 实现
class _AndroidFlutterWebViewPlatform extends FlutterWebViewPlatform {
  const _AndroidFlutterWebViewPlatform();

  @override
  Widget buildPlatformView({
    Key? key,
    required PlatformViewCreatedCallback onPlatformViewCreated,
    Map<String, dynamic>? params,
  }) {
    assert(
      defaultTargetPlatform == TargetPlatform.android,
      'FlutterWebView 默认实现仅支持 Android，请注册自定义平台。',
    );
    return AndroidView(
      key: key,
      viewType: 'com.gnahz.schedu/flutter_webview',
      onPlatformViewCreated: onPlatformViewCreated,
      creationParams: params,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

/// Flutter WebView 组件
class FlutterWebView extends StatefulWidget {
  final FlutterWebViewController controller;
  final ValueChanged<String?>? onPageStarted;
  final ValueChanged<double>? onProgress;
  final WebViewPageFinishedCallback? onPageFinished;
  final ValueChanged<String>? onWebResourceError;

  const FlutterWebView({
    super.key,
    required this.controller,
    this.onPageStarted,
    this.onProgress,
    this.onPageFinished,
    this.onWebResourceError,
  });

  @override
  State<FlutterWebView> createState() => _FlutterWebViewState();
}

class _FlutterWebViewState extends State<FlutterWebView> {
  MethodChannel? _methodChannel;

  void _onPlatformViewCreated(int viewId) {
    final channel = MethodChannel('com.gnahz.schedu/flutter_webview_$viewId');
    widget.controller._setChannel(channel);
    _methodChannel = channel;
    channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    final args = call.arguments as Map<dynamic, dynamic>?;
    switch (call.method) {
      case 'onPageStarted':
        widget.onPageStarted?.call(args?['url'] as String?);
        break;
      case 'onProgress':
        final progress = args?['progress'] as double? ?? 0;
        widget.onProgress?.call(progress);
        break;
      case 'onPageFinished':
        widget.onPageFinished?.call(
          args?['url'] as String?,
          args?['title'] as String?,
        );
        break;
      case 'onWebResourceError':
        widget.onWebResourceError
            ?.call(args?['description'] as String? ?? '加载失败');
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _methodChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterWebViewPlatform.instance.buildPlatformView(
      key: widget.key,
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }
}
