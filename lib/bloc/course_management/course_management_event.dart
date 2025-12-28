import 'package:equatable/equatable.dart';
import 'package:schedu/model/course.dart';

abstract class CourseManagementEvent extends Equatable {
  const CourseManagementEvent();

  @override
  List<Object?> get props => [];
}

/// Load all courses from database
class LoadAllCourses extends CourseManagementEvent {
  const LoadAllCourses();
}

/// Select a specific course
class SelectCourse extends CourseManagementEvent {
  final Course course;
  const SelectCourse(this.course);

  @override
  List<Object?> get props => [course];
}

/// Unselect a specific course
class UnselectCourse extends CourseManagementEvent {
  final Course course;
  const UnselectCourse(this.course);

  @override
  List<Object?> get props => [course];
}

/// Select all courses
class SelectAllCourses extends CourseManagementEvent {
  const SelectAllCourses();
}

/// Unselect all courses
class UnselectAllCourses extends CourseManagementEvent {
  const UnselectAllCourses();
}

/// Enter selection mode
class EnterSelectionMode extends CourseManagementEvent {
  const EnterSelectionMode();
}

/// Exit selection mode
class ExitSelectionMode extends CourseManagementEvent {
  const ExitSelectionMode();
}

/// Delete selected courses
class DeleteSelectedCourses extends CourseManagementEvent {
  const DeleteSelectedCourses();
}
