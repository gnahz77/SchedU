import 'package:openai_dart/openai_dart.dart';
import '../model/ai_chat.dart';
import 'ai_chat_service.dart';

/// [openai_dart] 的 [AIChatService] 实现
class OpenaiDartImpl extends AIChatService {
  late final OpenAIClient _client;

  OpenaiDartImpl({
    required String apiKey,
    String? baseUrl,
    String? organization,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) {
    _client = OpenAIClient(
      apiKey: apiKey,
      baseUrl: baseUrl,
      beta: null,
      organization: organization,
      headers: headers,
      queryParams: queryParameters,
    );
  }

  @override
  Future<List<AIModelInfo>> listModels({bool refreshCache = false}) async {
    final res = await _client.listModels();
    return res.data
        .map((model) => AIModelInfo(
              id: model.id,
              object: model.object?.toString(),
              ownedBy: model.ownedBy,
            ))
        .toList();
  }

  @override
  Stream<String> chatStream({required AIChatRequest request}) {
    final chatRequest = _buildRequest(request);
    return _client.createChatCompletionStream(request: chatRequest).map(
      (event) => event.choices
          ?.map((choice) => choice.delta?.content ?? '')
          .join() ?? '',
    );
  }

  @override
  Future<String> chat({required AIChatRequest request}) async {
    final chatRequest = _buildRequest(request);
    final res = await _client.createChatCompletion(request: chatRequest);
    return res.choices.map((choice) => choice.message.content ?? '').join();
  }

  CreateChatCompletionRequest _buildRequest(AIChatRequest request) {
    final messages = <ChatCompletionMessage>[];
    if (request.systemPrompt != null) {
      messages.add(
        ChatCompletionMessage.system(
          content: request.systemPrompt!,
        ),
      );
    }
    messages.addAll(request.messages.map((msg) {
      return msg.role == AIChatRole.user
          ? ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(msg.content),
            )
          : ChatCompletionMessage.assistant(
              content: msg.content,
            );
    }));
    if (request.prompt != null && request.prompt!.isNotEmpty) {
      messages.add(
        ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.string(request.prompt!),
        ),
      );
    }
    return CreateChatCompletionRequest(
      model: ChatCompletionModel.modelId(request.model),
      messages: messages,
      maxTokens: request.maxTokens,
      temperature: request.temperature,
    );
  }
}
