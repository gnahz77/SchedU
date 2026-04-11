import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:schedu/repository/app_update_store.dart';

/// 应用更新检测服务
///
/// 负责：
/// 1. 获取当前应用版本；
/// 2. 调用 GitHub Releases latest API；
/// 3. 执行 12 小时缓存与“此版本不再提醒”策略；
/// 4. 生成 UI 层展示更新弹窗所需的数据。
class AppUpdateService {
  /// GitHub 最新 release 接口
  static const String _latestReleaseApi =
      'https://api.github.com/repos/gnahz77/SchedU/releases/latest';

  /// GitHub release 列表页兜底地址
  static const String _defaultReleasePageUrl =
      'https://github.com/gnahz77/SchedU/releases';

  /// 更新检查缓存有效期
  static const Duration _cacheDuration = Duration(hours: 12);

  final AppUpdateStore _store;
  final Dio _dio;
  final Future<PackageInfo> Function() _packageInfoLoader;
  final DateTime Function() _now;

  /// 创建更新检测服务
  ///
  /// 支持注入 Dio、时间源和 PackageInfo 获取器，便于测试。
  AppUpdateService({
    AppUpdateStore? store,
    Dio? dio,
    Future<PackageInfo> Function()? packageInfoLoader,
    DateTime Function()? now,
  })  : _store = store ?? AppUpdateStore(),
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                headers: {
                  'User-Agent': 'SchedU-App-Update-Checker',
                  'Accept': 'application/vnd.github+json',
                },
              ),
            ),
        _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform,
        _now = now ?? DateTime.now;

  /// 检查是否需要提示用户更新
  ///
  /// 返回 null 表示当前不需要提示；
  /// 返回 [AppUpdatePrompt] 表示应弹出更新提示。
  /// [manual] 为 true 时，忽略版本静默和 12 小时缓存，强制从网络获取。
  Future<AppUpdatePrompt?> checkForUpdate({bool manual = false}) async {
    final now = _now();
    final packageInfo = await _packageInfoLoader();
    final currentVersion = _normalizeVersion(packageInfo.version);
    final skippedVersion = manual ? null : await _store.getSkippedVersion();
    final cachedResult = await _getCachedResult();
    final lastCheckAt = await _store.getLastCheckAt();

    if (!manual && lastCheckAt != null) {
      final elapsed = now.millisecondsSinceEpoch - lastCheckAt;
      if (elapsed >= 0 && elapsed < _cacheDuration.inMilliseconds) {
        return _buildPromptFromResult(
          currentVersion: currentVersion,
          skippedVersion: skippedVersion,
          result: cachedResult,
        );
      }
    }

    final latestResult = await _fetchLatestRelease(now);
    return _buildPromptFromResult(
      currentVersion: currentVersion,
      skippedVersion: skippedVersion,
      result: latestResult.result ??
          (latestResult.allowCachedFallback == false ? null : cachedResult),
    );
  }

  /// 将指定版本标记为“不再提醒”
  Future<void> skipVersion(String version) async {
    final normalizedVersion = _normalizeVersion(version);
    if (normalizedVersion.isEmpty) return;

    await _store.setSkippedVersion(normalizedVersion);
  }

  /// 根据查询结果构造弹窗所需信息
  AppUpdatePrompt? _buildPromptFromResult({
    required String currentVersion,
    required String? skippedVersion,
    required AppUpdateQueryResult? result,
  }) {
    if (result == null) return null;

    final latestVersion = _normalizeVersion(result.tagName);
    if (latestVersion.isEmpty || latestVersion == currentVersion) {
      return null;
    }

    if (skippedVersion != null && skippedVersion == latestVersion) {
      return null;
    }

    return AppUpdatePrompt(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      releaseUrl: result.releaseUrl,
    );
  }

  /// 读取本地缓存的 release 信息
  Future<AppUpdateQueryResult?> _getCachedResult() async {
    final tagName = await _store.getCachedTagName();
    if (tagName == null || tagName.trim().isEmpty) {
      return null;
    }

    final releaseUrl = await _store.getCachedReleaseUrl();
    return AppUpdateQueryResult(
      tagName: tagName,
      releaseUrl: releaseUrl ?? _defaultReleasePageUrl,
    );
  }

  /// 从 GitHub 拉取最新 release 信息
  ///
  /// - 请求成功：返回最新结果并刷新缓存；
  /// - 请求失败：允许回退到旧缓存；
  /// - 响应结构无效：清理旧缓存，避免误报过期版本。
  Future<AppUpdateFetchResult> _fetchLatestRelease(DateTime now) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_latestReleaseApi);
      final data = response.data;
      final tagName = data?['tag_name'];
      if (tagName is! String || tagName.trim().isEmpty) {
        await _store.setLastCheckAt(now.millisecondsSinceEpoch);
        await _store.clearCachedTagName();
        await _store.clearCachedReleaseUrl();
        return const AppUpdateFetchResult(
          allowCachedFallback: false,
        );
      }

      final releaseUrl = data?['html_url'];
      final normalizedReleaseUrl =
          releaseUrl is String && releaseUrl.trim().isNotEmpty
              ? releaseUrl
              : _defaultReleasePageUrl;

      await _store.setLastCheckAt(now.millisecondsSinceEpoch);
      await _store.setCachedTagName(tagName);
      await _store.setCachedReleaseUrl(normalizedReleaseUrl);

      return AppUpdateFetchResult(
        allowCachedFallback: false,
        result: AppUpdateQueryResult(
          tagName: tagName,
          releaseUrl: normalizedReleaseUrl,
        ),
      );
    } catch (_) {
      await _store.setLastCheckAt(now.millisecondsSinceEpoch);
      return const AppUpdateFetchResult(
        allowCachedFallback: true,
      );
    }
  }

  /// 归一化版本号，避免 `v1.2.3` 与 `1.2.3+45` 直接比较时误判
  static String _normalizeVersion(String version) {
    final normalized = version.trim();
    if (normalized.isEmpty) return '';

    final withoutPrefix = normalized.startsWith('v') || normalized.startsWith('V')
        ? normalized.substring(1)
        : normalized;
    return withoutPrefix.split('+').first.trim();
  }
}

/// 更新弹窗展示所需的数据
class AppUpdatePrompt {
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;

  const AppUpdatePrompt({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
  });
}

/// GitHub latest release 查询结果
class AppUpdateQueryResult {
  final String tagName;
  final String releaseUrl;

  const AppUpdateQueryResult({
    required this.tagName,
    required this.releaseUrl,
  });
}

/// 一次远端更新检查的结果
///
/// [allowCachedFallback] 为 true 时，表示本次请求失败但可以继续使用旧缓存；
/// 为 false 时，表示本次结果已经足够明确，不应再回退到旧缓存。
class AppUpdateFetchResult {
  final AppUpdateQueryResult? result;
  final bool allowCachedFallback;

  const AppUpdateFetchResult({
    this.result,
    required this.allowCachedFallback,
  });
}
