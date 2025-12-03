import 'package:shared_preferences/shared_preferences.dart';

/// 教务导入配置管理器
class JwImportSettings {
  static const String _keyJwUrl = 'jw_import_url';
  static const String _keyImportMode = 'jw_import_mode';
  static const String _keyAiProvider = 'jw_ai_provider';
  static const String _keyCustomApiUrl = 'jw_custom_api_url';
  static const String _keyApiKey = 'jw_api_key';
  static const String _keyAiModel = 'jw_ai_model';
  static const String _keyUseCustomModel = 'jw_use_custom_model';
  static const String _keyMaxTextLength = 'jw_max_text_length';

  /// 保存教务系统URL
  static Future<void> saveJwUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyJwUrl, url);
  }

  /// 获取教务系统URL
  static Future<String> getJwUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyJwUrl) ?? '';
  }

  /// 保存导入模式 (ai 或 js)
  static Future<void> saveImportMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyImportMode, mode);
  }

  /// 获取导入模式
  static Future<String> getImportMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyImportMode) ?? 'ai';
  }

  /// 保存AI服务商 (openai, anthropic, custom)
  static Future<void> saveAiProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiProvider, provider);
  }

  /// 获取AI服务商
  static Future<String> getAiProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAiProvider) ?? 'openai';
  }

  /// 保存自定义API地址
  static Future<void> saveCustomApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomApiUrl, url);
  }

  /// 获取自定义API地址
  static Future<String> getCustomApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomApiUrl) ?? '';
  }

  /// 保存API Key
  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, apiKey);
  }

  /// 获取API Key
  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey) ?? '';
  }

  /// 保存AI模型
  static Future<void> saveAiModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiModel, model);
  }

  /// 获取AI模型
  static Future<String> getAiModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAiModel) ?? 'gpt-3.5-turbo';
  }

  /// 保存是否使用自定义模型
  static Future<void> saveUseCustomModel(bool useCustom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseCustomModel, useCustom);
  }

  /// 获取是否使用自定义模型
  static Future<bool> getUseCustomModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseCustomModel) ?? false;
  }

  /// 保存最大文本长度
  static Future<void> saveMaxTextLength(int length) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxTextLength, length);
  }

  /// 获取最大文本长度
  static Future<int> getMaxTextLength() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMaxTextLength) ?? (1024*32);
  }

  /// 清除所有配置
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyJwUrl);
    await prefs.remove(_keyImportMode);
    await prefs.remove(_keyAiProvider);
    await prefs.remove(_keyCustomApiUrl);
    await prefs.remove(_keyApiKey);
    await prefs.remove(_keyAiModel);
    await prefs.remove(_keyUseCustomModel);
    await prefs.remove(_keyMaxTextLength);
  }
}
