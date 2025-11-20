import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/settings/settings_event.dart';
import 'package:schedu/bloc/settings/settings_state.dart';
import 'package:schedu/repository/settings_manager.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsManager _settingsManager;

  SettingsBloc(this._settingsManager) : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateTotalWeeks>(_onUpdateTotalWeeks);
    on<UpdateMaxSections>(_onUpdateMaxSections);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateShowWeekend>(_onUpdateShowWeekend);
    on<UpdateSectionConfig>(_onUpdateSectionConfig);
    on<UpdateSectionTimes>(_onUpdateSectionTimes);
    on<UpdateStartSemesterDate>(_onUpdateStartSemesterDate);
    on<ImportScheduleConfig>(_onImportScheduleConfig);
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    final totalWeeks = await _settingsManager.getTotalWeeks();
    final maxSections = await _settingsManager.getMaxSections();
    final themeModeStr = await _settingsManager.getThemeMode();
    final showWeekend = await _settingsManager.getShowWeekend();
    final morning = await _settingsManager.getMorningSections();
    final afternoon = await _settingsManager.getAfternoonSections();
    final evening = await _settingsManager.getEveningSections();
    final sectionTimes = await _settingsManager.getSectionTimesList();
    final startDate = await _settingsManager.getStartSemesterDate();

    ThemeMode themeMode;
    if (themeModeStr == 'light') {
      themeMode = ThemeMode.light;
    } else if (themeModeStr == 'dark') {
      themeMode = ThemeMode.dark;
    } else {
      themeMode = ThemeMode.system;
    }

    emit(SettingsState(
      totalWeeks: totalWeeks,
      maxSections: maxSections,
      themeMode: themeMode,
      showWeekend: showWeekend,
      morningSections: morning,
      afternoonSections: afternoon,
      eveningSections: evening,
      sectionTimes: sectionTimes,
      startSemesterDate: startDate,
    ));
  }

  Future<void> _onUpdateTotalWeeks(UpdateTotalWeeks event, Emitter<SettingsState> emit) async {
    await _settingsManager.setTotalWeeks(event.totalWeeks);
    emit(state.copyWith(totalWeeks: event.totalWeeks));
  }

  Future<void> _onUpdateMaxSections(UpdateMaxSections event, Emitter<SettingsState> emit) async {
    await _settingsManager.setMaxSections(event.maxSections);
    emit(state.copyWith(maxSections: event.maxSections));
  }

  Future<void> _onUpdateThemeMode(UpdateThemeMode event, Emitter<SettingsState> emit) async {
    String modeStr;
    switch (event.themeMode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      default:
        modeStr = 'system';
    }
    await _settingsManager.setThemeMode(modeStr);
    emit(state.copyWith(themeMode: event.themeMode));
  }

  Future<void> _onUpdateShowWeekend(UpdateShowWeekend event, Emitter<SettingsState> emit) async {
    await _settingsManager.setShowWeekend(event.showWeekend);
    emit(state.copyWith(showWeekend: event.showWeekend));
  }

  Future<void> _onUpdateSectionConfig(UpdateSectionConfig event, Emitter<SettingsState> emit) async {
    await _settingsManager.setMorningSections(event.morning);
    await _settingsManager.setAfternoonSections(event.afternoon);
    await _settingsManager.setEveningSections(event.evening);
    
    final total = event.morning + event.afternoon + event.evening;
    await _settingsManager.setMaxSections(total);

    emit(state.copyWith(
      morningSections: event.morning,
      afternoonSections: event.afternoon,
      eveningSections: event.evening,
      maxSections: total,
    ));
  }

  Future<void> _onUpdateSectionTimes(UpdateSectionTimes event, Emitter<SettingsState> emit) async {
    await _settingsManager.setSectionTimesList(event.sectionTimes);
    emit(state.copyWith(sectionTimes: event.sectionTimes));
  }

  Future<void> _onUpdateStartSemesterDate(UpdateStartSemesterDate event, Emitter<SettingsState> emit) async {
    if (event.date != null) {
      await _settingsManager.setStartSemester(event.date!.millisecondsSinceEpoch.toString());
    }
    emit(state.copyWith(startSemesterDate: event.date));
  }

  Future<void> _onImportScheduleConfig(ImportScheduleConfig event, Emitter<SettingsState> emit) async {
    await _settingsManager.importScheduleConfig(event.config);
    add(LoadSettings());
  }
}
