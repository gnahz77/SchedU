import 'package:equatable/equatable.dart';

/// JW导入配置的SideEffect事件（一次性事件）
abstract class JwImportConfigSideEffect extends Equatable {
  const JwImportConfigSideEffect();

  @override
  List<Object?> get props => [];
}

/// 显示错误消息
class ShowErrorMessage extends JwImportConfigSideEffect {
  final String message;

  const ShowErrorMessage(this.message);

  @override
  List<Object?> get props => [message];
}

/// 显示成功消息
class ShowSuccessMessage extends JwImportConfigSideEffect {
  final String message;

  const ShowSuccessMessage(this.message);

  @override
  List<Object?> get props => [message];
}

/// 模型列表加载成功
class ModelsLoadedSuccess extends JwImportConfigSideEffect {
  final int modelCount;

  const ModelsLoadedSuccess(this.modelCount);

  @override
  List<Object?> get props => [modelCount];
}

abstract class JwImportWebviewArguments extends Equatable {
  final String jwUrl;
  final String importMode;
  final String? strongPrompt;

  /// @param jwUrl 教务系统网址
  /// @param importMode 导入模式，'ai'或'js'
  /// @param strongPrompt 强提示，在打开页面后会弹窗显示
  const JwImportWebviewArguments({
    required this.jwUrl,
    required this.importMode,
    this.strongPrompt
  });

  @override
  List<Object?> get props => [jwUrl, importMode, strongPrompt];

}

/// AI导入模式的arguments
class AiImportWebviewArguments extends JwImportWebviewArguments {
  final String providerName;
  final String apiKey;
  final String aiModel;
  final int maxTextLength;
  final String baseUrl;

  const AiImportWebviewArguments({
    required super.jwUrl,
    required this.providerName,
    required this.apiKey,
    required this.aiModel,
    required this.maxTextLength,
    required this.baseUrl,
    super.strongPrompt
  }): super(importMode: 'ai');

  @override
  List<Object?> get props => super.props + [providerName, apiKey, aiModel, maxTextLength, baseUrl];
}

/// 系统免费解析服务的arguments
class SystemServiceWebviewArguments extends JwImportWebviewArguments {
  const SystemServiceWebviewArguments({
    required super.jwUrl,
    super.strongPrompt
  }): super(importMode: 'system');

  @override
  List<Object?> get props => super.props;
}

/// JS导入模式的arguments
class JsImportWebviewArguments extends JwImportWebviewArguments {
  final String script;

  const JsImportWebviewArguments({
    required super.jwUrl,
    required this.script,
    super.strongPrompt
  }): super(importMode: 'js');

  @override
  List<Object?> get props => super.props + [script];
}

class NavigateToImportWebView extends JwImportConfigSideEffect {
  final JwImportWebviewArguments arguments;

  const NavigateToImportWebView(this.arguments);

  @override
  List<Object?> get props => [arguments];
}

