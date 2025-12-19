import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../model/ai_chat.dart';
import '../../model/ai_service_provider.dart';
import '../../repository/jw_import_settings.dart';
import '../../service/openai_dart_impl.dart';
import '../../service/schedu_ai_service.dart';
import 'jw_import_config_event.dart';
import 'jw_import_config_state.dart';
import 'jw_import_config_side_effect.dart';

/// 测试服务的提示词
const String defaultTestSystemPrompt = "This is a test message. Just reply ‘ok’—no need to explain.";
const String defaultTestUserPrompt = "All you have to do is reply ok";

/// JW导入配置BLoC
class JwImportConfigBloc
    extends Bloc<JwImportConfigEvent, JwImportConfigState> {

  // SideEffect Stream Controller
  final _sideEffectController = StreamController<JwImportConfigSideEffect>.broadcast();
  Stream<JwImportConfigSideEffect> get sideEffectStream => _sideEffectController.stream;

  JwImportConfigBloc() : super(const JwImportConfigInitial()) {
    on<LoadConfigEvent>(_onLoadConfig);
    on<LoadAiProvidersEvent>(_onLoadAiProviders);
    on<LoadAiModelsEvent>(_onLoadAiModels);
    on<UpdateJwUrlEvent>(_onUpdateJwUrl);
    on<UpdateImportModeEvent>(_onUpdateImportMode);
    on<UpdateAiProviderEvent>(_onUpdateAiProvider);
    on<UpdateCustomApiUrlEvent>(_onUpdateCustomApiUrl);
    on<UpdateApiKeyEvent>(_onUpdateApiKey);
    on<UpdateAiModelEvent>(_onUpdateAiModel);
    on<UpdateUseCustomModelEvent>(_onUpdateUseCustomModel);
    on<UpdateMaxTextLengthEvent>(_onUpdateMaxTextLength);
    on<SaveConfigEvent>(_onSaveConfig);
    on<TestAiServiceEvent>(_onTestAiService);
  }

  @override
  Future<void> close() {
    _sideEffectController.close();
    return super.close();
  }

  /// 发送SideEffect事件
  void _emitSideEffect(JwImportConfigSideEffect effect) {
    if (!_sideEffectController.isClosed) {
      _sideEffectController.add(effect);
    }
  }

  Future<void> _onLoadConfig(
    LoadConfigEvent event,
    Emitter<JwImportConfigState> emit,
  ) async {
    emit(const JwImportConfigLoading());
    try {
      // 加载AI服务提供商
      final loadedProviders = await AiServiceProvider.loadProviders();
      
      // 在首位添加系统免费解析服务
      final systemFreeService = AiServiceProvider(
        name: JwImportConfigLoaded.systemFreeServiceName,
        baseUrl: '', // 系统服务使用默认地址
        defaultModel: '',
        icon: '',
      );
      final aiProviders = [systemFreeService, ...loadedProviders];

      // 加载保存的配置
      final jwUrl = await JwImportSettings.getJwUrl();
      final importMode = await JwImportSettings.getImportMode();
      final aiProvider = await JwImportSettings.getAiProvider();
      final apiUrl = await JwImportSettings.getCustomApiUrl();
      final apiKey = await JwImportSettings.getApiKey();
      final aiModel = await JwImportSettings.getAiModel();
      final useCustomModel = await JwImportSettings.getUseCustomModel();
      final maxTextLength = await JwImportSettings.getMaxTextLength();

      // 查找选中的服务提供商索引
      int selectedProviderIndex = aiProviders.indexWhere((provider) => provider.name == aiProvider);

      // 如果没找到匹配的,使用第一个
      if (selectedProviderIndex == -1 && aiProviders.isNotEmpty) {
        selectedProviderIndex = 0;
      }

      emit(
        JwImportConfigLoaded(
          jwUrl: jwUrl,
          importMode: importMode,
          aiProviders: aiProviders,
          selectedProviderIndex: selectedProviderIndex,
          apiUrl: apiUrl,
          apiKey: apiKey,
          aiModel: aiModel,
          useCustomModel: useCustomModel,
          maxTextLength: maxTextLength,
        ),
      );
    } catch (e) {
      _emitSideEffect(ShowErrorMessage('加载配置失败: $e'));
      emit(const JwImportConfigInitial());
    }
  }

  Future<void> _onLoadAiProviders(
    LoadAiProvidersEvent event,
    Emitter<JwImportConfigState> emit,
  ) async {
    if (state is! JwImportConfigLoaded) return;

    try {
      final loadedProviders = await AiServiceProvider.loadProviders();
      // 在首位添加系统免费解析服务
      final systemFreeService = AiServiceProvider(
        name: JwImportConfigLoaded.systemFreeServiceName,
        baseUrl: '',
        defaultModel: '',
        icon: '',
      );
      final aiProviders = [systemFreeService, ...loadedProviders];
      emit((state as JwImportConfigLoaded).copyWith(aiProviders: aiProviders));
    } catch (e) {
      _emitSideEffect(ShowErrorMessage('加载AI服务提供商失败: $e'));
    }
  }

  Future<void> _onLoadAiModels(
    LoadAiModelsEvent event,
    Emitter<JwImportConfigState> emit,
  ) async {
    if (state is! JwImportConfigLoaded) return;

    final currentState = state as JwImportConfigLoaded;
    if (currentState.apiKey.isEmpty) {
      _emitSideEffect(const ShowErrorMessage('请先输入API Key'));
      return;
    }

    // 设置加载状态
    emit(currentState.copyWith(isLoadingModels: true));

    try {
      // 创建AI服务实例
      final aiService = OpenaiDartImpl(
        apiKey: currentState.apiKey,
        baseUrl: currentState.apiUrl.isEmpty
            ? currentState.selectedProvider!.baseUrl
            : currentState.apiUrl,
      );

      // 获取可用模型列表
      final models = await aiService.listModels();

      emit(currentState.copyWith(availableModels: models, isLoadingModels: false));
      
      // 发送成功的SideEffect
      _emitSideEffect(ModelsLoadedSuccess(models.length));
    } catch (e) {
      emit(currentState.copyWith(isLoadingModels: false));
      _emitSideEffect(ShowErrorMessage('获取模型列表失败: $e'));
    }
  }

  void _onUpdateJwUrl(
    UpdateJwUrlEvent event,
    Emitter<JwImportConfigState> emit,
  ) {
    if (state is JwImportConfigLoaded) {
      emit((state as JwImportConfigLoaded).copyWith(jwUrl: event.jwUrl));
    }
  }

  void _onUpdateImportMode(
    UpdateImportModeEvent event,
    Emitter<JwImportConfigState> emit,
  ) {
    if (state is JwImportConfigLoaded) {
      emit(
        (state as JwImportConfigLoaded).copyWith(importMode: event.importMode),
      );
    }
  }

  void _onUpdateAiProvider(
    UpdateAiProviderEvent event,
    Emitter<JwImportConfigState> emit,
  ) {
    if (state is JwImportConfigLoaded) {
      final currentState = state as JwImportConfigLoaded;
      final provider = currentState.aiProviders[event.providerIndex];

      emit(
        currentState.copyWith(
          selectedProviderIndex: event.providerIndex,
          aiModel: provider.defaultModel,
          availableModels: [], // 清空之前的模型列表
          useCustomModel: false, // 切换服务商时重置自定义模型模式
        ),
      );
    }
  }

  void _onUpdateCustomApiUrl(
    UpdateCustomApiUrlEvent event,
    Emitter<JwImportConfigState> emit,
  ) {
    if (state is JwImportConfigLoaded) {
      emit(
        (state as JwImportConfigLoaded).copyWith(
          apiUrl: event.customApiUrl,
        ),
      );
    }
  }

  void _onUpdateApiKey(
    UpdateApiKeyEvent event,
    Emitter<JwImportConfigState> emit,
  ) {
    if (state is JwImportConfigLoaded) {
      emit(
        (state as JwImportConfigLoaded).copyWith(
          apiKey: event.apiKey,
        ),
      );
    }
  }

  void _onUpdateAiModel(
    UpdateAiModelEvent event,
    Emitter<JwImportConfigState> emit,
  ) {
    if (state is JwImportConfigLoaded) {
      emit((state as JwImportConfigLoaded).copyWith(aiModel: event.aiModel));
    }
  }

  void _onUpdateUseCustomModel(
    UpdateUseCustomModelEvent event,
    Emitter<JwImportConfigState> emit,
  ) {
    if (state is JwImportConfigLoaded) {
      final currentState = state as JwImportConfigLoaded;
      emit(
        currentState.copyWith(
          useCustomModel: event.useCustomModel,
          // 切换到非自定义模式时，重置为默认模型
          aiModel: event.useCustomModel
              ? currentState.aiModel
              : (currentState.availableModels.isNotEmpty
                  ? currentState.availableModels.first.id
                  : currentState.selectedProvider?.defaultModel ?? ''),
        ),
      );
    }
  }

  void _onUpdateMaxTextLength(
    UpdateMaxTextLengthEvent event,
    Emitter<JwImportConfigState> emit,
  ) {
    if (state is JwImportConfigLoaded) {
      emit(
        (state as JwImportConfigLoaded).copyWith(
          maxTextLength: event.maxTextLength,
        ),
      );
    }
  }

  Future<void> _onSaveConfig(
    SaveConfigEvent event,
    Emitter<JwImportConfigState> emit,
  ) async {
    if (state is! JwImportConfigLoaded) return;

    final currentState = state as JwImportConfigLoaded;

    try {
      await JwImportSettings.saveJwUrl(currentState.jwUrl);
      await JwImportSettings.saveImportMode(currentState.importMode);

      // 保存AI服务商名称
      final providerName = currentState.selectedProvider?.name ?? 'custom';
      await JwImportSettings.saveAiProvider(providerName);

      await JwImportSettings.saveCustomApiUrl(currentState.apiUrl);
      await JwImportSettings.saveApiKey(currentState.apiKey);
      await JwImportSettings.saveAiModel(currentState.aiModel);
      await JwImportSettings.saveUseCustomModel(currentState.useCustomModel);
      await JwImportSettings.saveMaxTextLength(currentState.maxTextLength);

      // 发送成功消息和导航作为SideEffect
      _emitSideEffect(const ShowSuccessMessage('配置已保存'));
      if (event.navigateToImport) {
        if (currentState.importMode == 'js') {
          // TODO: JS导入待实现
          _emitSideEffect(const ShowErrorMessage('JS导入模式尚未实现'));
          return;
        }
        
        final strongPrompt = "导入前请确认已登录并打开 周/学期 课表页面，以确保能识别到网页中的课程信息。"
            "\n\n导入前建议关闭不必要的弹窗和广告，以免影响对页面的解析。";
        
        JwImportWebviewArguments args;
        
        // 判断是否使用系统免费服务
        if (currentState.isSystemFreeService) {
          args = SystemServiceWebviewArguments(
            jwUrl: currentState.jwUrl,
            strongPrompt: strongPrompt,
          );
        } else if (currentState.importMode == 'ai') {
          final resolvedBaseUrl = currentState.apiUrl.isEmpty
              ? currentState.selectedProvider?.baseUrl ?? ''
              : currentState.apiUrl;
          args = AiImportWebviewArguments(
            jwUrl: currentState.jwUrl,
            providerName: providerName,
            apiKey: currentState.apiKey,
            aiModel: currentState.aiModel,
            maxTextLength: currentState.maxTextLength,
            baseUrl: resolvedBaseUrl,
            strongPrompt: strongPrompt,
          );
        } else {
          args = JsImportWebviewArguments(
            jwUrl: currentState.jwUrl,
            script: '',
          );
        }
        _emitSideEffect(NavigateToImportWebView(args));
      }
    } catch (e) {
      _emitSideEffect(ShowErrorMessage('保存配置失败: $e'));
    }
  }

  Future<void> _onTestAiService(
    TestAiServiceEvent event,
    Emitter<JwImportConfigState> emit,
  ) async {
    if (state is! JwImportConfigLoaded) return;

    final currentState = state as JwImportConfigLoaded;

    // 判断是否使用系统免费解析服务
    if (currentState.isSystemFreeService) {
      emit(currentState.copyWith(isTestingService: true));
      try {
        final schedUService = SchedUAIService();
        final result = await schedUService.testService();
        
        if (result.success) {
          _emitSideEffect(ShowSuccessMessage('系统服务测试成功! ${result.timestamp != null ? "(服务器时间: ${result.timestamp})" : ""}'));
        } else {
          _emitSideEffect(ShowErrorMessage('系统服务测试失败: ${result.message}'));
        }
      } catch (e) {
        _emitSideEffect(ShowErrorMessage('系统服务测试失败: $e'));
      } finally {
        emit(currentState.copyWith(isTestingService: false));
      }
      return;
    }

    // 其他AI服务商的测试逻辑
    if (currentState.apiKey.isEmpty) {
      _emitSideEffect(const ShowErrorMessage('请先输入API Key'));
      return;
    }

    if (currentState.aiModel.isEmpty) {
      _emitSideEffect(const ShowErrorMessage('请先选择或输入模型名称'));
      return;
    }

    emit(currentState.copyWith(isTestingService: true));
    try {
      final aiService = OpenaiDartImpl(
        apiKey: currentState.apiKey,
        baseUrl: currentState.apiUrl.isEmpty
            ? currentState.selectedProvider!.baseUrl
            : currentState.apiUrl,
      );

      await aiService.chat(
        request: AIChatRequest(
          model: currentState.aiModel,
          systemPrompt: defaultTestSystemPrompt,
          messages: [
            AIChatMessage(
              role: AIChatRole.user,
              content: defaultTestUserPrompt,
            )
          ]
        ),
      );

      _emitSideEffect(const ShowSuccessMessage('AI服务测试成功!'));
    } catch (e) {
      _emitSideEffect(ShowErrorMessage('AI服务测试失败: $e'));
    } finally {
      emit(currentState.copyWith(isTestingService: false));
    }
  }
}
