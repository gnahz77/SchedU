import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

/// SchedU系统自带的AI课程表解析服务
class SchedUAIService {
  static const String _defaultBaseUrl = 'http://schedu.iema.cn/schedu/api/ai';
  
  final String baseUrl;
  final Dio _dio;

  SchedUAIService({String? baseUrl})
      : baseUrl = baseUrl ?? _defaultBaseUrl,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 3),
        ));

  /// 测试服务连通性
  Future<SchedUServiceTestResult> testService() async {
    try {
      final response = await _dio.get('$baseUrl/test');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['ok'] == true) {
          return SchedUServiceTestResult(
            success: true,
            message: '服务连接成功',
            timestamp: data['data']?['timestamp'],
          );
        }
      }
      
      return SchedUServiceTestResult(
        success: false,
        message: '服务响应异常',
      );
    } on DioException catch (e) {
      return SchedUServiceTestResult(
        success: false,
        message: _handleDioError(e),
      );
    } catch (e) {
      return SchedUServiceTestResult(
        success: false,
        message: '连接失败: $e',
      );
    }
  }

  /// 获取服务状态
  Future<SchedUServiceStatus> getStatus() async {
    try {
      final response = await _dio.get('$baseUrl/status');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['ok'] == true) {
          final statusData = data['data'] as Map<String, dynamic>;
          return SchedUServiceStatus(
            success: true,
            totalInFlight: statusData['totalInFlight'] ?? 0,
            maxConcurrent: statusData['maxConcurrent'] ?? 0,
            models: (statusData['models'] as List?)
                ?.map((m) => SchedUModelStatus.fromJson(m))
                .toList() ?? [],
          );
        }
      }
      
      return SchedUServiceStatus(
        success: false,
        errorMessage: '获取状态失败',
      );
    } on DioException catch (e) {
      return SchedUServiceStatus(
        success: false,
        errorMessage: _handleDioError(e),
      );
    } catch (e) {
      return SchedUServiceStatus(
        success: false,
        errorMessage: '获取状态失败: $e',
      );
    }
  }

  /// 解析课程表（非流式）
  /// 
  /// 发送HTML或原始文本到服务器解析，返回完整的课程JSON
  Future<SchedUParseResult> parse({
    String? html,
    String? rawText,
  }) async {
    if ((html == null || html.isEmpty) && (rawText == null || rawText.isEmpty)) {
      return SchedUParseResult(
        success: false,
        errorMessage: 'html和rawText至少需要提供一个',
      );
    }

    try {
      final response = await _dio.post(
        '$baseUrl/parse',
        data: {
          if (html != null && html.isNotEmpty) 'html': html,
          if (rawText != null && rawText.isNotEmpty) 'rawText': rawText,
        },
        options: Options(
          contentType: 'application/json',
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['ok'] == true) {
            return SchedUParseResult(
              success: true,
              content: data['data']?['content'],
            );
          } else {
            return SchedUParseResult(
              success: false,
              errorMessage: data['error'] ?? data['message'] ?? '解析失败',
            );
          }
        }
      }

      return SchedUParseResult(
        success: false,
        errorMessage: '服务响应异常 (${response.statusCode})',
      );
    } on DioException catch (e) {
      return SchedUParseResult(
        success: false,
        errorMessage: _handleDioError(e),
      );
    } catch (e) {
      return SchedUParseResult(
        success: false,
        errorMessage: '解析请求失败: $e',
      );
    }
  }

  /// 解析课程表（流式）
  /// 
  /// 使用SSE方式接收解析进度，返回流式事件
  Stream<SchedUStreamEvent> parseStream({
    String? html,
    String? rawText,
  }) async* {
    if ((html == null || html.isEmpty) && (rawText == null || rawText.isEmpty)) {
      yield SchedUStreamErrorEvent(
        message: 'html和rawText至少需要提供一个',
      );
      return;
    }

    try {
      final response = await _dio.post<ResponseBody>(
        '$baseUrl/parse-stream',
        data: {
          if (html != null && html.isNotEmpty) 'html': html,
          if (rawText != null && rawText.isNotEmpty) 'rawText': rawText,
        },
        options: Options(
          contentType: 'application/json',
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(minutes: 3),
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) {
        yield SchedUStreamErrorEvent(message: '无法获取响应流');
        return;
      }

      // 解析SSE事件流
      String buffer = '';
      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);
        
        // 按行分割处理
        while (buffer.contains('\n\n')) {
          final eventEnd = buffer.indexOf('\n\n');
          final eventStr = buffer.substring(0, eventEnd);
          buffer = buffer.substring(eventEnd + 2);

          final event = _parseSSEEvent(eventStr);
          if (event != null) {
            yield event;
            
            // 如果是完成或错误事件，结束流
            if (event is SchedUStreamCompleteEvent || 
                event is SchedUStreamErrorEvent) {
              return;
            }
          }
        }
      }
    } on DioException catch (e) {
      yield SchedUStreamErrorEvent(message: _handleDioError(e));
    } catch (e) {
      yield SchedUStreamErrorEvent(message: '流式解析失败: $e');
    }
  }

  /// 解析SSE事件
  SchedUStreamEvent? _parseSSEEvent(String eventStr) {
    String? eventType;
    String? data;

    for (final line in eventStr.split('\n')) {
      if (line.startsWith('event:')) {
        eventType = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        data = line.substring(5).trim();
      }
    }

    if (eventType == null || data == null) return null;

    try {
      final jsonData = jsonDecode(data);
      
      switch (eventType) {
        case 'start':
          return SchedUStreamStartEvent(
            message: jsonData['message'] ?? '开始连接AI服务',
          );
        case 'progress':
          return SchedUStreamProgressEvent(
            length: jsonData['length'] ?? 0,
          );
        case 'complete':
          return SchedUStreamCompleteEvent(
            success: jsonData['ok'] ?? false,
            message: jsonData['message'],
            totalLength: jsonData['totalLength'] ?? 0,
            content: jsonData['content'],
          );
        case 'error':
          return SchedUStreamErrorEvent(
            message: jsonData['message'] ?? '未知错误',
            content: jsonData['content'],
          );
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// 处理Dio错误
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络';
      case DioExceptionType.sendTimeout:
        return '发送超时，请检查网络';
      case DioExceptionType.receiveTimeout:
        return '接收超时，服务器响应过慢';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          final error = responseData['error'] ?? responseData['message'];
          if (error != null) {
            return '$error';
          }
        }
        switch (statusCode) {
          case 400:
            return '请求参数错误';
          case 429:
            return '请求过于频繁，请稍后再试';
          case 503:
            return '服务不可用';
          default:
            return '服务器错误 ($statusCode)';
        }
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '无法连接到服务器';
      default:
        return '网络错误: ${e.message}';
    }
  }
}

