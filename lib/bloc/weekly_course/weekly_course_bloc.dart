import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/weekly_course/weekly_course_event.dart';
import 'package:schedu/bloc/weekly_course/weekly_course_state.dart';
import 'package:schedu/model/app_settings.dart';
import 'package:schedu/repository/app_settings_store.dart';
import 'package:schedu/repository/course_repository.dart';
import 'package:schedu/view/weekly/weekly_schedule_utils.dart';
import 'package:schedu/model/course.dart';

/// 周课程业务逻辑处理
class WeeklyCourseBloc extends Bloc<WeeklyCourseEvent, WeeklyCourseState> {
  final CourseRepository _courseRepository;
  final AppSettingsStore _settingsDataStore;
  /// 周数据请求令牌，用于避免过时请求覆盖新数据
  final Map<int, int> _weekRequestTokens = <int, int>{};
  /// 请求令牌自增种子
  int _requestTokenSeed = 0;
  /// 每次设置变更时递增，用于使过时请求失效
  int _settingsEpoch = 0;

  late final StreamSubscription _courseSub;
  late final StreamSubscription _settingsSub;

  WeeklyCourseBloc(this._courseRepository, this._settingsDataStore)
      : super(WeeklyCourseInitial()) {
    on<RefreshWeeklyCourses>(_onRefreshWeeklyCourses);
    on<LoadWeeklyCourses>(_onLoadWeeklyCourses);
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
    _settingsEpoch++;
    _weekRequestTokens.clear();

    /// 刷新时重新计算当前周，除非事件指定保持当前周且当前状态已加载课程数据
    final settings = _settingsDataStore.data;
    final int effectiveTotalWeeks = _effectiveTotalWeeks(settings);
    final int currentWeek;
    if (event.resetToCurrentWeek || state is! WeeklyCourseLoaded) {
      currentWeek = _clampWeek(
        WeeklyScheduleUtils.calculateCurrentWeek(_startSemesterOrNull(settings)),
        effectiveTotalWeeks,
      );
    } else {
      final currentState = state as WeeklyCourseLoaded;
      currentWeek = _clampWeek(currentState.currentWeek, effectiveTotalWeeks);
    }

    final weekData = _createPlaceholderWeekData(currentWeek, settings);
    emit(WeeklyCourseLoaded(
      currentWeek: currentWeek,
      weekStart: weekData.weekStart,
      coursesByDay: weekData.coursesByDay,
      settings: settings,
      isHoliday: weekData.isHoliday,
      weekCache: <int, WeekData>{currentWeek: weekData},
      loadingWeeks: const <int>{},
      settingsEpoch: _settingsEpoch,
    ));

    await _ensureWeekCached(currentWeek, emit);
    _triggerNeighborPrefetch(currentWeek);
  }

  /// 处理加载指定周课程事件
  Future<void> _onLoadWeeklyCourses(
    LoadWeeklyCourses event,
    Emitter<WeeklyCourseState> emit,
  ) async {
    if (state is! WeeklyCourseLoaded) {
      return;
    }
    final currentState = state as WeeklyCourseLoaded;
    final targetWeek = _clampWeek(
      event.weekNumber,
      _effectiveTotalWeeks(currentState.settings),
    );
    await _ensureWeekCached(targetWeek, emit);
  }

  /// 处理上一周事件
  Future<void> _onGoToPreviousWeek(
    GoToPreviousWeek event,
    Emitter<WeeklyCourseState> emit,
  ) async {
    try {
      if (state is! WeeklyCourseLoaded) return;
      final currentState = state as WeeklyCourseLoaded;
      if (currentState.currentWeek <= 1) {
        return;
      }
      final targetWeek = currentState.currentWeek - 1;
      await _switchToWeek(targetWeek, emit);
    } catch (e) {
      emit(WeeklyCourseError('加载上一周课程失败: ${e.toString()}'));
    }
  }

