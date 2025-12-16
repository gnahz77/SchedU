import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/settings/settings_event.dart';
import 'package:schedu/bloc/settings/settings_side_effect.dart';
import 'package:schedu/bloc/settings/settings_state.dart';
import 'package:schedu/repository/app_settings_store.dart';

import '../../repository/course_repository.dart';
import '../../service/course_import_service.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {

  final StreamController<SettingsSideEffectEvent> _sideEffect = StreamController<SettingsSideEffectEvent>.broadcast();
  Stream<SettingsSideEffectEvent> get sideEffect => _sideEffect.stream;

  final CourseRepository _courseRepository;
  final AppSettingsStore _settingsDataStore;
  late final StreamSubscription _sub;

  SettingsBloc(this._courseRepository, this._settingsDataStore) : super(const SettingsState()) {
    on<RefreshSettings>(_onRefreshSettings);
    on<UpdateTotalWeeks>(_onUpdateTotalWeeks);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateShowWeekend>(_onUpdateShowWeekend);
    on<UpdateSectionConfig>(_onUpdateSectionConfig);
    on<UpdateSectionTimes>(_onUpdateSectionTimes);
    on<UpdateStartSemesterDate>(_onUpdateStartSemesterDate);
    on<ImportCourseTimes>(_onImportCoursesTimes);
    on<ExportCourseTimes>(_onExportCourseTimes);

    _sub = _settingsDataStore.stream.listen((data) {
      add(RefreshSettings());
    });
  }

  @override
  Future<void> close() {
    _sideEffect.close();
    _sub.cancel();
    return super.close();
  }

  Future<void> _onRefreshSettings(RefreshSettings event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(appSettings: _settingsDataStore.data));
  }

  Future<void> _onUpdateTotalWeeks(UpdateTotalWeeks event, Emitter<SettingsState> emit) async {
    await _settingsDataStore.setTotalWeeks(event.totalWeeks);
  }

  Future<void> _onUpdateThemeMode(UpdateThemeMode event, Emitter<SettingsState> emit) async {
    await _settingsDataStore.setThemeMode(event.themeMode);
  }

  Future<void> _onUpdateShowWeekend(UpdateShowWeekend event, Emitter<SettingsState> emit) async {
    await _settingsDataStore.setShowWeekend(event.showWeekend);
  }

  Future<void> _onUpdateSectionConfig(UpdateSectionConfig event, Emitter<SettingsState> emit) async {
    await _settingsDataStore.setMorningSections(event.morning);
    await _settingsDataStore.setAfternoonSections(event.afternoon);
    await _settingsDataStore.setEveningSections(event.evening);
  }

  Future<void> _onUpdateSectionTimes(UpdateSectionTimes event, Emitter<SettingsState> emit) async {
    await _settingsDataStore.setSectionTimesList(event.sectionTimes);
  }

  Future<void> _onUpdateStartSemesterDate(UpdateStartSemesterDate event, Emitter<SettingsState> emit) async {
    if (event.date != null) {
      await _settingsDataStore.setStartSemester(event.date!.millisecondsSinceEpoch);
    }
  }

  /// 处理从JSON导入课程事件
  Future<void> _onImportCoursesTimes(
      ImportCourseTimes event,
      Emitter<SettingsState> emit,
  ) async {
    try {
      emit(state.copyWith(loading: true));
      // 导入时间表配置
      if (event.importData.scheduleConfig != null) {
        await AppSettingsStore.instance.importScheduleConfig(event.importData.scheduleConfig!);
      }
      await _courseRepository.importCoursesFromJson(event.importData.courses);
      _sideEffect.add(const SettingsSuccessMessage('课程导入成功'));
    } catch (e) {
      _sideEffect.add(SettingsErrorMessage('导入课程失败: ${e.toString()}'));
    } finally {
      emit(state.copyWith(loading: false));
    }
  }

  /// 处理导出课程到文件事件
  Future<void> _onExportCourseTimes(
      ExportCourseTimes event,
      Emitter<SettingsState> emit,
      ) async {
    try {
      emit(state.copyWith(loading: true));

      // 获取所有课程
      final courses = await _courseRepository.getAllCourses();

      if (courses.isEmpty) {
        _sideEffect.add(const SettingsErrorMessage('没有可导出的课程数据'));
        return;
      }

      // 获取时间表配置
      final scheduleConfig = await AppSettingsStore.instance.exportScheduleConfig();

      // 生成JSON字符串
      final jsonString = CourseImportService.exportToJson(
        courses: courses,
        scheduleConfig: scheduleConfig,
      );

      // 处理导出文件保存
      try {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: '保存课程数据',
          fileName: 'schedu_export_${DateTime.now().millisecondsSinceEpoch}.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: utf8.encode(jsonString),
        );
        if (result != null) {
          _sideEffect.add(SettingsSuccessMessage('导出成功：${courses.length}门课程'));
        }
      } catch (e) {
        _sideEffect.add(SettingsErrorMessage('保存文件失败: $e'));
      }
    } catch (e) {
      _sideEffect.add(SettingsErrorMessage('导出失败: ${e.toString()}'));
    } finally {
      emit(state.copyWith(loading: false));
    }
  }

}
