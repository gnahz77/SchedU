import 'package:equatable/equatable.dart';
import 'package:schedu/model/course.dart';

/// 课程相关事件的基类
abstract class CourseEvent extends Equatable {
  const CourseEvent();
}

/// 加载所有课程
class LoadCourses extends CourseEvent {
  const LoadCourses();

  @override
  List<Object?> get props => [];
}

/// 添加课程
class AddCourse extends CourseEvent {
  final Course course;

  const AddCourse(this.course);

  @override
  List<Object?> get props => [course];
}

/// 更新课程
class UpdateCourse extends CourseEvent {
  final Course course;

  const UpdateCourse(this.course);

  @override
  List<Object?> get props => [course];
}

/// 删除课程
class DeleteCourse extends CourseEvent {
  final Course course;

  const DeleteCourse(this.course);

  @override
  List<Object?> get props => [course];
}

/// 从JSON导入课程
class ImportCoursesFromJson extends CourseEvent {
  final List<Map<String, dynamic>> jsonData;

  const ImportCoursesFromJson(this.jsonData);

  @override
  List<Object?> get props => [jsonData];
}

/// 获取指定日期的课程
class LoadCoursesForDay extends CourseEvent {
  final DateTime date;

  const LoadCoursesForDay(this.date);

  @override
  List<Object?> get props => [date];
}

/// 获取指定周的课程
class LoadCoursesForWeek extends CourseEvent {
  final DateTime weekStart;

  const LoadCoursesForWeek(this.weekStart);

  @override
  List<Object?> get props => [weekStart];
}
