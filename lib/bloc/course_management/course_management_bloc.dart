import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/course_management/course_management_event.dart';
import 'package:schedu/bloc/course_management/course_management_state.dart';
import 'package:schedu/repository/course_repository.dart';
import 'package:schedu/model/course.dart';

class CourseManagementBloc extends Bloc<CourseManagementEvent, CourseManagementState> {
  final CourseRepository _courseRepository;

  CourseManagementBloc(this._courseRepository) : super(const CourseManagementState()) {
    on<LoadAllCourses>(_onLoadAllCourses);
    on<SelectCourse>(_onSelectCourse);
    on<UnselectCourse>(_onUnselectCourse);
    on<SelectAllCourses>(_onSelectAllCourses);
    on<UnselectAllCourses>(_onUnselectAllCourses);
    on<EnterSelectionMode>(_onEnterSelectionMode);
    on<ExitSelectionMode>(_onExitSelectionMode);
    on<DeleteSelectedCourses>(_onDeleteSelectedCourses);
  }

  Future<void> _onLoadAllCourses(LoadAllCourses event, Emitter<CourseManagementState> emit) async {
    emit(state.copyWith(loading: true));
    try {
      final courses = await _courseRepository.getAllCourses();
      emit(state.copyWith(courses: courses, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  void _onSelectCourse(SelectCourse event, Emitter<CourseManagementState> emit) {
    final updatedSelection = Set<Course>.from(state.selectedCourses)..add(event.course);
    emit(state.copyWith(selectedCourses: updatedSelection));
  }

  void _onUnselectCourse(UnselectCourse event, Emitter<CourseManagementState> emit) {
    final updatedSelection = Set<Course>.from(state.selectedCourses)..remove(event.course);
    emit(state.copyWith(selectedCourses: updatedSelection));
  }

  void _onSelectAllCourses(SelectAllCourses event, Emitter<CourseManagementState> emit) {
    emit(state.copyWith(selectedCourses: Set<Course>.from(state.courses)));
  }

  void _onUnselectAllCourses(UnselectAllCourses event, Emitter<CourseManagementState> emit) {
    emit(state.copyWith(selectedCourses: {}));
  }

  void _onEnterSelectionMode(EnterSelectionMode event, Emitter<CourseManagementState> emit) {
    emit(state.copyWith(isSelectionMode: true));
  }

  void _onExitSelectionMode(ExitSelectionMode event, Emitter<CourseManagementState> emit) {
    emit(state.copyWith(isSelectionMode: false, selectedCourses: {}));
  }

  Future<void> _onDeleteSelectedCourses(DeleteSelectedCourses event, Emitter<CourseManagementState> emit) async {
    if (state.selectedCourses.isEmpty) return;

    emit(state.copyWith(loading: true));
    try {
      for (final course in state.selectedCourses) {
        await _courseRepository.deleteCourse(course);
      }

      // Reload courses after deletion
      final updatedCourses = await _courseRepository.getAllCourses();
      emit(state.copyWith(
        courses: updatedCourses,
        selectedCourses: {},
        isSelectionMode: false,
        loading: false,
        successMessage: '已删除 ${state.selectedCourses.length} 门课程',
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: '删除失败: ${e.toString()}'));
    }
  }

}
