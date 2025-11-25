import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/daily_course/daily_course_event.dart';
import 'package:schedu/bloc/daily_course/daily_course_state.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/model/section_time.dart';
import 'package:schedu/repository/course_repository.dart';
import 'package:schedu/repository/settings_manager.dart';

/// 今日课程业务逻辑处理
class DailyCourseBloc extends Bloc<DailyCourseEvent, DailyCourseState> {
  final CourseRepository _courseRepository;
  final SettingsManager _settingsManager;

  DailyCourseBloc(this._courseRepository, this._settingsManager)
      : super(DailyCourseInitial()) {
    on<LoadDailyCourses>(_onLoadDailyCourses);
    on<RefreshDailyCourses>(_onRefreshDailyCourses);
  }

  /// 处理加载今日课程事件
  Future<void> _onLoadDailyCourses(
    LoadDailyCourses event,
    Emitter<DailyCourseState> emit,
  ) async {
    try {
      emit(DailyCourseLoading());
      await _loadAndEmitCourses(emit);
    } catch (e) {
      emit(DailyCourseError('加载今日课程失败: ${e.toString()}'));
    }
  }

  /// 处理刷新今日课程事件
  Future<void> _onRefreshDailyCourses(
    RefreshDailyCourses event,
    Emitter<DailyCourseState> emit,
  ) async {
    try {
      await _loadAndEmitCourses(emit);
    } catch (e) {
      emit(DailyCourseError('刷新今日课程失败: ${e.toString()}'));
    }
  }

  /// 加载并发送课程数据
  Future<void> _loadAndEmitCourses(Emitter<DailyCourseState> emit) async {
    final today = _startOfDay(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));

    final startSemester = await _settingsManager.getStartSemesterDate();
    final sectionTimes = await _settingsManager.getSectionTimesList();

    final currentWeekNumber = _calculateWeekNumber(today, startSemester);

    final allCourses = await _courseRepository.getAllCourses();

    final todayCourses = _filterCourses(allCourses, today, startSemester)
        .map((course) => CourseWithStatus(
              course: course,
              status: _getCourseStatus(course, today, sectionTimes, startSemester),
            ))
        .toList();

    final tomorrowCourses = _filterCourses(allCourses, tomorrow, startSemester)
        .map((course) => CourseWithStatus(
              course: course,
              status: _getCourseStatus(course, tomorrow, sectionTimes, startSemester),
            ))
        .toList();

    emit(DailyCourseLoaded(
      today: today,
      tomorrow: tomorrow,
      todayCourses: todayCourses,
      tomorrowCourses: tomorrowCourses,
      currentWeekNumber: currentWeekNumber,
      sectionTimes: sectionTimes,
    ));
  }

  CourseStatus _getCourseStatus(
    Course course,
    DateTime checkDate,
    List<SectionTime> sectionTimes,
    DateTime? startSemesterDate,
  ) {
    if (course.sections.isEmpty || sectionTimes.isEmpty) {
      return CourseStatus.notStarted;
    }
    final targetWeekday = checkDate.weekday;
    if (course.day != targetWeekday) {
      return CourseStatus.notStarted;
    }
    if (startSemesterDate != null) {
      final weekNumber = ((checkDate
          .difference(startSemesterDate)
          .inDays) ~/ 7) + 1;
      if (!course.weeks.contains(weekNumber)) {
        return CourseStatus.notStarted;
      }
    }
    final startSection = course.sections.first;
    final endSection = course.sections.last;
    final startTime = sectionTimes
        .where((st) => st.section == startSection)
        .firstOrNull
        ?.startTime;
    final endTime = sectionTimes
        .where((st) => st.section == endSection)
        .firstOrNull
        ?.endTime;
    if (startTime == null || endTime == null) {
      return CourseStatus.notStarted;
    }
    final now = DateTime.now();
    final startTimeParts = startTime.split(':');
    final endTimeParts = endTime.split(':');
    final courseStart = DateTime(
      checkDate.year,
      checkDate.month,
      checkDate.day,
      int.parse(startTimeParts[0]),
      int.parse(startTimeParts[1]),
    );
    final courseEnd = DateTime(
      checkDate.year,
      checkDate.month,
      checkDate.day,
      int.parse(endTimeParts[0]),
      int.parse(endTimeParts[1]),
    );
    if (checkDate.year == now.year &&
        checkDate.month == now.month &&
        checkDate.day == now.day) {
      if (now.isBefore(courseStart)) {
        return CourseStatus.notStarted;
      } else if (now.isAfter(courseEnd)) {
        return CourseStatus.finished;
      } else {
        return CourseStatus.ongoing;
      }
    } else if (checkDate.isBefore(DateTime(now.year, now.month, now.day))) {
      return CourseStatus.finished;
    } else {
      return CourseStatus.notStarted;
    }
  }

  /// 过滤指定日期的课程
  List<Course> _filterCourses(
      List<Course> allCourses, DateTime date, DateTime? startSemester) {
    final weekNumber = _calculateWeekNumber(date, startSemester);
    final weekday = date.weekday;
    return allCourses.where((course) {
      return course.day == weekday && course.weeks.contains(weekNumber);
    }).toList()..sort((a, b) => a.sections.first.compareTo(b.sections.first));
  }

  /// 计算周数
  int _calculateWeekNumber(DateTime date, DateTime? startSemester) {
    if (startSemester == null) return 1;
    final d = DateTime(date.year, date.month, date.day);
    final s =
        DateTime(startSemester.year, startSemester.month, startSemester.day);

    final diff = d.difference(s).inDays;
    if (diff < 0) return 1;
    return (diff / 7).floor() + 1;
  }

  /// 获取当天的开始时间
  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
