import 'package:equatable/equatable.dart';

/// JW导入配置事件基类
abstract class JwImportConfigEvent extends Equatable {
  const JwImportConfigEvent();

  @override
  List<Object?> get props => [];
}

/// 加载配置事件
class LoadConfigEvent extends JwImportConfigEvent {
  const LoadConfigEvent();
}

/// 加载AI服务提供商事件
class LoadAiProvidersEvent extends JwImportConfigEvent {
  const LoadAiProvidersEvent();
}

/// 加载AI模型列表事件
class LoadAiModelsEvent extends JwImportConfigEvent {
  const LoadAiModelsEvent();
}

/// 更新教务系统URL事件
class UpdateJwUrlEvent extends JwImportConfigEvent {
  final String jwUrl;

  const UpdateJwUrlEvent(this.jwUrl);

  @override
  List<Object?> get props => [jwUrl];
}

/// 更新导入模式事件
class UpdateImportModeEvent extends JwImportConfigEvent {
  final String importMode;

  const UpdateImportModeEvent(this.importMode);

  @override
  List<Object?> get props => [importMode];
}

/// 更新AI服务提供商事件
class UpdateAiProviderEvent extends JwImportConfigEvent {
  final int providerIndex;

  const UpdateAiProviderEvent(this.providerIndex);

  @override
  List<Object?> get props => [providerIndex];
}

/// 更新自定义API地址事件
class UpdateCustomApiUrlEvent extends JwImportConfigEvent {
  final String customApiUrl;

  const UpdateCustomApiUrlEvent(this.customApiUrl);

  @override
  List<Object?> get props => [customApiUrl];
}

/// 更新API Key事件
class UpdateApiKeyEvent extends JwImportConfigEvent {
  final String apiKey;

  const UpdateApiKeyEvent(this.apiKey);

  @override
  List<Object?> get props => [apiKey];
}

/// 更新AI模型事件
class UpdateAiModelEvent extends JwImportConfigEvent {
  final String aiModel;

  const UpdateAiModelEvent(this.aiModel);

  @override
  List<Object?> get props => [aiModel];
}

/// 更新是否使用自定义模型
class UpdateUseCustomModelEvent extends JwImportConfigEvent {
  final bool useCustomModel;

  const UpdateUseCustomModelEvent(this.useCustomModel);

  @override
  List<Object?> get props => [useCustomModel];
}

/// 更新最大文本长度事件
class UpdateMaxTextLengthEvent extends JwImportConfigEvent {
  final int maxTextLength;

  const UpdateMaxTextLengthEvent(this.maxTextLength);

  @override
  List<Object?> get props => [maxTextLength];
}

/// 保存配置事件
class SaveConfigEvent extends JwImportConfigEvent {
  final bool navigateToImport;
  const SaveConfigEvent({this.navigateToImport = false});
}

/// 测试AI服务事件
class TestAiServiceEvent extends JwImportConfigEvent {
  const TestAiServiceEvent();
}
