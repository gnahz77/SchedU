import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:schedu/model/app_settings.dart';
import 'package:schedu/model/section_time.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置管理器
class AppSettingsStore {
  static const String _keyTotalWeeks = 'total_weeks';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyShowWeekend = 'show_weekend';
  static const String _keyMorningSections = 'morning_sections';
  static const String _keyAfternoonSections = 'afternoon_sections';
  static const String _keyEveningSections = 'evening_sections';
  static const String _keySectionTimes = 'section_times';
  static const String _keyStartSemester = 'start_semester';
  static const String _keyStartWithSunday = 'start_with_sunday';
  static const String _keyShowNonCurrentWeekCourses = 'show_non_current_week_courses';

  static AppSettingsStore? _instance;
  static AppSettingsStore get instance => _instance ??= AppSettingsStore._();

  AppSettingsStore._() {
    // load initial settings
    _prefs.then((prefs) {
      // 兼容旧版本
      if (prefs.containsKey(_keyStartSemester)) {
        final startSemester = prefs.get(_keyStartSemester);
        if (startSemester is String) {
          final timestamp = int.tryParse(startSemester);
          if (timestamp != null) {
            prefs.setInt(_keyStartSemester, timestamp);
          }
        }
      }
      _data = AppSettings(
        totalWeeks: prefs.getInt(_keyTotalWeeks) ?? 20,
        themeMode: ThemeMode.values.firstWhere(
          (mode) => mode.name == prefs.getString(_keyThemeMode),
          orElse: () => ThemeMode.system,
        ),
        showWeekend: prefs.getBool(_keyShowWeekend) ?? true,
        morningSections: prefs.getInt(_keyMorningSections) ?? 4,
        afternoonSections: prefs.getInt(_keyAfternoonSections) ?? 4,
        eveningSections: prefs.getInt(_keyEveningSections) ?? 2,
        sectionTimes: prefs.getString(_keySectionTimes) != null
            ? (jsonDecode(prefs.getString(_keySectionTimes)!) as List<dynamic>)
                .map((item) => SectionTime.fromJson(item))
                .toList()
            : AppSettings.defaultSectionTimes,
        startSemester: prefs.getInt(_keyStartSemester) ?? DateTime.now().millisecondsSinceEpoch,
        startWithSunday: prefs.getBool(_keyStartWithSunday) ?? false,
        showNonCurrentWeekCourses: prefs.getBool(_keyShowNonCurrentWeekCourses) ?? false,
      );
      _streamController.add(_data);
    });
  }

  SharedPreferences? _prefsV;
  Future<SharedPreferences> get _prefs async {
    _prefsV ??= await SharedPreferences.getInstance();
    return _prefsV!;
  }

  // 设置变更流和当前数据（单例模式下不需要关闭）
  final _streamController = StreamController<AppSettings>.broadcast();
  var _data = AppSettings();
  Stream<AppSettings> get stream => _streamController.stream;
  AppSettings get data => _data;

  Future<void> _update(Function(SharedPreferences prefs) updater) async {
    final prefs = await _prefs;
    await updater(prefs);
    _streamController.add(_data);
  }

  /// 设置本学期总周数
  Future<void> setTotalWeeks(int weeks) async {
    await _update((prefs) async {
      await prefs.setInt(_keyTotalWeeks, weeks);
      _data = _data.copyWith(
        totalWeeks: weeks,
      );
    });
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    await _update((prefs) async {
      await prefs.setString(_keyThemeMode, mode.name);
      _data = _data.copyWith(
        themeMode: mode,
      );
    });
  }

  /// 设置是否显示周末
  Future<void> setShowWeekend(bool show) async {
    await _update((prefs) async {
      await prefs.setBool(_keyShowWeekend, show);
      _data = _data.copyWith(
        showWeekend: show,
      );
    });
  }

  /// 设置上午课程节数
  Future<void> setMorningSections(int sections) async {
    await _update((prefs) async {
      await prefs.setInt(_keyMorningSections, sections);
      _data = _data.copyWith(
        morningSections: sections,
      );
    });
  }

  /// 设置下午课程节数
  Future<void> setAfternoonSections(int sections) async {
    await _update((prefs) async {
      await prefs.setInt(_keyAfternoonSections, sections);
      _data = _data.copyWith(
        afternoonSections: sections,
      );
    });
  }

