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
  final List<Course> courses; // 当前周的课程
  final AppSettings settings;
  final bool isHoliday;

  const WeeklyCourseLoaded({
    required this.currentWeek,
    required this.weekStart,
    required this.courses,
    required this.settings,
    required this.isHoliday,
  });

  @override
  List<Object?> get props => [currentWeek, weekStart, courses, settings, isHoliday];

  WeeklyCourseLoaded copyWith({
    int? currentWeek,
    DateTime? weekStart,
    List<Course>? courses,
    AppSettings? settings,
    bool? isHoliday,
  }) {
    return WeeklyCourseLoaded(
      currentWeek: currentWeek ?? this.currentWeek,
      weekStart: weekStart ?? this.weekStart,
      courses: courses ?? this.courses,
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
