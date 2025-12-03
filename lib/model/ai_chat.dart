class AIModelInfo {
  final String id;
  final String? object;
  final String? ownedBy;

  AIModelInfo({required this.id, this.object, this.ownedBy});
}

class AIChatRequest {
  final String model;
  final String? prompt;
  final List<AIChatMessage> messages;
  final String? systemPrompt;
  final int? maxTokens;
  final double? temperature;

  AIChatRequest({
    required this.model,
    this.prompt,
    this.messages = const [],
    this.systemPrompt,
    this.maxTokens,
    this.temperature,
  });
}

class AIChatMessage {
  final AIChatRole role;
  final String content;

  AIChatMessage({required this.role, required this.content});
}


enum AIChatRole {
  user,
  assistant,
}