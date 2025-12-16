import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:schedu/model/section_time.dart';
import 'package:schedu/service/course_import_service.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class RefreshSettings extends SettingsEvent {
  const RefreshSettings();
  @override
  List<Object?> get props => [];
}

class UpdateTotalWeeks extends SettingsEvent {
  final int totalWeeks;
  const UpdateTotalWeeks(this.totalWeeks);
  @override
  List<Object?> get props => [totalWeeks];
}

class UpdateThemeMode extends SettingsEvent {
  final ThemeMode themeMode;
  const UpdateThemeMode(this.themeMode);
  @override
  List<Object?> get props => [themeMode];
}

class UpdateShowWeekend extends SettingsEvent {
  final bool showWeekend;
  const UpdateShowWeekend(this.showWeekend);
  @override
  List<Object?> get props => [showWeekend];
}

class UpdateSectionConfig extends SettingsEvent {
  final int morning;
  final int afternoon;
  final int evening;
  const UpdateSectionConfig(this.morning, this.afternoon, this.evening);
  @override
  List<Object?> get props => [morning, afternoon, evening];
}

class UpdateSectionTimes extends SettingsEvent {
  final List<SectionTime> sectionTimes;
  const UpdateSectionTimes(this.sectionTimes);
  @override
  List<Object?> get props => [sectionTimes];
}

class UpdateStartSemesterDate extends SettingsEvent {
  final DateTime? date;
  const UpdateStartSemesterDate(this.date);
  @override
  List<Object?> get props => [date];
}

class ImportCourseTimes extends SettingsEvent {
  final ImportData importData;

  const ImportCourseTimes(this.importData);

  @override
  List<Object?> get props => [importData];
}

class ExportCourseTimes extends SettingsEvent {
  const ExportCourseTimes();

  @override
  List<Object?> get props => [];
}