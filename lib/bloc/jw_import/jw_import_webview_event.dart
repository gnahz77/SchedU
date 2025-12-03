import 'package:equatable/equatable.dart';
import 'jw_import_config_side_effect.dart';

/// JwImportWebview 事件基类
abstract class JwImportWebviewEvent extends Equatable {
  const JwImportWebviewEvent();

  @override
  List<Object?> get props => [];
}

/// 初始化WebView
class InitializeWebView extends JwImportWebviewEvent {
  final JwImportWebviewArguments? arguments;

  const InitializeWebView({this.arguments});

  @override
  List<Object?> get props => [arguments];
}

/// 页面开始加载
class PageStarted extends JwImportWebviewEvent {
  final String? url;

  const PageStarted({this.url});

  @override
  List<Object?> get props => [url];
}

/// 页面加载进度更新
class PageProgressUpdated extends JwImportWebviewEvent {
  final double progress;

  const PageProgressUpdated(this.progress);

  @override
  List<Object?> get props => [progress];
}

/// 页面加载完成
class PageFinished extends JwImportWebviewEvent {
  final String? url;
  final String? title;

  const PageFinished({this.url, this.title});

  @override
  List<Object?> get props => [url, title];
}

/// 页面加载错误
class PageLoadError extends JwImportWebviewEvent {
  final String description;

  const PageLoadError(this.description);

  @override
  List<Object?> get props => [description];
}

/// 切换桌面模式
class ToggleDesktopMode extends JwImportWebviewEvent {
  final bool isDesktopMode;

  const ToggleDesktopMode(this.isDesktopMode);

  @override
  List<Object?> get props => [isDesktopMode];
}

/// 解析并导入课程
class ParseAndImportCourses extends JwImportWebviewEvent {
  final String htmlContent;

  const ParseAndImportCourses(this.htmlContent);

  @override
  List<Object?> get props => [htmlContent];
}

/// 确认导入课程
class ConfirmImportCourses extends JwImportWebviewEvent {
  const ConfirmImportCourses();
}

/// 取消导入
class CancelImport extends JwImportWebviewEvent {
  const CancelImport();
}
