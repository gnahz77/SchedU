import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/gen/assets.gen.dart';
import 'package:schedu/model/ai_chat.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/repository/course_repository.dart';
import 'package:schedu/service/openai_dart_impl.dart';
import 'jw_import_config_side_effect.dart';
import 'jw_import_webview_event.dart';
import 'jw_import_webview_state.dart';
import 'jw_import_webview_side_effect.dart';

/// JwImportWebview BLoC
class JwImportWebviewBloc extends Bloc<JwImportWebviewEvent, JwImportWebviewState> {
  final CourseRepository _courseRepository;
  
  /// 副作用事件流
  final _sideEffectController = StreamController<JwImportWebviewSideEffect>.broadcast();
  Stream<JwImportWebviewSideEffect> get sideEffects => _sideEffectController.stream;

  JwImportWebviewBloc(this._courseRepository) : super(const JwImportWebviewState()) {
    on<InitializeWebView>(_onInitializeWebView);
    on<PageStarted>(_onPageStarted);
    on<PageProgressUpdated>(_onPageProgressUpdated);
    on<PageFinished>(_onPageFinished);
    on<PageLoadError>(_onPageLoadError);
    on<ToggleDesktopMode>(_onToggleDesktopMode);
    on<ParseAndImportCourses>(_onParseAndImportCourses);
    on<ConfirmImportCourses>(_onConfirmImportCourses);
    on<CancelImport>(_onCancelImport);
  }

  @override
  Future<void> close() {
    _sideEffectController.close();
    return super.close();
  }

  void _emitSideEffect(JwImportWebviewSideEffect effect) {
    _sideEffectController.add(effect);
  }

  /// 初始化WebView
  void _onInitializeWebView(
    InitializeWebView event,
    Emitter<JwImportWebviewState> emit,
  ) {
    if (event.arguments == null) {
      emit(state.copyWith(
        hasError: true,
        errorMessage: '未提供必要的参数，请返回配置页面进行设置',
        isLoading: false,
      ));
      return;
    }

    emit(state.copyWith(
      arguments: event.arguments,
      isLoading: true,
    ));
  }

  /// 页面开始加载
  void _onPageStarted(
    PageStarted event,
    Emitter<JwImportWebviewState> emit,
  ) {
    emit(state.copyWith(
      isLoading: true,
      hasError: false,
    ));
  }

  /// 页面加载进度更新
  void _onPageProgressUpdated(
    PageProgressUpdated event,
    Emitter<JwImportWebviewState> emit,
  ) {
    emit(state.copyWith(loadingProgress: event.progress));
  }

  /// 页面加载完成
  void _onPageFinished(
    PageFinished event,
    Emitter<JwImportWebviewState> emit,
  ) {
    emit(state.copyWith(
      isLoading: false,
      pageTitle: (event.title?.isNotEmpty == true) ? event.title : state.pageTitle,
    ));
  }

  /// 页面加载错误
  void _onPageLoadError(
    PageLoadError event,
    Emitter<JwImportWebviewState> emit,
  ) {
    // emit(state.copyWith(
    //   hasError: true,
    //   errorMessage: event.description,
    //   isLoading: false,
    // ));
  }

  /// 切换桌面模式
  void _onToggleDesktopMode(
    ToggleDesktopMode event,
    Emitter<JwImportWebviewState> emit,
  ) {
    emit(state.copyWith(isDesktopMode: event.isDesktopMode));
  }