/// 服务测试结果
class SchedUServiceTestResult {
  final bool success;
  final String message;
  final String? timestamp;

  const SchedUServiceTestResult({
    required this.success,
    required this.message,
    this.timestamp,
  });
}

/// 服务状态
class SchedUServiceStatus {
  final bool success;
  final int totalInFlight;
  final int maxConcurrent;
  final List<SchedUModelStatus> models;
  final String? errorMessage;

  const SchedUServiceStatus({
    required this.success,
    this.totalInFlight = 0,
    this.maxConcurrent = 0,
    this.models = const [],
    this.errorMessage,
  });
}

/// 模型状态
class SchedUModelStatus {
  final String name;
  final String modelId;
  final String baseUrl;
  final int inFlight;

  const SchedUModelStatus({
    required this.name,
    required this.modelId,
    required this.baseUrl,
    required this.inFlight,
  });

  factory SchedUModelStatus.fromJson(Map<String, dynamic> json) {
    return SchedUModelStatus(
      name: json['name'] ?? '',
      modelId: json['modelId'] ?? '',
      baseUrl: json['baseUrl'] ?? '',
      inFlight: json['inFlight'] ?? 0,
    );
  }
}

/// 解析结果
class SchedUParseResult {
  final bool success;
  final String? content;
  final String? errorMessage;

  const SchedUParseResult({
    required this.success,
    this.content,
    this.errorMessage,
  });
}

/// 流式事件基类
abstract class SchedUStreamEvent {
  const SchedUStreamEvent();
}

/// 开始事件
class SchedUStreamStartEvent extends SchedUStreamEvent {
  final String message;

  const SchedUStreamStartEvent({required this.message});
}

/// 进度事件
class SchedUStreamProgressEvent extends SchedUStreamEvent {
  final int length;

  const SchedUStreamProgressEvent({required this.length});
}

/// 完成事件
class SchedUStreamCompleteEvent extends SchedUStreamEvent {
  final bool success;
  final String? message;
  final int totalLength;
  final String? content;

  const SchedUStreamCompleteEvent({
    required this.success,
    this.message,
    required this.totalLength,
    this.content,
  });
}

/// 错误事件
class SchedUStreamErrorEvent extends SchedUStreamEvent {
  final String message;
  final String? content;

  const SchedUStreamErrorEvent({
    required this.message,
    this.content,
  });
}