  /// 处理下一周事件
  Future<void> _onGoToNextWeek(
    GoToNextWeek event,
    Emitter<WeeklyCourseState> emit,
  ) async {
    try {
      if (state is! WeeklyCourseLoaded) return;
      final currentState = state as WeeklyCourseLoaded;
      final effectiveTotalWeeks = _effectiveTotalWeeks(currentState.settings);
      if (currentState.currentWeek >= effectiveTotalWeeks) {
        return;
      }
      final targetWeek = currentState.currentWeek + 1;
      await _switchToWeek(targetWeek, emit);
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
      if (state is! WeeklyCourseLoaded) {
        await _onRefreshWeeklyCourses(
          const RefreshWeeklyCourses(resetToCurrentWeek: true),
          emit,
        );
      }
      if (state is! WeeklyCourseLoaded) return;
      final currentState = state as WeeklyCourseLoaded;
      final effectiveTotalWeeks = _effectiveTotalWeeks(currentState.settings);
      final targetWeek = _clampWeek(event.weekNumber, effectiveTotalWeeks);
      await _switchToWeek(targetWeek, emit);
    } catch (e) {
      emit(WeeklyCourseError('跳转到第${event.weekNumber}周失败: ${e.toString()}'));
    }
  }

  /// 切换到指定周，优先使用缓存数据，必要时加载数据
  Future<void> _switchToWeek(int weekNumber, Emitter<WeeklyCourseState> emit) async {
    if (state is! WeeklyCourseLoaded) {
      return;
    }
    final currentState = state as WeeklyCourseLoaded;
    final settings = currentState.settings;
    final targetWeek = _clampWeek(weekNumber, _effectiveTotalWeeks(settings));
    final cached = currentState.weekCache[targetWeek];

    if (cached != null && cached.isReady) {
      final alignedCache = Map<int, WeekData>.from(currentState.weekCache)
        ..[targetWeek] = cached.copyWith(
          weekNumber: targetWeek,
          weekStart: cached.weekStart,
          coursesByDay: cached.coursesByDay,
          isHoliday: cached.isHoliday,
          isReady: true,
        );
      emit(currentState.copyWith(
        currentWeek: targetWeek,
        weekStart: cached.weekStart,
        coursesByDay: cached.coursesByDay,
        isHoliday: cached.isHoliday,
        weekCache: _pruneWeekCache(alignedCache, targetWeek),
      ));
      _triggerNeighborPrefetch(targetWeek);
      return;
    }

    final placeholder = _createPlaceholderWeekData(targetWeek, settings);
    final cache = Map<int, WeekData>.from(currentState.weekCache)
      ..[targetWeek] = placeholder;
    emit(currentState.copyWith(
      currentWeek: targetWeek,
      weekStart: placeholder.weekStart,
      coursesByDay: placeholder.coursesByDay,
      isHoliday: placeholder.isHoliday,
      weekCache: _pruneWeekCache(cache, targetWeek),
    ));

    await _ensureWeekCached(targetWeek, emit);
    _triggerNeighborPrefetch(targetWeek);
  }

