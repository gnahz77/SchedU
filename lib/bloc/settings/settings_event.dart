import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:schedu/model/section_time.dart';
import 'package:schedu/service/course_import_service.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

/// 刷新设置数据
class RefreshSettings extends SettingsEvent {
  const RefreshSettings();
  @override
  List<Object?> get props => [];
}

/// 更新总周数
class UpdateTotalWeeks extends SettingsEvent {
  final int totalWeeks;
  const UpdateTotalWeeks(this.totalWeeks);
  @override
  List<Object?> get props => [totalWeeks];
}

/// 更新主题模式
class UpdateThemeMode extends SettingsEvent {
  final ThemeMode themeMode;
  const UpdateThemeMode(this.themeMode);
  @override
  List<Object?> get props => [themeMode];
}

/// 更新每日节数设置
class UpdateSectionConfig extends SettingsEvent {
  final int morning;
  final int afternoon;
  final int evening;
  const UpdateSectionConfig(this.morning, this.afternoon, this.evening);
  @override
  List<Object?> get props => [morning, afternoon, evening];
}

/// 更新每节课的时间设置
class UpdateSectionTimes extends SettingsEvent {
  final List<SectionTime> sectionTimes;
  const UpdateSectionTimes(this.sectionTimes);
  @override
  List<Object?> get props => [sectionTimes];
}

/// 更新周课表展示设置（显示周末）
class UpdateWeeklyScheduleDisplay extends SettingsEvent {
  final bool showWeekend;

  const UpdateWeeklyScheduleDisplay({
    required this.showWeekend,
  });

  @override
  List<Object?> get props => [showWeekend];
}

/// 更新开学日期
class UpdateStartSemesterDate extends SettingsEvent {
  final DateTime? date;
  const UpdateStartSemesterDate(this.date);
  @override
  List<Object?> get props => [date];
}

/// 导入课程时间设置
class ImportCourseTimes extends SettingsEvent {
  final ImportData importData;

  const ImportCourseTimes(this.importData);

  @override
  List<Object?> get props => [importData];
}

/// 导出课程时间设置
class ExportCourseTimes extends SettingsEvent {
  const ExportCourseTimes();

  @override
  List<Object?> get props => [];
}

/// 更新是否显示非当前周课程
class UpdateShowNonCurrentWeekCourses extends SettingsEvent {
  final bool show;
  const UpdateShowNonCurrentWeekCourses(this.show);
  @override
  List<Object?> get props => [show];
}