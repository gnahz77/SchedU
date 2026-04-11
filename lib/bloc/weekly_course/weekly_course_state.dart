import 'package:equatable/equatable.dart';
import 'package:schedu/model/app_settings.dart';
import 'package:schedu/model/course.dart';

/// 周课程状态的基类
abstract class WeeklyCourseState extends Equatable {
  const WeeklyCourseState();
}

/// 单周缓存数据
class WeekData extends Equatable {
  final int weekNumber;
  final DateTime weekStart;
  final List<List<Course>> coursesByDay;
  final bool isHoliday;
  final bool isReady;

  const WeekData({
    required this.weekNumber,
    required this.weekStart,
    required this.coursesByDay,
    required this.isHoliday,
    required this.isReady,
  });

  @override
  List<Object?> get props => [
    weekNumber,
    weekStart,
    coursesByDay,
    isHoliday,
    isReady,
  ];

  WeekData copyWith({
    int? weekNumber,
    DateTime? weekStart,
    List<List<Course>>? coursesByDay,
    bool? isHoliday,
    bool? isReady,
  }) {
    return WeekData(
      weekNumber: weekNumber ?? this.weekNumber,
      weekStart: weekStart ?? this.weekStart,
      coursesByDay: coursesByDay ?? this.coursesByDay,
      isHoliday: isHoliday ?? this.isHoliday,
      isReady: isReady ?? this.isReady,
    );
  }
}

/// 初始状态
class WeeklyCourseInitial extends WeeklyCourseState {
  @override
  List<Object?> get props => [];
}

/// 加载中
class WeeklyCourseLoading extends WeeklyCourseState {
  @override
  List<Object?> get props => [];
}

/// 加载成功
class WeeklyCourseLoaded extends WeeklyCourseState {
  final int currentWeek;
  final DateTime weekStart;
  // 每周7天的课程列表（day=1 对应索引 0）
  final List<List<Course>> coursesByDay;
  final AppSettings settings;
  final bool isHoliday;
  final Map<int, WeekData> weekCache;
  final Set<int> loadingWeeks;
  final int settingsEpoch;

  const WeeklyCourseLoaded({
    required this.currentWeek,
    required this.weekStart,
    required this.coursesByDay,
    required this.settings,
    required this.isHoliday,
    required this.weekCache,
    required this.loadingWeeks,
    required this.settingsEpoch,
  });

  @override
  List<Object?> get props => [
    currentWeek,
    weekStart,
    coursesByDay,
    settings,
    isHoliday,
    weekCache,
    loadingWeeks,
    settingsEpoch,
  ];

  WeeklyCourseLoaded copyWith({
    int? currentWeek,
    DateTime? weekStart,
    List<List<Course>>? coursesByDay,
    AppSettings? settings,
    bool? isHoliday,
    Map<int, WeekData>? weekCache,
    Set<int>? loadingWeeks,
    int? settingsEpoch,
  }) {
    return WeeklyCourseLoaded(
      currentWeek: currentWeek ?? this.currentWeek,
      weekStart: weekStart ?? this.weekStart,
      coursesByDay: coursesByDay ?? this.coursesByDay,
      settings: settings ?? this.settings,
      isHoliday: isHoliday ?? this.isHoliday,
      weekCache: Map<int, WeekData>.unmodifiable(weekCache ?? this.weekCache),
      loadingWeeks: Set<int>.unmodifiable(loadingWeeks ?? this.loadingWeeks),
      settingsEpoch: settingsEpoch ?? this.settingsEpoch,
    );
  }
}

/// 错误状态
class WeeklyCourseError extends WeeklyCourseState {
  final String message;

  const WeeklyCourseError(this.message);

  @override
  List<Object?> get props => [message];
}
