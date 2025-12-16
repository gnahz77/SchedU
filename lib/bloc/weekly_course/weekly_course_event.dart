import 'package:equatable/equatable.dart';

/// 周课程相关事件的基类
abstract class WeeklyCourseEvent extends Equatable {
  const WeeklyCourseEvent();
}

/// 刷新
class RefreshWeeklyCourses extends WeeklyCourseEvent {
  final bool resetToCurrentWeek;
  const RefreshWeeklyCourses({this.resetToCurrentWeek = false});

  @override
  List<Object?> get props => [];
}

/// 加载指定周的课程
class LoadWeeklyCourses extends WeeklyCourseEvent {
  final int weekNumber;

  const LoadWeeklyCourses(this.weekNumber);

  @override
  List<Object?> get props => [weekNumber];
}

/// 切换到上一周
class GoToPreviousWeek extends WeeklyCourseEvent {
  const GoToPreviousWeek();

  @override
  List<Object?> get props => [];
}

/// 切换到下一周
class GoToNextWeek extends WeeklyCourseEvent {
  const GoToNextWeek();

  @override
  List<Object?> get props => [];
}

/// 跳转到指定周
class JumpToWeek extends WeeklyCourseEvent {
  final int weekNumber;

  const JumpToWeek(this.weekNumber);

  @override
  List<Object?> get props => [weekNumber];
}
