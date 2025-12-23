import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:schedu/model/section_time.dart';

class AppSettings extends Equatable {
  // 学期总周数
  final int totalWeeks;
  // 主题模式
  final ThemeMode themeMode;
  // 是否显示周末
  final bool showWeekend;
  // 上午节数
  final int morningSections;
  // 下午节数
  final int afternoonSections;
  // 晚上节数
  final int eveningSections;
  // 节次时间列表
  final List<SectionTime> sectionTimes;
  // 开学时间
  final int startSemester;
  // 开学时间是否从星期天开始计算
  final bool startWithSunday;
  // 周课表宽度自适应
  final bool adaptiveWidth;

  const AppSettings({
    this.totalWeeks = 20,
    this.themeMode = ThemeMode.system,
    this.showWeekend = true,
    this.morningSections = 4,
    this.afternoonSections = 4,
    this.eveningSections = 4,
    this.sectionTimes = defaultSectionTimes,
    this.startWithSunday = false,
    this.startSemester = -1,
    this.adaptiveWidth = true,
  });

  /// 每日总节数
  int get totalDailySections =>
      morningSections + afternoonSections + eveningSections;

  /// 默认节次列表（与原 `AppSettingsStore._getDefaultSectionTimesList()` 保持一致）
  static const List<SectionTime> defaultSectionTimes = [
    SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
    SectionTime(section: 2, startTime: '08:55', endTime: '09:40'),
    SectionTime(section: 3, startTime: '10:00', endTime: '10:45'),
    SectionTime(section: 4, startTime: '10:55', endTime: '11:40'),
    SectionTime(section: 5, startTime: '14:00', endTime: '14:45'),
    SectionTime(section: 6, startTime: '14:55', endTime: '15:40'),
    SectionTime(section: 7, startTime: '16:00', endTime: '16:45'),
    SectionTime(section: 8, startTime: '16:55', endTime: '17:40'),
    SectionTime(section: 9, startTime: '19:00', endTime: '19:45'),
    SectionTime(section: 10, startTime: '19:55', endTime: '20:40'),
    SectionTime(section: 11, startTime: '20:50', endTime: '21:35'),
    SectionTime(section: 12, startTime: '21:45', endTime: '22:30'),
  ];

  /// 如果需要在运行时确保节次不为空，可使用该 getter
  List<SectionTime> get effectiveSectionTimes =>
      sectionTimes.isNotEmpty ? sectionTimes : defaultSectionTimes;

  AppSettings copyWith({
    int? totalWeeks,
    ThemeMode? themeMode,
    bool? showWeekend,
    int? morningSections,
    int? afternoonSections,
    int? eveningSections,
    List<SectionTime>? sectionTimes,
    int? startSemester,
    bool? startWithSunday,
    bool? adaptiveWidth,
  }) {
    return AppSettings(
      totalWeeks: totalWeeks ?? this.totalWeeks,
      themeMode: themeMode ?? this.themeMode,
      showWeekend: showWeekend ?? this.showWeekend,
      morningSections: morningSections ?? this.morningSections,
      afternoonSections: afternoonSections ?? this.afternoonSections,
      eveningSections: eveningSections ?? this.eveningSections,
      sectionTimes: sectionTimes ?? this.sectionTimes,
      startSemester: startSemester ?? this.startSemester,
      startWithSunday: startWithSunday ?? this.startWithSunday,
      adaptiveWidth: adaptiveWidth ?? this.adaptiveWidth,
    );
  }

  @override
  List<Object?> get props => [
    totalWeeks,
    themeMode,
    showWeekend,
    morningSections,
    afternoonSections,
    eveningSections,
    sectionTimes,
    startSemester,
    startWithSunday,
    adaptiveWidth,
  ];
}
