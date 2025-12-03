import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:schedu/gen/assets.gen.dart';

part 'ai_service_provider.g.dart';

/// AI服务提供商信息
@JsonSerializable()
class AiServiceProvider {
  final String name;
  final String baseUrl;
  final String defaultModel;
  final String icon;

  AiServiceProvider({
    required this.name,
    required this.baseUrl,
    required this.defaultModel,
    required this.icon,
  });

  factory AiServiceProvider.fromJson(Map<String, dynamic> json) => _$AiServiceProviderFromJson(json);

  Map<String, dynamic> toJson() => _$AiServiceProviderToJson(this);

  /// 从assets加载所有服务提供商
  static Future<List<AiServiceProvider>> loadProviders() async {
    try {
      final String jsonString = await rootBundle.loadString(Assets.aiServiceProvider);
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => AiServiceProvider.fromJson(json)).toList();
    } catch (e) {
      throw Exception('加载AI服务提供商配置失败: $e');
    }
  }
}
