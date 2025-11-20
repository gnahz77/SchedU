import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/course/course_event.dart';
import 'package:schedu/repository/course_repository.dart';
import 'course_state.dart';

/// 课程业务逻辑处理
class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final CourseRepository _courseRepository;

  CourseBloc(this._courseRepository) : super(CourseInitial()) {
    on<LoadCourses>(_onLoadCourses);
    on<AddCourse>(_onAddCourse);
    on<UpdateCourse>(_onUpdateCourse);
    on<DeleteCourse>(_onDeleteCourse);
    on<ImportCoursesFromJson>(_onImportCoursesFromJson);
  }

  /// 处理加载所有课程事件
  Future<void> _onLoadCourses(
    LoadCourses event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(CourseLoading());
      final courses = await _courseRepository.getAllCourses();
      emit(CourseLoaded(courses));
    } catch (e) {
      emit(CourseError('加载课程失败: ${e.toString()}'));
    }
  }

  /// 处理添加课程事件
  Future<void> _onAddCourse(
    AddCourse event,
    Emitter<CourseState> emit,
  ) async {
    try {
      await _courseRepository.insertCourse(event.course);
      final courses = await _courseRepository.getAllCourses();
      emit(CourseOperationSuccess('课程添加成功', courses));
    } catch (e) {
      emit(CourseError('添加课程失败: ${e.toString()}'));
    }
  }

  /// 处理更新课程事件
  Future<void> _onUpdateCourse(
    UpdateCourse event,
    Emitter<CourseState> emit,
  ) async {
    try {
      await _courseRepository.updateCourse(event.course);
      final courses = await _courseRepository.getAllCourses();
      emit(CourseOperationSuccess('课程更新成功', courses));
    } catch (e) {
      emit(CourseError('更新课程失败: ${e.toString()}'));
    }
  }

  /// 处理删除课程事件
  Future<void> _onDeleteCourse(
    DeleteCourse event,
    Emitter<CourseState> emit,
  ) async {
    try {
      await _courseRepository.deleteCourse(event.course);
      final courses = await _courseRepository.getAllCourses();
      emit(CourseOperationSuccess('课程删除成功', courses));
    } catch (e) {
      emit(CourseError('删除课程失败: ${e.toString()}'));
    }
  }

  /// 处理从JSON导入课程事件
  Future<void> _onImportCoursesFromJson(
    ImportCoursesFromJson event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(CourseLoading());
      await _courseRepository.importCoursesFromJson(event.jsonData);
      final courses = await _courseRepository.getAllCourses();
      emit(CourseOperationSuccess('课程导入成功', courses));
    } catch (e) {
      emit(CourseError('导入课程失败: ${e.toString()}'));
    }
  }
}
