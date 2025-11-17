import 'package:equatable/equatable.dart';
import 'package:schedu/model/course.dart';

/// 课程状态的基类
abstract class CourseState extends Equatable {
  const CourseState();
}

/// 初始状态
class CourseInitial extends CourseState {
  @override
  List<Object?> get props => [];
}

/// 加载中
class CourseLoading extends CourseState {
  @override
  List<Object?> get props => [];
}

/// 加载成功
class CourseLoaded extends CourseState {
  final List<Course> courses;

  const CourseLoaded(this.courses);

  @override
  List<Object?> get props => [courses];
}

/// 复合状态 - 包含所有类型的课程数据
class CourseDataLoaded extends CourseState {
  final List<Course> allCourses;
  final Map<String, List<Course>> dailyCourses; // key: "yyyy-MM-dd"
  final Map<String, List<Course>> weeklyCourses; // key: "yyyy-MM-dd" (week start date)

  const CourseDataLoaded({
    required this.allCourses,
    this.dailyCourses = const {},
    this.weeklyCourses = const {},
  });

  /// 获取指定日期的课程
  List<Course> getCoursesForDate(DateTime date) {
    final key = _formatDateKey(date);
    return dailyCourses[key] ?? [];
  }

  /// 获取指定周的课程
  List<Course> getCoursesForWeek(DateTime weekStart) {
    final key = _formatDateKey(weekStart);
    return weeklyCourses[key] ?? [];
  }

  /// 检查是否有指定日期的数据
  bool hasDailyData(DateTime date) {
    final key = _formatDateKey(date);
    return dailyCourses.containsKey(key);
  }

  /// 检查是否有指定周的数据
  bool hasWeeklyData(DateTime weekStart) {
    final key = _formatDateKey(weekStart);
    return weeklyCourses.containsKey(key);
  }

  /// 添加或更新日期课程数据
  CourseDataLoaded withDailyCourses(DateTime date, List<Course> courses) {
    final key = _formatDateKey(date);
    final newDailyCourses = Map<String, List<Course>>.from(dailyCourses);
    newDailyCourses[key] = courses;
    
    return CourseDataLoaded(
      allCourses: allCourses,
      dailyCourses: newDailyCourses,
      weeklyCourses: weeklyCourses,
    );
  }

  /// 添加或更新周课程数据
  CourseDataLoaded withWeeklyCourses(DateTime weekStart, List<Course> courses) {
    final key = _formatDateKey(weekStart);
    final newWeeklyCourses = Map<String, List<Course>>.from(weeklyCourses);
    newWeeklyCourses[key] = courses;
    
    return CourseDataLoaded(
      allCourses: allCourses,
      dailyCourses: dailyCourses,
      weeklyCourses: newWeeklyCourses,
    );
  }

  /// 更新所有课程数据
  CourseDataLoaded withAllCourses(List<Course> courses) {
    return CourseDataLoaded(
      allCourses: courses,
      dailyCourses: dailyCourses,
      weeklyCourses: weeklyCourses,
    );
  }

  /// 格式化日期为键值
  static String formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  static String _formatDateKey(DateTime date) {
    return formatDateKey(date);
  }

  @override
  List<Object?> get props => [allCourses, dailyCourses, weeklyCourses];
}

/// 特定日期的课程加载成功
class CoursesForDayLoaded extends CourseState {
  final List<Course> courses;
  final DateTime date;

  const CoursesForDayLoaded(this.courses, this.date);

  @override
  List<Object?> get props => [courses, date];
}

/// 特定周的课程加载成功
class CoursesForWeekLoaded extends CourseState {
  final List<Course> courses;
  final DateTime weekStart;

  const CoursesForWeekLoaded(this.courses, this.weekStart);

  @override
  List<Object?> get props => [courses, weekStart];
}

/// 操作成功
class CourseOperationSuccess extends CourseState {
  final String message;
  final List<Course> courses;

  const CourseOperationSuccess(this.message, this.courses);

  @override
  List<Object?> get props => [message, courses];
}

/// 错误状态
class CourseError extends CourseState {
  final String message;

  const CourseError(this.message);

  @override
  List<Object?> get props => [message];
}
