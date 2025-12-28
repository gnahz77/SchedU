import 'package:equatable/equatable.dart';
import 'package:schedu/model/course.dart';

class CourseManagementState extends Equatable {
  final List<Course> courses;
  final Set<Course> selectedCourses;
  final bool isSelectionMode;
  final bool loading;
  final String? error;
  final String? successMessage;

  const CourseManagementState({
    this.courses = const [],
    this.selectedCourses = const {},
    this.isSelectionMode = false,
    this.loading = false,
    this.error,
    this.successMessage,
  });

  CourseManagementState copyWith({
    List<Course>? courses,
    Set<Course>? selectedCourses,
    bool? isSelectionMode,
    bool? loading,
    String? error,
    String? successMessage,
  }) {
    return CourseManagementState(
      courses: courses ?? this.courses,
      selectedCourses: selectedCourses ?? this.selectedCourses,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      loading: loading ?? this.loading,
      error: error, // Pass null to clear
      successMessage: successMessage, // Pass null to clear
    );
  }

  int get selectedCount => selectedCourses.length;
  bool get hasSelection => selectedCourses.isNotEmpty;

  @override
  List<Object?> get props => [courses, selectedCourses, isSelectionMode, loading, error, successMessage];
}
