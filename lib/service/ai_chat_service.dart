import '../model/ai_chat.dart';

abstract class AIChatService {
  /// 列出可用的模型
  Future<List<AIModelInfo>> listModels({bool refreshCache = false});
  /// 通过流式方式进行聊天
  Stream<String> chatStream({required AIChatRequest request});
  /// 通过一次性请求进行聊天
  Future<String> chat({required AIChatRequest request});
}