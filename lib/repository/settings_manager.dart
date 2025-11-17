import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:schedu/model/section_time.dart';

/// 应用设置管理器
class SettingsManager {
  static const String _keyCurrentWeek = 'current_week';
  static const String _keyTotalWeeks = 'total_weeks';
  static const String _keyMaxSections = 'max_sections';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyShowWeekend = 'show_weekend';
  static const String _keyMorningSections = 'morning_sections';
  static const String _keyAfternoonSections = 'afternoon_sections';
  static const String _keyEveningSections = 'evening_sections';
  static const String _keySectionTimes = 'section_times';
  static const String _keyStartSemester = 'start_semester';
  static const String _keyStartWithSunday = 'start_with_sunday';

  static SettingsManager? _instance;
  static SettingsManager get instance => _instance ??= SettingsManager._();

  SettingsManager._();

  SharedPreferences? _prefs;

  /// 初始化设置管理器
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 获取当前周数
  Future<int> getCurrentWeek() async {
    await init();
    return _prefs?.getInt(_keyCurrentWeek) ?? 1;
  }

  /// 设置当前周数
  Future<void> setCurrentWeek(int week) async {
    await init();
    await _prefs?.setInt(_keyCurrentWeek, week);
  }

  /// 获取本学期总周数
  Future<int> getTotalWeeks() async {
    await init();
    return _prefs?.getInt(_keyTotalWeeks) ?? 20;
  }

  /// 设置本学期总周数
  Future<void> setTotalWeeks(int weeks) async {
    await init();
    await _prefs?.setInt(_keyTotalWeeks, weeks);
  }

  /// 获取每日最大节数
  Future<int> getMaxSections() async {
    await init();
    return _prefs?.getInt(_keyMaxSections) ?? 12;
  }

  /// 设置每日最大节数
  Future<void> setMaxSections(int sections) async {
    await init();
    await _prefs?.setInt(_keyMaxSections, sections);
  }

  /// 获取主题模式
  Future<String> getThemeMode() async {
    await init();
    return _prefs?.getString(_keyThemeMode) ?? 'system';
  }

  /// 设置主题模式
  Future<void> setThemeMode(String mode) async {
    await init();
    await _prefs?.setString(_keyThemeMode, mode);
  }

  /// 是否显示周末
  Future<bool> getShowWeekend() async {
    await init();
    return _prefs?.getBool(_keyShowWeekend) ?? true;
  }

  /// 设置是否显示周末
  Future<void> setShowWeekend(bool show) async {
    await init();
    await _prefs?.setBool(_keyShowWeekend, show);
  }

  /// 获取上午课程节数
  Future<int> getMorningSections() async {
    await init();
    return _prefs?.getInt(_keyMorningSections) ?? 4;
  }

  /// 设置上午课程节数
  Future<void> setMorningSections(int sections) async {
    await init();
    await _prefs?.setInt(_keyMorningSections, sections);
  }

  /// 获取下午课程节数
  Future<int> getAfternoonSections() async {
    await init();
    return _prefs?.getInt(_keyAfternoonSections) ?? 4;
  }

  /// 设置下午课程节数
  Future<void> setAfternoonSections(int sections) async {
    await init();
    await _prefs?.setInt(_keyAfternoonSections, sections);
  }

  /// 获取晚上课程节数
  Future<int> getEveningSections() async {
    await init();
    return _prefs?.getInt(_keyEveningSections) ?? 4;
  }

  /// 设置晚上课程节数
  Future<void> setEveningSections(int sections) async {
    await init();
    await _prefs?.setInt(_keyEveningSections, sections);
  }

  /// 获取开学时间
  Future<String?> getStartSemester() async {
    await init();
    return _prefs?.getString(_keyStartSemester);
  }

  /// 设置开学时间
  Future<void> setStartSemester(String? timestamp) async {
    await init();
    if (timestamp != null) {
      await _prefs?.setString(_keyStartSemester, timestamp);
    } else {
      await _prefs?.remove(_keyStartSemester);
    }
  }

  /// 是否以周日为起始日
  Future<bool> getStartWithSunday() async {
    await init();
    return _prefs?.getBool(_keyStartWithSunday) ?? false;
  }

  /// 设置是否以周日为起始日
  Future<void> setStartWithSunday(bool startWithSunday) async {
    await init();
    await _prefs?.setBool(_keyStartWithSunday, startWithSunday);
  }

  /// 获取节次时间设置
  Future<List<SectionTime>> getSectionTimesList() async {
    await init();
    final timesString = _prefs?.getString(_keySectionTimes);
    if (timesString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(timesString);
        return decoded.map((item) => SectionTime.fromJson(item)).toList();
      } catch (e) {
        // 解析失败，返回默认设置
        return _getDefaultSectionTimesList();
      }
    }

    // 返回默认节次时间设置
    return _getDefaultSectionTimesList();
  }

  /// 设置节次时间
  Future<void> setSectionTimesList(List<SectionTime> sectionTimes) async {
    await init();
    final timesString = jsonEncode(sectionTimes.map((st) => st.toJson()).toList());
    await _prefs?.setString(_keySectionTimes, timesString);
  }

  /// 导入时间表配置
  Future<void> importScheduleConfig(ScheduleConfig config) async {
    await init();

    // 导入总周数
    if (config.totalWeek != null && config.totalWeek! >= 10 && config.totalWeek! <= 35) {
      await setTotalWeeks(config.totalWeek!);
    }

    // 导入开学时间
    if (config.startSemester != null && config.startSemester!.length == 13) {
      await setStartSemester(config.startSemester);
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

    // 更新总节数
    final morning = await getMorningSections();
    final afternoon = await getAfternoonSections();
    final evening = await getEveningSections();
    await setMaxSections(morning + afternoon + evening);

    // 导入节次时间设置
    if (config.sections != null && config.sections!.isNotEmpty) {
      // 验证节次时间格式
      final validSections = config.sections!.where((section) {
        return section.section >= 1 &&
               section.section <= 30 &&
               _isValidTimeFormat(section.startTime) &&
               _isValidTimeFormat(section.endTime);
      }).toList();

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

  /// 获取默认节次时间设置
  List<SectionTime> _getDefaultSectionTimesList() {
    return [
      const SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
      const SectionTime(section: 2, startTime: '08:55', endTime: '09:40'),
      const SectionTime(section: 3, startTime: '10:00', endTime: '10:45'),
      const SectionTime(section: 4, startTime: '10:55', endTime: '11:40'),
      const SectionTime(section: 5, startTime: '14:00', endTime: '14:45'),
      const SectionTime(section: 6, startTime: '14:55', endTime: '15:40'),
      const SectionTime(section: 7, startTime: '16:00', endTime: '16:45'),
      const SectionTime(section: 8, startTime: '16:55', endTime: '17:40'),
      const SectionTime(section: 9, startTime: '19:00', endTime: '19:45'),
      const SectionTime(section: 10, startTime: '19:55', endTime: '20:40'),
      const SectionTime(section: 11, startTime: '20:50', endTime: '21:35'),
      const SectionTime(section: 12, startTime: '21:45', endTime: '22:30'),
    ];
  }
}