  /// 解析并导入课程
  Future<void> _onParseAndImportCourses(
    ParseAndImportCourses event,
    Emitter<JwImportWebviewState> emit,
  ) async {
    final args = state.arguments;
    if (args == null) {
      _emitSideEffect(const ShowSnackBarMessage('配置参数丢失', isError: true));
      return;
    }

    // 检查是否是AI导入模式
    if (args is! AiImportWebviewArguments) {
      _emitSideEffect(const ShowSnackBarMessage('JS导入功能开发中...', isError: false));
      return;
    }

    final aiArgs = args;

    emit(state.copyWith(
      isParsing: true,
      parsingStatus: '正在获取页面内容...',
      aiResponseLength: 0,
    ));

    try {
      // 加载系统提示词
      final systemPrompt = await rootBundle.loadString(Assets.prompt);

      emit(state.copyWith(parsingStatus: '正在调用AI解析课程表...'));

      // 准备HTML内容
      String htmlContent = event.htmlContent;
      
      // 如果设置了最大文本长度，进行截断
      if (aiArgs.maxTextLength > 0 && htmlContent.length > aiArgs.maxTextLength) {
        htmlContent = htmlContent.substring(0, aiArgs.maxTextLength);
      }

      // 创建AI服务
      final aiService = OpenaiDartImpl(
        apiKey: aiArgs.apiKey,
        baseUrl: aiArgs.baseUrl.isNotEmpty ? aiArgs.baseUrl : null,
      );

      // 发送请求
      final request = AIChatRequest(
        model: aiArgs.aiModel,
        systemPrompt: systemPrompt,
        prompt: htmlContent,
      );

      // 使用流式API接收数据
      String fullResponse = '';
      await for (final chunk in aiService.chatStream(request: request)) {
        fullResponse += chunk;
        
        // 实时更新UI显示已接收的内容长度
        emit(state.copyWith(
          parsingStatus: '正在接收AI返回内容...',
          aiResponseLength: fullResponse.length,
        ));
      }

      emit(state.copyWith(parsingStatus: '正在解析AI返回结果...'));

      // 解析AI返回的JSON
      final courses = _parseCoursesFromResponse(fullResponse);

      if (courses.isEmpty) {
        emit(state.copyWith(
          isParsing: false,
          clearParsingStatus: true,
          aiResponseLength: 0,
        ));
        _emitSideEffect(const ShowSnackBarMessage('未能从页面中解析出课程数据', isError: true));
        return;
      }

      // 保存解析结果并显示确认对话框
      emit(state.copyWith(
        isParsing: false,
        parsedCourses: courses,
        showImportConfirmDialog: true,
        clearParsingStatus: true,
        aiResponseLength: 0,
      ));
      _emitSideEffect(ShowImportConfirmDialog(courses.length));
    } catch (e) {
      emit(state.copyWith(
        isParsing: false,
        clearParsingStatus: true,
        aiResponseLength: 0,
      ));
      _emitSideEffect(ShowSnackBarMessage('解析失败: $e', isError: true));
    }
  }

  /// 从AI响应中解析课程列表
  List<Course> _parseCoursesFromResponse(String response) {
    try {
      // 尝试清理响应文本（移除可能的markdown标记）
      String cleanedResponse = response.trim();
      
      // 移除可能的markdown代码块标记
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      } else if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      // 解析JSON
      final dynamic jsonData = jsonDecode(cleanedResponse);
      
      if (jsonData is! List) {
        return [];
      }

      final List<Course> courses = [];
      for (final item in jsonData) {
        if (item is Map<String, dynamic>) {
          try {
            // 验证必要字段
            if (_validateCourseData(item)) {
              courses.add(Course.fromJson(item));
            }
          } catch (e) {
            // 跳过无法解析的单个课程
            continue;
          }
        }
      }

      return courses;
    } catch (e) {
      return [];
    }
  }

  /// 验证课程数据格式
  bool _validateCourseData(Map<String, dynamic> data) {
    final requiredFields = ['name', 'position', 'teacher', 'weeks', 'day', 'sections'];
    for (String field in requiredFields) {
      if (!data.containsKey(field)) {
        return false;
      }
    }

    // 验证数据类型
    try {
      if (data['name'] is! String ||
          data['position'] is! String ||
          data['teacher'] is! String) {
        return false;
      }

      final day = data['day'];
      if (day is! int || day < 1 || day > 7) {
        return false;
      }

      final weeks = data['weeks'];
      if (weeks is! List || weeks.isEmpty) {
        return false;
      }
      for (var week in weeks) {
        if (week is! int || week < 1) {
          return false;
        }
      }

      final sections = data['sections'];
      if (sections is! List || sections.isEmpty) {
        return false;
      }
      for (var section in sections) {
        if (section is! int || section < 1) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 确认导入课程
  Future<void> _onConfirmImportCourses(
    ConfirmImportCourses event,
    Emitter<JwImportWebviewState> emit,
  ) async {
    final courses = state.parsedCourses;
    if (courses == null || courses.isEmpty) {
      _emitSideEffect(const ShowSnackBarMessage('没有可导入的课程数据', isError: true));
      return;
    }

    emit(state.copyWith(
      isImporting: true,
      showImportConfirmDialog: false,
    ));

    try {
      // 转换为JSON格式并导入
      final jsonData = courses.map((c) => c.toJson()).toList();
      await _courseRepository.importCoursesFromJson(jsonData);

      emit(state.copyWith(
        isImporting: false,
        clearParsedCourses: true,
      ));

      _emitSideEffect(ImportSuccessNavigateBack(courses.length));

    } catch (e) {
      emit(state.copyWith(isImporting: false));
      _emitSideEffect(ShowSnackBarMessage('导入失败: $e', isError: true));
    }
  }

  /// 取消导入
  void _onCancelImport(
    CancelImport event,
    Emitter<JwImportWebviewState> emit,
  ) {
    emit(state.copyWith(
      showImportConfirmDialog: false,
      clearParsedCourses: true,
    ));
    _emitSideEffect(const HideImportConfirmDialog());
  }
}
