import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/weekly_course/weekly_course_event.dart';
import 'package:schedu/bloc/weekly_course/weekly_course_state.dart';
import 'package:schedu/repository/app_settings_store.dart';
import 'package:schedu/repository/course_repository.dart';
import 'package:schedu/view/weekly/weekly_schedule_utils.dart';
import 'package:schedu/model/course.dart';

/// 周课程业务逻辑处理
class WeeklyCourseBloc extends Bloc<WeeklyCourseEvent, WeeklyCourseState> {
  final CourseRepository _courseRepository;
  final AppSettingsStore _settingsDataStore;

  late final StreamSubscription _courseSub;
  late final StreamSubscription _settingsSub;

  WeeklyCourseBloc(this._courseRepository, this._settingsDataStore)
      : super(WeeklyCourseInitial()) {
    on<RefreshWeeklyCourses>(_onRefreshWeeklyCourses);
    on<GoToPreviousWeek>(_onGoToPreviousWeek);
    on<GoToNextWeek>(_onGoToNextWeek);
    on<JumpToWeek>(_onJumpToWeek);

    _courseSub = _courseRepository.stream.listen((_) {
      add(const RefreshWeeklyCourses());
    });
    _settingsSub = _settingsDataStore.stream.listen((_) {
      add(const RefreshWeeklyCourses(resetToCurrentWeek: true));
    });
  }

  @override
  Future<void> close() {
    _courseSub.cancel();
    _settingsSub.cancel();
    return super.close();
  }

  /// 处理刷新周课程事件
  Future<void> _onRefreshWeeklyCourses(
      RefreshWeeklyCourses event,
      Emitter<WeeklyCourseState> emit,
  ) async {
    final int currentWeek;
    if (event.resetToCurrentWeek || state is! WeeklyCourseLoaded) {
      final startSemester = _settingsDataStore.data.startSemester == -1
          ? null
          : DateTime.fromMillisecondsSinceEpoch(_settingsDataStore.data.startSemester);
      currentWeek = WeeklyScheduleUtils.calculateCurrentWeek(startSemester);
    } else {
      final currentState = state as WeeklyCourseLoaded;
      currentWeek = currentState.currentWeek;
    }
    await _loadAndEmitCourses(currentWeek, emit);
  }

  /// 处理上一周事件
  Future<void> _onGoToPreviousWeek(
    GoToPreviousWeek event,
    Emitter<WeeklyCourseState> emit,
  ) async {
    if (state is! WeeklyCourseLoaded) return;
    final currentState = state as WeeklyCourseLoaded;
    
    if (currentState.currentWeek <= 1) return;
    
    try {
      await _loadAndEmitCourses(currentState.currentWeek - 1, emit);
    } catch (e) {
      emit(WeeklyCourseError('加载上一周课程失败: ${e.toString()}'));
    }
  }

  /// 处理下一周事件
  Future<void> _onGoToNextWeek(
    GoToNextWeek event,
    Emitter<WeeklyCourseState> emit,
  ) async {
    if (state is! WeeklyCourseLoaded) return;
    final currentState = state as WeeklyCourseLoaded;
    
    try {
      await _loadAndEmitCourses(currentState.currentWeek + 1, emit);
    } catch (e) {
      emit(WeeklyCourseError('加载下一周课程失败: ${e.toString()}'));
    }
  }

  /// 处理跳转到指定周事件
  Future<void> _onJumpToWeek(
    JumpToWeek event,
    Emitter<WeeklyCourseState> emit,
  ) async {
    try {
      await _loadAndEmitCourses(event.weekNumber, emit);
    } catch (e) {
      emit(WeeklyCourseError('跳转到第${event.weekNumber}周失败: ${e.toString()}'));
    }
  }

  /// 加载并发送课程数据
  Future<void> _loadAndEmitCourses(int weekNumber, Emitter<WeeklyCourseState> emit) async {
    final startSemester = DateTime.fromMillisecondsSinceEpoch(_settingsDataStore.data.startSemester);
    // 获取周起始日期
    final weekStart = _getWeekStart(weekNumber, startSemester);
    final isHoliday = _isHoliday(weekStart, startSemester, _settingsDataStore.data.totalWeeks);
    final List<Course> weeklyCourses;
    if (isHoliday) {
      weeklyCourses = [];
    } else {
      // 过滤当前周的课程
      weeklyCourses = await _courseRepository.getCoursesForWeek(weekNumber);
    }

    emit(WeeklyCourseLoaded(
      currentWeek: weekNumber,
      weekStart: weekStart,
      courses: weeklyCourses,
      settings: _settingsDataStore.data,
      isHoliday: isHoliday,
    ));
  }

  /// 获取指定周号对应的周起始日期
  DateTime _getWeekStart(int weekNumber, DateTime? startSemester) {
    if (startSemester == null) {
      return WeeklyScheduleUtils.getWeekStart(DateTime.now());
    }
    final start = WeeklyScheduleUtils.getWeekStart(startSemester);
    return start.add(Duration(days: (weekNumber - 1) * 7));
  }

  bool _isHoliday(DateTime weekStart, DateTime startSemester, int totalWeeks) {
    if (totalWeeks < 1) return false;
    final startDate = DateTime(startSemester.year, startSemester.month, startSemester.day);
    final endDate = startDate.add(Duration(days: totalWeeks * 7 - 1));
    return weekStart.isBefore(startDate) || weekStart.isAfter(endDate);
  }
}
