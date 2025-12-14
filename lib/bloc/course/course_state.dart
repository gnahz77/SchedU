import 'package:equatable/equatable.dart';

/// 课程状态的基类
abstract class CourseState extends Equatable {
  const CourseState();
}

/// 初始状态
class CourseInitial extends CourseState {
  @override
  List<Object?> get props => [];
}

/// 操作成功
class CourseOperationSuccess extends CourseState {
  final String message;

  const CourseOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// 错误状态
class CourseError extends CourseState {
  final String message;

  const CourseError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 正在处理中（用于导入导出）
class CourseProcessing extends CourseState {
  final String message;

  const CourseProcessing(this.message);

  @override
  List<Object?> get props => [message];
}

/// 导出成功
class CourseExportSuccess extends CourseState {
  final String jsonData;
  final int courseCount;

  const CourseExportSuccess({
    required this.jsonData,
    required this.courseCount,
  });

  @override
  List<Object?> get props => [jsonData, courseCount];
}