  /// 设置晚上课程节数
  Future<void> setEveningSections(int sections) async {
    await _update((prefs) async {
      await prefs.setInt(_keyEveningSections, sections);
      _data = _data.copyWith(
        eveningSections: sections,
      );
    });
  }

  /// 设置开学时间
  Future<void> setStartSemester(int timestamp) async {
    await _update((prefs) async {
      await prefs.setInt(_keyStartSemester, timestamp);
      _data = _data.copyWith(
        startSemester: timestamp,
      );
    });
  }

  /// 设置是否以周日为起始日
  Future<void> setStartWithSunday(bool startWithSunday) async {
    await _update((prefs) async {
      await prefs.setBool(_keyStartWithSunday, startWithSunday);
      _data = _data.copyWith(
        startWithSunday: startWithSunday,
      );
    });
  }

  /// 设置是否显示非当前周课程
  Future<void> setShowNonCurrentWeekCourses(bool show) async {
    await _update((prefs) async {
      await prefs.setBool(_keyShowNonCurrentWeekCourses, show);
      _data = _data.copyWith(
        showNonCurrentWeekCourses: show,
      );
    });
  }

  /// 设置节次时间
  Future<void> setSectionTimesList(List<SectionTime> sectionTimes) async {
    await _update((prefs) async {
      final timesString = jsonEncode(sectionTimes.map((st) => st.toJson()).toList());
      await prefs.setString(_keySectionTimes, timesString);
      _data = _data.copyWith(
        sectionTimes: sectionTimes,
      );
    });
  }

  /// 导入时间表配置
  Future<void> importScheduleConfig(ScheduleConfig config) async {
    // 导入总周数
    if (config.totalWeek != null && config.totalWeek! >= 1 && config.totalWeek! <= 50) {
      await setTotalWeeks(config.totalWeek!);
    }

    // 导入开学时间
    if (config.startSemester != null && config.startSemester!.length == 13) {
      await setStartSemester(int.parse(config.startSemester!));
    }

    // 导入周日起始设置
    if (config.startWithSunday != null) {
      await setStartWithSunday(config.startWithSunday!);
      // 如果设置为周日起始，自动开启周末显示
      if (config.startWithSunday!) {
        await setShowWeekend(true);
      }
    }

    // 导入周末显示设置
    if (config.showWeekend != null) {
      await setShowWeekend(config.showWeekend!);
    }

    // 导入课程时间段设置
    if (config.forenoon != null && config.forenoon! >= 1 && config.forenoon! <= 10) {
      await setMorningSections(config.forenoon!);
    }
    if (config.afternoon != null && config.afternoon! >= 0 && config.afternoon! <= 10) {
      await setAfternoonSections(config.afternoon!);
    }
    if (config.night != null && config.night! >= 0 && config.night! <= 10) {
      await setEveningSections(config.night!);
    }

    // 导入节次时间设置
    if (config.sections != null && config.sections!.isNotEmpty) {
      // 验证节次时间格式
      final validSections = config.sections!.where((section) {
        return section.section >= 1 &&
               section.section <= 30 &&
               _isValidTimeFormat(section.startTime) &&
               _isValidTimeFormat(section.endTime);
      }).toList();
      validSections.sort((a, b) => a.section.compareTo(b.section));

      if (validSections.isNotEmpty) {
        // 按节次排序
        validSections.sort((a, b) => a.section.compareTo(b.section));
        await setSectionTimesList(validSections);
      }
    }
  }

  /// 验证时间格式（HH:MM）
  bool _isValidTimeFormat(String time) {
    if (time.length != 5) return false;
    final parts = time.split(':');
    if (parts.length != 2) return false;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    return hour != null &&
           minute != null &&
           hour >= 0 &&
           hour <= 23 &&
           minute >= 0 &&
           minute <= 59;
  }

  /// 规范化日期（去除时间部分）
  DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  /// 导出当前时间表配置
  Future<ScheduleConfig> exportScheduleConfig() async {
    return ScheduleConfig(
      totalWeek: data.totalWeeks,
      startSemester: data.startSemester.toString(),
      startWithSunday: data.startWithSunday,
      showWeekend: data.showWeekend,
      forenoon: data.morningSections,
      afternoon: data.afternoonSections,
      night: data.eveningSections,
      sections: data.sectionTimes,
    );
  }
}
