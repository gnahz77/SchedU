import 'package:equatable/equatable.dart';
import 'package:schedu/model/course.dart';
import 'jw_import_config_side_effect.dart';

/// JwImportWebview 状态
class JwImportWebviewState extends Equatable {
  /// 页面标题
  final String pageTitle;
  
  /// 是否正在加载
  final bool isLoading;
  
  /// 加载进度 (0.0 - 1.0)
  final double loadingProgress;
  
  /// 是否有错误
  final bool hasError;
  
  /// 错误消息
  final String errorMessage;
  
  /// 是否桌面模式
  final bool isDesktopMode;
  
  /// 传入的参数
  final JwImportWebviewArguments? arguments;
  
  /// 是否正在解析
  final bool isParsing;
  
  /// 解析状态文本
  final String? parsingStatus;
  
  /// AI已返回的内容长度
  final int aiResponseLength;
  
  /// 解析出的课程列表（待确认导入）
  final List<Course>? parsedCourses;
  
  /// 是否正在导入
  final bool isImporting;

  const JwImportWebviewState({
    this.pageTitle = '教务系统',
    this.isLoading = true,
    this.loadingProgress = 0.0,
    this.hasError = false,
    this.errorMessage = '',
    this.isDesktopMode = false,
    this.arguments,
    this.isParsing = false,
    this.parsingStatus,
    this.aiResponseLength = 0,
    this.parsedCourses,
    this.isImporting = false,
  });

  JwImportWebviewState copyWith({
    String? pageTitle,
    bool? isLoading,
    double? loadingProgress,
    bool? hasError,
    String? errorMessage,
    bool? isDesktopMode,
    JwImportWebviewArguments? arguments,
    bool? isParsing,
    String? parsingStatus,
    int? aiResponseLength,
    List<Course>? parsedCourses,
    bool? isImporting,
    bool clearParsedCourses = false,
    bool clearParsingStatus = false,
  }) {
    return JwImportWebviewState(
      pageTitle: pageTitle ?? this.pageTitle,
      isLoading: isLoading ?? this.isLoading,
      loadingProgress: loadingProgress ?? this.loadingProgress,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      isDesktopMode: isDesktopMode ?? this.isDesktopMode,
      arguments: arguments ?? this.arguments,
      isParsing: isParsing ?? this.isParsing,
      parsingStatus: clearParsingStatus ? null : (parsingStatus ?? this.parsingStatus),
      aiResponseLength: aiResponseLength ?? this.aiResponseLength,
      parsedCourses: clearParsedCourses ? null : (parsedCourses ?? this.parsedCourses),
      isImporting: isImporting ?? this.isImporting,
    );
  }

  @override
  List<Object?> get props => [
        pageTitle,
        isLoading,
        loadingProgress,
        hasError,
        errorMessage,
        isDesktopMode,
        arguments,
        isParsing,
        parsingStatus,
        aiResponseLength,
        parsedCourses,
        isImporting,
      ];
}