  /// 确保指定周的数据已缓存，必要时加载数据并更新状态
  Future<void> _ensureWeekCached(int weekNumber, Emitter<WeeklyCourseState> emit) async {
    if (state is! WeeklyCourseLoaded) {
      return;
    }
    var currentState = state as WeeklyCourseLoaded;
    final settings = currentState.settings;
    final targetWeek = _clampWeek(weekNumber, _effectiveTotalWeeks(settings));
    final cached = currentState.weekCache[targetWeek];
    if (cached != null && cached.isReady) {
      return;
    }
    if (currentState.loadingWeeks.contains(targetWeek)) {
      return;
    }

    final loadingWeeks = Set<int>.from(currentState.loadingWeeks)..add(targetWeek);
    emit(currentState.copyWith(loadingWeeks: loadingWeeks));
    if (state is! WeeklyCourseLoaded) {
      return;
    }
    currentState = state as WeeklyCourseLoaded;
    final startEpoch = currentState.settingsEpoch;
    final token = ++_requestTokenSeed;
    _weekRequestTokens[targetWeek] = token;

    try {
      final weekData = await _loadWeekData(targetWeek, currentState.settings);
      if (state is! WeeklyCourseLoaded) {
        return;
      }
      final latestState = state as WeeklyCourseLoaded;
      final latestToken = _weekRequestTokens[targetWeek];
      final stale =
          latestState.settingsEpoch != startEpoch || latestToken != token;
      if (stale) {
        return;
      }

      final cache = Map<int, WeekData>.from(latestState.weekCache)
        ..[targetWeek] = weekData;
      final prunedCache = _pruneWeekCache(cache, latestState.currentWeek);
      final updatedState = latestState.copyWith(weekCache: prunedCache);
      if (latestState.currentWeek == targetWeek) {
        emit(updatedState.copyWith(
          weekStart: weekData.weekStart,
          coursesByDay: weekData.coursesByDay,
          isHoliday: weekData.isHoliday,
        ));
      } else {
        emit(updatedState);
      }
    } finally {
      if (_weekRequestTokens[targetWeek] == token) {
        _weekRequestTokens.remove(targetWeek);
      }

      if (state is WeeklyCourseLoaded) {
        final latestState = state as WeeklyCourseLoaded;
        if (latestState.settingsEpoch == startEpoch &&
            latestState.loadingWeeks.contains(targetWeek)) {
          final newLoading = Set<int>.from(latestState.loadingWeeks)
            ..remove(targetWeek);
          emit(latestState.copyWith(loadingWeeks: newLoading));
        }
      }
    }
  }

  /// 触发相邻周的数据预加载，避免过度预加载
  void _triggerNeighborPrefetch(int currentWeek) {
    if (state is! WeeklyCourseLoaded) {
      return;
    }
    final currentState = state as WeeklyCourseLoaded;
    final maxWeek = _effectiveTotalWeeks(currentState.settings);
    final prevWeek = _clampWeek(currentWeek - 1, maxWeek);
    final nextWeek = _clampWeek(currentWeek + 1, maxWeek);

    if (prevWeek != currentWeek &&
        !_shouldSkipPrefetch(currentState, prevWeek)) {
      add(LoadWeeklyCourses(prevWeek));
    }
    if (nextWeek != currentWeek &&
        !_shouldSkipPrefetch(currentState, nextWeek)) {
      add(LoadWeeklyCourses(nextWeek));
    }
  }

  /// 判断是否应该跳过预加载，避免重复加载或过度加载
  bool _shouldSkipPrefetch(WeeklyCourseLoaded state, int weekNumber) {
    final cached = state.weekCache[weekNumber];
    if (cached != null && cached.isReady) {
      return true;
    }
    return state.loadingWeeks.contains(weekNumber);
  }

  /// 加载指定周的数据
  Future<WeekData> _loadWeekData(int weekNumber, AppSettings settings) async {
    final weekStart = _getWeekStart(weekNumber, _startSemesterOrNull(settings));
    final isHoliday = _isHoliday(
      weekStart,
      _startSemesterOrNull(settings),
      _effectiveTotalWeeks(settings),
    );
    if (isHoliday) {
      return WeekData(
        weekNumber: weekNumber,
        weekStart: weekStart,
        coursesByDay: _emptyWeekCourses(),
        isHoliday: true,
        isReady: true,
      );
    }

    final List<Course> courses;
    if (settings.showNonCurrentWeekCourses) {
      courses = await _courseRepository.getAllCourses();
    } else {
      courses = await _courseRepository.getCoursesForWeek(weekNumber);
    }
    final coursesByDay = _groupCoursesByDay(courses, weekNumber, settings);

    return WeekData(
      weekNumber: weekNumber,
      weekStart: weekStart,
      coursesByDay: coursesByDay,
      isHoliday: false,
      isReady: true,
    );
  }

