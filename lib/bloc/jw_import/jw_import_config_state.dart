import 'package:equatable/equatable.dart';
import '../../model/ai_service_provider.dart';
import '../../model/ai_chat.dart';

/// JW导入配置状态基类
abstract class JwImportConfigState extends Equatable {
  const JwImportConfigState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class JwImportConfigInitial extends JwImportConfigState {
  const JwImportConfigInitial();
}

/// 加载中状态
class JwImportConfigLoading extends JwImportConfigState {
  const JwImportConfigLoading();
}

/// 已加载状态
class JwImportConfigLoaded extends JwImportConfigState {
  final String jwUrl;
  final String importMode;
  final List<AiServiceProvider> aiProviders;
  final int selectedProviderIndex;
  final String apiUrl;
  final String apiKey;
  final String aiModel;
  final bool useCustomModel;
  final int maxTextLength;
  final List<AIModelInfo> availableModels;
  final bool isLoadingModels;
  final bool isTestingService;

  const JwImportConfigLoaded({
    required this.jwUrl,
    required this.importMode,
    required this.aiProviders,
    required this.selectedProviderIndex,
    required this.apiUrl,
    required this.apiKey,
    required this.aiModel,
    required this.useCustomModel,
    required this.maxTextLength,
    this.availableModels = const [],
    this.isLoadingModels = false,
    this.isTestingService = false,
  });

  /// 系统免费服务的标识名称
  static const String systemFreeServiceName = '系统免费解析服务';

  /// 获取当前选中的服务提供商
  AiServiceProvider? get selectedProvider {
    if (selectedProviderIndex >= 0 && selectedProviderIndex < aiProviders.length) {
      return aiProviders[selectedProviderIndex];
    }
    return null;
  }

  /// 是否使用系统免费解析服务
  bool get isSystemFreeService {
    return selectedProvider?.name == systemFreeServiceName;
  }

  /// 是否使用自定义服务商
  bool get isCustomProvider {
    return selectedProvider?.name == '自定义' || selectedProviderIndex == -1;
  }

  JwImportConfigLoaded copyWith({
    String? jwUrl,
    String? importMode,
    List<AiServiceProvider>? aiProviders,
    int? selectedProviderIndex,
    String? apiUrl,
    String? apiKey,
    String? aiModel,
    bool? useCustomModel,
    int? maxTextLength,
    List<AIModelInfo>? availableModels,
    bool? isLoadingModels,
    bool? isTestingService,
  }) {
    return JwImportConfigLoaded(
      jwUrl: jwUrl ?? this.jwUrl,
      importMode: importMode ?? this.importMode,
      aiProviders: aiProviders ?? this.aiProviders,
      selectedProviderIndex: selectedProviderIndex ?? this.selectedProviderIndex,
      apiUrl: apiUrl ?? this.apiUrl,
      apiKey: apiKey ?? this.apiKey,
      aiModel: aiModel ?? this.aiModel,
      useCustomModel: useCustomModel ?? this.useCustomModel,
      maxTextLength: maxTextLength ?? this.maxTextLength,
      availableModels: availableModels ?? this.availableModels,
      isLoadingModels: isLoadingModels ?? this.isLoadingModels,
      isTestingService: isTestingService ?? this.isTestingService,
    );
  }

  @override
  List<Object?> get props => [
        jwUrl,
        importMode,
        aiProviders,
        selectedProviderIndex,
        apiUrl,
        apiKey,
        aiModel,
        useCustomModel,
        maxTextLength,
        availableModels,
        isLoadingModels,
        isTestingService,
      ];
}
