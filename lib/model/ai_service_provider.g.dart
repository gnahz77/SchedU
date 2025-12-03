// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_service_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AiServiceProvider _$AiServiceProviderFromJson(Map<String, dynamic> json) =>
    AiServiceProvider(
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      defaultModel: json['defaultModel'] as String,
      icon: json['icon'] as String,
    );

Map<String, dynamic> _$AiServiceProviderToJson(AiServiceProvider instance) =>
    <String, dynamic>{
      'name': instance.name,
      'baseUrl': instance.baseUrl,
      'defaultModel': instance.defaultModel,
      'icon': instance.icon,
    };