  /// 创建指定周的占位数据，用于在加载过程中显示基本信息
  WeekData _createPlaceholderWeekData(int weekNumber, AppSettings settings) {
    final weekStart = _getWeekStart(weekNumber, _startSemesterOrNull(settings));
    final isHoliday = _isHoliday(
      weekStart,
      _startSemesterOrNull(settings),
      _effectiveTotalWeeks(settings),
    );
    return WeekData(
      weekNumber: weekNumber,
      weekStart: weekStart,
      coursesByDay: _emptyWeekCourses(),
      isHoliday: isHoliday,
      isReady: false,
    );
  }

  /// 修剪周数据缓存，仅保留当前周及其相邻两周的数据
  Map<int, WeekData> _pruneWeekCache(Map<int, WeekData> cache, int currentWeek) {
    final minWeek = currentWeek - 2;
    final maxWeek = currentWeek + 2;
    final result = <int, WeekData>{};
    for (final entry in cache.entries) {
      if (entry.key >= minWeek && entry.key <= maxWeek) {
        result[entry.key] = entry.value;
      }
    }
    if (!result.containsKey(currentWeek)) {
      result[currentWeek] = _createPlaceholderWeekData(
        currentWeek,
        _settingsDataStore.data,
      );
    }
    return result;
  }

  /// 计算有效的总周数，确保至少为1周
  int _effectiveTotalWeeks(AppSettings settings) {
    if (settings.totalWeeks <= 0) {
      return 1;
    }
    return settings.totalWeeks;
  }

  /// 将周号限制在有效范围内，避免无效周号导致错误
  int _clampWeek(int weekNumber, int effectiveTotalWeeks) {
    if (weekNumber < 1) {
      return 1;
    }
    if (weekNumber > effectiveTotalWeeks) {
      return effectiveTotalWeeks;
    }
    return weekNumber;
  }

  /// 获取开学日期，如果未设置或无效则返回null
  DateTime? _startSemesterOrNull(AppSettings settings) {
    if (settings.startSemester <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(settings.startSemester);
  }

  /// 将课程列表按周几分组，并根据设置过滤非当前周课程
  List<List<Course>> _groupCoursesByDay(
    List<Course> courses,
    int currentWeek,
    AppSettings settings,
  ) {
    final List<List<Course>> result = List.generate(7, (_) => []);
    for (final course in courses) {
      if (course.day < 1 || course.day > 7) {
        continue;
      }
      final index = course.day - 1;
      final isCurrentWeekCourse = course.weeks.contains(currentWeek);
      if (isCurrentWeekCourse || settings.showNonCurrentWeekCourses) {
        result[index].add(course);
      }
    }
    if (settings.showNonCurrentWeekCourses) {
      for (final dayCourses in result) {
        dayCourses.sort((a, b) {
          final aCurrent = a.weeks.contains(currentWeek);
          final bCurrent = b.weeks.contains(currentWeek);
          if (aCurrent == bCurrent) {
            return 0;
          }
          return aCurrent ? -1 : 1;
        });
      }
    }
    return result;
  }

  List<List<Course>> _emptyWeekCourses() {
    return List.generate(7, (_) => []);
  }

  /// 获取指定周号对应的周起始日期
  DateTime _getWeekStart(int weekNumber, DateTime? startSemester) {
    if (startSemester == null) {
      return WeeklyScheduleUtils.getWeekStart(DateTime.now());
    }
    final start = WeeklyScheduleUtils.getWeekStart(startSemester);
    return start.add(Duration(days: (weekNumber - 1) * 7));
  }

  bool _isHoliday(DateTime weekStart, DateTime? startSemester, int totalWeeks) {
    if (startSemester == null) {
      return false;
    }
    if (totalWeeks < 1) {
      return false;
    }
    final startDate = DateTime(startSemester.year, startSemester.month, startSemester.day);
    final endDate = startDate.add(Duration(days: totalWeeks * 7 - 1));
    return weekStart.isBefore(startDate) || weekStart.isAfter(endDate);
  }
}
