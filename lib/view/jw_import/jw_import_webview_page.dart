import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/jw_import/jw_import_webview_bloc.dart';
import 'package:schedu/bloc/jw_import/jw_import_webview_event.dart';
import 'package:schedu/bloc/jw_import/jw_import_webview_state.dart';
import 'package:schedu/bloc/jw_import/jw_import_webview_side_effect.dart';
import 'package:schedu/repository/course_repository.dart';
import 'package:schedu/repository/jw_import_settings.dart';
import 'package:schedu/view/widget/flutter_webview.dart';
import '../../bloc/jw_import/jw_import_config_side_effect.dart';
import '../../gen/assets.gen.dart';

/// 教务导入WebView页面
class JwImportWebviewPage extends StatefulWidget {
  const JwImportWebviewPage({super.key});

  @override
  State<JwImportWebviewPage> createState() => _JwImportWebviewPageState();
}

class _JwImportWebviewPageState extends State<JwImportWebviewPage> {
  late final FlutterWebViewController _webViewController;
  StreamSubscription<JwImportWebviewSideEffect>? _sideEffectSubscription;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _webViewController = FlutterWebViewController();
    _webViewController.clearCookies();
    _webViewController.clearLocalStorage();
    
    // 监听副作用事件
    _sideEffectSubscription = context.read<JwImportWebviewBloc>().sideEffects.listen(_handleSideEffect);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      final args = ModalRoute.of(context)?.settings.arguments as JwImportWebviewArguments;
      context.read<JwImportWebviewBloc>().add(InitializeWebView(arguments: args));
      _loadUrl(args.jwUrl);
      if (args.strongPrompt != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('提示'),
              content: Text(args.strongPrompt!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
              ],
            ),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _sideEffectSubscription?.cancel();
    super.dispose();
  }

  /// 加载URL
  Future<void> _loadUrl(String url) async {
    if (url.isEmpty) {
      final savedUrl = await JwImportSettings.getJwUrl();
      if (savedUrl.isNotEmpty) {
        _webViewController.loadUrl(savedUrl);
      }
    } else {
      _webViewController.loadUrl(url);
    }
  }

  /// 处理副作用事件
  void _handleSideEffect(JwImportWebviewSideEffect effect) {
    if (!mounted) return;

    if (effect is ShowSnackBarMessage) {
      _showSnackBar(effect.message, isError: effect.isError);
    } else if (effect is ImportSuccessNavigateBack) {
      _showSnackBar('成功导入 ${effect.courseCount} 门课程', isError: false);
      // 延迟返回，让用户看到成功消息
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context, true); // 返回true表示导入成功
        }
      });
    } else if (effect is ShowImportConfirmDialog) {
      _showImportConfirmDialog(effect.courseCount);
    } else if (effect is HideImportConfirmDialog) {
    }
  }

  /// 显示导入确认对话框
  void _showImportConfirmDialog(int courseCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认导入'),
        content: Text(
          '找到 $courseCount 门课程，确定要导入吗？\n\n注意：这将清空现有的所有课程数据！',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<JwImportWebviewBloc>().add(const CancelImport());
            },
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<JwImportWebviewBloc>().add(const ConfirmImportCourses());
            },
            child: const Text('确认导入'),
          ),
        ],
      ),
    );
  }

  /// 刷新页面
  Future<void> _refreshPage() async {
    await _webViewController.reload();
  }

  /// 解析并导入课程数据
  Future<void> _parseAndImport() async {
    try {
      // 获取页面HTML内容
      final args = context.read<JwImportWebviewBloc>().state.arguments;
      final script = args is JsImportWebviewArguments
          ? args.script
          : await rootBundle.loadString(Assets.scheduleParse);
      final result = await _webViewController.runJavaScriptReturningResult(
        '(function() { \n $script \n return getSchedule(); \n})()',
      );
      if (result == null || result.isEmpty) {
        _showParseFailedDialog('未知错误，解析代码执行未返回结果');
        return;
      }
      final resultJson = jsonDecode(result);
      if (resultJson['success'] != true) {
        _showParseFailedDialog(resultJson['error'] ?? '解析失败，未能找到课程表部分\n请确认已登录并打开课程表页面');
        return;
      }
      
      _showParseDialog(resultJson);
    } catch (e) {
      _showSnackBar('获取页面内容失败: $e', isError: true);
    }
  }

  /// 显示解析对话框
  void _showParseDialog(dynamic resultJson) {
    final html = resultJson['html'] as String;
    final args = context.read<JwImportWebviewBloc>().state.arguments;
    final aiArgs = args is AiImportWebviewArguments ? args : null;
    final jsArgs = args is JsImportWebviewArguments ? args : null;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('解析课程数据'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('已获取到页面内容（${html.length}字符）'),
            const SizedBox(height: 16),
            Text(
              args!.importMode == 'ai' ? '使用AI解析课程表数据...' : '使用JS脚本解析课程表数据...',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            if (aiArgs != null) ...[
              Text('服务商: ${aiArgs.providerName}'),
              Text('AI模型: ${aiArgs.aiModel}'),
              if (aiArgs.maxTextLength > 0) Text('最大发送文本长度: ${aiArgs.maxTextLength}'),
              Text('BaseUrl: ${aiArgs.baseUrl}'),
            ] else if (jsArgs != null) ...[
              Text('JS脚本长度: ${jsArgs.script.length} 字符'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
          if (html.isNotEmpty)
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<JwImportWebviewBloc>().add(ParseAndImportCourses(resultJson));
              },
              child: const Text('开始解析'),
            ),
        ],
      ),
    );
  }

  void _showParseFailedDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解析失败'),
        content: Text('解析课程数据失败: $errorMessage'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示更多选项
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => BlocBuilder<JwImportWebviewBloc, JwImportWebviewState>(
        builder: (context, state) => StatefulBuilder(
          builder: (context, modalSetState) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('刷新页面'),
                  onTap: () {
                    Navigator.pop(context);
                    _refreshPage();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_back),
                  title: const Text('后退'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (await _webViewController.canGoBack()) {
                      _webViewController.goBack();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_forward),
                  title: const Text('前进'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (await _webViewController.canGoForward()) {
                      _webViewController.goForward();
                    }
                  },
                ),
                SwitchListTile(
                  value: state.isDesktopMode,
                  onChanged: (value) {
                    context.read<JwImportWebviewBloc>().add(ToggleDesktopMode(value));
                    _webViewController.setDesktopMode(value);
                  },
                  title: const Text('桌面版网站'),
                  secondary: const Icon(Icons.desktop_windows),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('返回配置'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JwImportWebviewBloc, JwImportWebviewState>(
      builder: (context, state) {
        // 参数未提供时显示错误页面
        if (state.arguments == null && state.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('教务系统'),
            ),
            body: Center(
              child: Text(
                state.errorMessage.isNotEmpty
                    ? state.errorMessage
                    : '未提供必要的参数，请返回配置页面进行设置',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(state.pageTitle),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _showMoreOptions,
                tooltip: '更多选项',
              ),
            ],
          ),
          body: Stack(
            children: [
              // WebView
              if (!state.hasError)
                FlutterWebView(
                  controller: _webViewController,
                  onPageStarted: (url) {
                    context.read<JwImportWebviewBloc>().add(PageStarted(url: url));
                  },
                  onProgress: (progress) {
                    context.read<JwImportWebviewBloc>().add(PageProgressUpdated(progress));
                  },
                  onPageFinished: (url, title) {
                    context.read<JwImportWebviewBloc>().add(PageFinished(url: url, title: title));
                  },
                  onWebResourceError: (description) {
                    context.read<JwImportWebviewBloc>().add(PageLoadError(description));
                  },
                ),

              // 加载进度条
              if (state.isLoading)
                LinearProgressIndicator(
                  value: state.loadingProgress,
                  backgroundColor: Colors.transparent,
                ),

              // 解析中遮罩
              if (state.isParsing || state.isImporting)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.all(32),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              state.isImporting
                                  ? '正在导入课程...'
                                  : (state.parsingStatus ?? '正在解析...'),
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            // AI返回内容长度提示
                            if (state.isParsing && state.aiResponseLength > 0) ...[
                              const SizedBox(height: 12),
                              Text(
                                'AI已返回内容：${state.aiResponseLength} 字符',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 错误页面
              if (state.hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '加载失败',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('返回配置'),
                            ),
                            const SizedBox(width: 16),
                            FilledButton.icon(
                              onPressed: _refreshPage,
                              icon: const Icon(Icons.refresh),
                              label: const Text('重试'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: (state.hasError || state.isParsing || state.isImporting)
              ? null
              : FloatingActionButton.extended(
                  onPressed: _parseAndImport,
                  icon: const Icon(Icons.upload),
                  label: const Text('解析导入'),
                  tooltip: '解析当前页面并导入课程数据',
                ),
        );
      },
    );
  }
}