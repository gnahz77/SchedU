import 'package:shared_preferences/shared_preferences.dart';

/// 应用更新检查缓存与静默设置存储
class AppUpdateStore {
  /// 最近一次向 GitHub 发起检查的时间戳
  static const String _keyLastCheckAt = 'app_update_last_check_at';

  /// 最近一次成功获取到的 release tag
  static const String _keyCachedTagName = 'app_update_cached_tag_name';

  /// 最近一次成功获取到的 release 页面地址
  static const String _keyCachedReleaseUrl = 'app_update_cached_release_url';

  /// 当前被用户选择“不再提醒”的版本号
  static const String _keySkippedVersion = 'app_update_skipped_version';

  /// 获取 SharedPreferences 实例
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// 读取最近一次检查时间
  Future<int?> getLastCheckAt() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyLastCheckAt);
  }

  /// 保存最近一次检查时间
  Future<void> setLastCheckAt(int timestamp) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyLastCheckAt, timestamp);
  }

  /// 读取缓存的最新 tag
  Future<String?> getCachedTagName() async {
    final prefs = await _prefs;
    return prefs.getString(_keyCachedTagName);
  }

  /// 保存缓存的最新 tag
  Future<void> setCachedTagName(String tagName) async {
    final prefs = await _prefs;
    await prefs.setString(_keyCachedTagName, tagName);
  }

  /// 清除缓存的最新 tag
  Future<void> clearCachedTagName() async {
    final prefs = await _prefs;
    await prefs.remove(_keyCachedTagName);
  }

  /// 读取缓存的 release 页面地址
  Future<String?> getCachedReleaseUrl() async {
    final prefs = await _prefs;
    return prefs.getString(_keyCachedReleaseUrl);
  }

  /// 保存缓存的 release 页面地址
  Future<void> setCachedReleaseUrl(String releaseUrl) async {
    final prefs = await _prefs;
    await prefs.setString(_keyCachedReleaseUrl, releaseUrl);
  }

  /// 清除缓存的 release 页面地址
  Future<void> clearCachedReleaseUrl() async {
    final prefs = await _prefs;
    await prefs.remove(_keyCachedReleaseUrl);
  }

  /// 读取当前被忽略提醒的版本号
  Future<String?> getSkippedVersion() async {
    final prefs = await _prefs;
    return prefs.getString(_keySkippedVersion);
  }

  /// 保存当前被忽略提醒的版本号
  Future<void> setSkippedVersion(String version) async {
    final prefs = await _prefs;
    await prefs.setString(_keySkippedVersion, version);
  }

  /// 清除版本忽略状态
  Future<void> clearSkippedVersion() async {
    final prefs = await _prefs;
    await prefs.remove(_keySkippedVersion);
  }
}
