import 'package:equatable/equatable.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/model/section_time.dart';

/// 课程状态枚举
enum CourseStatus {
  notStarted, // 未开始
  ongoing,    // 进行中
  finished,   // 已结束
}

/// 今日课程状态的基类
abstract class DailyCourseState extends Equatable {
  const DailyCourseState();
}

/// 初始状态
class DailyCourseInitial extends DailyCourseState {
  @override
  List<Object?> get props => [];
}

/// 加载中
class DailyCourseLoading extends DailyCourseState {
  @override
  List<Object?> get props => [];
}

/// 加载成功
class DailyCourseLoaded extends DailyCourseState {
  final DateTime today;
  final DateTime tomorrow;
  final List<CourseWithStatus> todayCourses;
  final List<CourseWithStatus> tomorrowCourses;
  final int currentWeekNumber;
  final List<SectionTime> sectionTimes;

  const DailyCourseLoaded({
    required this.today,
    required this.tomorrow,
    required this.todayCourses,
    required this.tomorrowCourses,
    required this.currentWeekNumber,
    required this.sectionTimes,
  });

  @override
  List<Object?> get props => [
    today,
    tomorrow,
    todayCourses,
    tomorrowCourses,
    currentWeekNumber,
    sectionTimes,
  ];
}

/// 错误状态
class DailyCourseError extends DailyCourseState {
  final String message;

  const DailyCourseError(this.message);

  @override
  List<Object?> get props => [message];
}

class CourseWithStatus {
  final Course course;
  final CourseStatus status;
  CourseWithStatus({required this.course, required this.status});
}
