import 'package:equatable/equatable.dart';

/// 今日课程相关事件的基类
abstract class DailyCourseEvent extends Equatable {
  const DailyCourseEvent();
}

/// 刷新今日和明日课程
class RefreshDailyCourses extends DailyCourseEvent {
  const RefreshDailyCourses();

  @override
  List<Object?> get props => [];
}
