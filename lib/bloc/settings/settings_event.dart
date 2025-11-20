import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:schedu/model/section_time.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateTotalWeeks extends SettingsEvent {
  final int totalWeeks;
  const UpdateTotalWeeks(this.totalWeeks);
  @override
  List<Object?> get props => [totalWeeks];
}

class UpdateMaxSections extends SettingsEvent {
  final int maxSections;
  const UpdateMaxSections(this.maxSections);
  @override
  List<Object?> get props => [maxSections];
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

class ImportScheduleConfig extends SettingsEvent {
  final ScheduleConfig config;
  const ImportScheduleConfig(this.config);
  @override
  List<Object?> get props => [config];
}
