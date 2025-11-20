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

/// 操作成功
class CourseOperationSuccess extends CourseLoaded {
  final String message;

  const CourseOperationSuccess(this.message, List<Course> courses) : super(courses);

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
