import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/daily_course/daily_course_event.dart';
import 'package:schedu/bloc/daily_course/daily_course_state.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/model/section_time.dart';
import 'package:schedu/repository/course_repository.dart';
import 'package:schedu/repository/app_settings_store.dart';

/// 今日课程业务逻辑处理
class DailyCourseBloc extends Bloc<DailyCourseEvent, DailyCourseState> {
  final CourseRepository _courseRepository;
  final AppSettingsStore _settingsStore;

  late final StreamSubscription _courseSub;
  late final StreamSubscription _settingsSub;

  DailyCourseBloc(this._courseRepository, this._settingsStore)
      : super(DailyCourseInitial()) {
    on<RefreshDailyCourses>(_refreshDailyCourses);

    _courseSub = _courseRepository.stream.listen((_) {
      add(RefreshDailyCourses());
    });
    _settingsSub = _settingsStore.stream.listen((_) {
      add(RefreshDailyCourses());
    });
  }

  @override
  Future<void> close() {
    _courseSub.cancel();
    _settingsSub.cancel();
    return super.close();
  }

  /// 处理刷新今日课程事件
  Future<void> _refreshDailyCourses(
    RefreshDailyCourses event,
    Emitter<DailyCourseState> emit,
  ) async {
    emit(DailyCourseLoading());
    final today = _startOfDay(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));

    final startSemester = _settingsStore.data.startSemester == -1
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(_settingsStore.data.startSemester);
    final sectionTimes = _settingsStore.data.sectionTimes;
    final currentWeekNumber = _calculateWeekNumber(today, startSemester);

    final todayCourses = (await _courseRepository.getCoursesForDay(currentWeekNumber, today.weekday))
        .map((course) => CourseWithStatus(
          course: course,
          status: _getCourseStatus(course, today, sectionTimes, startSemester),
        )).toList();
    todayCourses.sort((a, b) => a.course.sections.first.compareTo(b.course.sections.first));
    final tomorrowCourses = (await _courseRepository.getCoursesForDay(currentWeekNumber + (tomorrow.weekday < today.weekday ? 1 : 0), tomorrow.weekday))
        .map((course) => CourseWithStatus(
          course: course,
          status: _getCourseStatus(course, tomorrow, sectionTimes, startSemester),
        )).toList();
    tomorrowCourses.sort((a, b) => a.course.sections.first.compareTo(b.course.sections.first));

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

  /// 计算周数
  int _calculateWeekNumber(DateTime date, DateTime startSemester) {
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
