import 'package:equatable/equatable.dart';
import 'package:schedu/model/app_settings.dart';
import 'package:schedu/model/course.dart';

/// 周课程状态的基类
abstract class WeeklyCourseState extends Equatable {
  const WeeklyCourseState();
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

  const WeeklyCourseLoaded({
    required this.currentWeek,
    required this.weekStart,
    required this.coursesByDay,
    required this.settings,
    required this.isHoliday,
  });

  @override
  List<Object?> get props => [currentWeek, weekStart, coursesByDay, settings, isHoliday];

  WeeklyCourseLoaded copyWith({
    int? currentWeek,
    DateTime? weekStart,
    List<List<Course>>? coursesByDay,
    AppSettings? settings,
    bool? isHoliday,
  }) {
    return WeeklyCourseLoaded(
      currentWeek: currentWeek ?? this.currentWeek,
      weekStart: weekStart ?? this.weekStart,
      coursesByDay: coursesByDay ?? this.coursesByDay,
      settings: settings ?? this.settings,
      isHoliday: isHoliday ?? this.isHoliday,
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
