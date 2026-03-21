// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// Directory path: assets/images/ai
  $AssetsImagesAiGen get ai => const $AssetsImagesAiGen();

  /// File path: assets/images/schedu_icon.svg
  String get scheduIcon => 'assets/images/schedu_icon.svg';

  /// List of all assets
  List<String> get values => [scheduIcon];
}

class $AssetsImagesAiGen {
  const $AssetsImagesAiGen();

  /// File path: assets/images/ai/Baidu.ico
  String get baidu => 'assets/images/ai/Baidu.ico';

  /// File path: assets/images/ai/ChatGPT.ico
  String get chatGPT => 'assets/images/ai/ChatGPT.ico';

  /// File path: assets/images/ai/Claude.png
  AssetGenImage get claude =>
      const AssetGenImage('assets/images/ai/Claude.png');

  /// File path: assets/images/ai/DeepSeek.png
  AssetGenImage get deepSeek =>
      const AssetGenImage('assets/images/ai/DeepSeek.png');

  /// File path: assets/images/ai/DouBao.png
  AssetGenImage get douBao =>
      const AssetGenImage('assets/images/ai/DouBao.png');

  /// File path: assets/images/ai/GLM.png
  AssetGenImage get glm => const AssetGenImage('assets/images/ai/GLM.png');

  /// File path: assets/images/ai/Gemini.png
  AssetGenImage get gemini =>
      const AssetGenImage('assets/images/ai/Gemini.png');

  /// File path: assets/images/ai/Grok.png
  AssetGenImage get grok => const AssetGenImage('assets/images/ai/Grok.png');

  /// File path: assets/images/ai/Kimi.png
  AssetGenImage get kimi => const AssetGenImage('assets/images/ai/Kimi.png');

  /// File path: assets/images/ai/MiMo.jpg
  AssetGenImage get miMo => const AssetGenImage('assets/images/ai/MiMo.jpg');

  /// File path: assets/images/ai/Qwen.png
  AssetGenImage get qwen => const AssetGenImage('assets/images/ai/Qwen.png');

  /// File path: assets/images/ai/Tencent.png
  AssetGenImage get tencent =>
      const AssetGenImage('assets/images/ai/Tencent.png');

  /// List of all assets
  List<dynamic> get values => [
    baidu,
    chatGPT,
    claude,
    deepSeek,
    douBao,
    glm,
    gemini,
    grok,
    kimi,
    miMo,
    qwen,
    tencent,
  ];
}

class Assets {
  const Assets._();

  static const String aiServiceProvider = 'assets/ai_service_provider.json';
  static const $AssetsImagesGen images = $AssetsImagesGen();
  static const String libLicense = 'assets/lib_license.txt';
  static const String prompt = 'assets/prompt.txt';
  static const String scheduleParse = 'assets/schedule_parse.js';

  /// List of all assets
  static List<String> get values => [
    aiServiceProvider,
    libLicense,
    prompt,
    scheduleParse,
  ];
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
