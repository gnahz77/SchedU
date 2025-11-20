import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:schedu/model/section_time.dart';

class SettingsState extends Equatable {
  final int totalWeeks;
  final int maxSections;
  final ThemeMode themeMode;
  final bool showWeekend;
  final int morningSections;
  final int afternoonSections;
  final int eveningSections;
  final List<SectionTime> sectionTimes;
  final DateTime? startSemesterDate;

  const SettingsState({
    this.totalWeeks = 20,
    this.maxSections = 12,
    this.themeMode = ThemeMode.system,
    this.showWeekend = true,
    this.morningSections = 4,
    this.afternoonSections = 4,
    this.eveningSections = 4,
    this.sectionTimes = const [],
    this.startSemesterDate,
  });

  SettingsState copyWith({
    int? totalWeeks,
    int? maxSections,
    ThemeMode? themeMode,
    bool? showWeekend,
    int? morningSections,
    int? afternoonSections,
    int? eveningSections,
    List<SectionTime>? sectionTimes,
    DateTime? startSemesterDate,
  }) {
    return SettingsState(
      totalWeeks: totalWeeks ?? this.totalWeeks,
      maxSections: maxSections ?? this.maxSections,
      themeMode: themeMode ?? this.themeMode,
      showWeekend: showWeekend ?? this.showWeekend,
      morningSections: morningSections ?? this.morningSections,
      afternoonSections: afternoonSections ?? this.afternoonSections,
      eveningSections: eveningSections ?? this.eveningSections,
      sectionTimes: sectionTimes ?? this.sectionTimes,
      startSemesterDate: startSemesterDate ?? this.startSemesterDate,
    );
  }

  @override
  List<Object?> get props => [
        totalWeeks,
        maxSections,
        themeMode,
        showWeekend,
        morningSections,
        afternoonSections,
        eveningSections,
        sectionTimes,
        startSemesterDate,
      ];
}
