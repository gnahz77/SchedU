## FlutterWebView 实现说明

### 组件简介

`FlutterWebView` 是 SchedU 项目自定义实现的 WebView 组件，主要用于教务系统网页的嵌入与交互，支持页面加载、进度、错误、JavaScript 执行等功能。
当前仅适配 Android 平台（基于 PlatformView），后续将扩展其他平台的实现。

### 架构设计

- **控制器（FlutterWebViewController）**  
  提供加载 URL、刷新、前进/后退、执行 JS、获取标题、清理 Cookie/本地存储、设置 User-Agent 等方法。通过 MethodChannel 与原生通信。
- **平台抽象（FlutterWebViewPlatform）**  
  采用平台适配模式，当前仅实现 Android（_AndroidFlutterWebViewPlatform），后续将扩展 iOS 自定义实现。
- **组件本体（FlutterWebView）**  
  StatefulWidget，负责创建 PlatformView 并监听原生事件（如 onPageStarted、onProgress、onPageFinished、onWebResourceError），通过回调暴露给上层。

### 主要流程

1. **初始化**  
   创建 `FlutterWebViewController` 并传入 `FlutterWebView` 组件。
2. **平台视图创建**  
   通过 `FlutterWebViewPlatform.instance.buildPlatformView` 创建原生 WebView（Android 使用 AndroidView）。
3. **通信机制**  
   使用 `MethodChannel` 实现 Flutter 与原生的双向通信，支持方法调用与事件回调。
4. **事件回调**  
   页面加载、进度、错误等事件通过 MethodChannel 回调到 Flutter 层，触发对应回调函数。
5. **扩展性**  
   通过继承 `FlutterWebViewPlatform` 可扩展支持其他平台。

### 用法示例

```dart
final controller = FlutterWebViewController();

FlutterWebView(
  controller: controller,
  onPageStarted: (url) => print('开始加载: $url'),
  onProgress: (progress) => print('加载进度: $progress'),
  onPageFinished: (url, title) => print('加载完成: $title'),
  onWebResourceError: (desc) => print('加载错误: $desc'),
)
```

### 相关文件

- [flutter_webview.dart](lib/view/widget/flutter_webview.dart)：FlutterWebView 组件及控制器实现
- 原生端代码：见 Android 平台相关实现 [FlutterWebView.kt](android/app/src/main/kotlin/com/gnahz/schedu/widget/FlutterWebView.kt)