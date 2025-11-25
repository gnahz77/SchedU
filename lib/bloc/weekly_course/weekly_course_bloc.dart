import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/weekly_course/weekly_course_event.dart';
import 'package:schedu/bloc/weekly_course/weekly_course_state.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/repository/course_repository.dart';
import 'package:schedu/repository/settings_manager.dart';
import 'package:schedu/view/weekly/weekly_schedule_utils.dart';

/// 周课程业务逻辑处理
class WeeklyCourseBloc extends Bloc<WeeklyCourseEvent, WeeklyCourseState> {
  final CourseRepository _courseRepository;
  final SettingsManager _settingsManager;

  WeeklyCourseBloc(this._courseRepository, this._settingsManager)
      : super(WeeklyCourseInitial()) {
    on<LoadWeeklyCourses>(_onLoadWeeklyCourses);
    on<GoToPreviousWeek>(_onGoToPreviousWeek);
    on<GoToNextWeek>(_onGoToNextWeek);
    on<JumpToWeek>(_onJumpToWeek);
    on<RefreshWeeklyCourses>(_onRefreshWeeklyCourses);
  }

  /// 处理加载周课程事件
  Future<void> _onLoadWeeklyCourses(
    LoadWeeklyCourses event,
    Emitter<WeeklyCourseState> emit,
  ) async {
    try {
      emit(WeeklyCourseLoading());
      await _loadAndEmitCourses(event.weekNumber, emit);
    } catch (e) {
      emit(WeeklyCourseError('加载周课程失败: ${e.toString()}'));
    }
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

  /// 处理刷新周课程事件
  Future<void> _onRefreshWeeklyCourses(
    RefreshWeeklyCourses event,
    Emitter<WeeklyCourseState> emit,
  ) async {
    if (event.resetToCurrentWeek || state is! WeeklyCourseLoaded) {
      // 加载当前周
      final startSemester = await _settingsManager.getStartSemesterDate();
      final currentWeek = WeeklyScheduleUtils.calculateCurrentWeek(startSemester);
      add(LoadWeeklyCourses(currentWeek));
      return;
    }
    
    final currentState = state as WeeklyCourseLoaded;
    try {
      await _loadAndEmitCourses(currentState.currentWeek, emit);
    } catch (e) {
      emit(WeeklyCourseError('刷新周课程失败: ${e.toString()}'));
    }
  }

  /// 加载并发送课程数据
  Future<void> _loadAndEmitCourses(int weekNumber, Emitter<WeeklyCourseState> emit) async {
    // 获取设置
    final startSemester = await _settingsManager.getStartSemesterDate();
    final totalWeeks = await _settingsManager.getTotalWeeks();
    final showWeekend = await _settingsManager.getShowWeekend();
    
    // 获取周起始日期
    final weekStart = _getWeekStart(weekNumber, startSemester);

    // 获取所有课程
    final allCourses = await _courseRepository.getAllCourses();

    // 过滤当前周的课程
    final weeklyCourses = _filterWeeklyCourses(allCourses, weekNumber);
    
    // 计算真实的当前周
    final actualCurrentWeek = WeeklyScheduleUtils.calculateCurrentWeek(startSemester);

    emit(WeeklyCourseLoaded(
      currentWeek: weekNumber,
      weekStart: weekStart,
      courses: weeklyCourses,
      showWeekend: showWeekend,
    ));
  }

  /// 过滤指定周的课程
  List<Course> _filterWeeklyCourses(List<Course> allCourses, int weekNumber) {
    return allCourses.where((course) {
      return course.weeks.contains(weekNumber);
    }).toList();
  }

  /// 获取指定周号对应的周起始日期
  DateTime _getWeekStart(int weekNumber, DateTime? startSemester) {
    if (startSemester == null) {
      return WeeklyScheduleUtils.getWeekStart(DateTime.now());
    }
    final start = WeeklyScheduleUtils.getWeekStart(startSemester);
    return start.add(Duration(days: (weekNumber - 1) * 7));
  }
}
