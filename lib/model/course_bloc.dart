import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/model/course_event.dart';
import 'package:schedu/model/course_state.dart';
import 'package:schedu/repository/course_repository.dart';
import 'package:schedu/repository/settings_manager.dart';

/// 课程业务逻辑处理
class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final CourseRepository _courseRepository;

  CourseBloc(this._courseRepository) : super(CourseInitial()) {
    on<LoadCourses>(_onLoadCourses);
    on<AddCourse>(_onAddCourse);
    on<UpdateCourse>(_onUpdateCourse);
    on<DeleteCourse>(_onDeleteCourse);
    on<ImportCoursesFromJson>(_onImportCoursesFromJson);
    on<LoadCoursesForDay>(_onLoadCoursesForDay);
    on<LoadCoursesForWeek>(_onLoadCoursesForWeek);
  }

  /// 处理加载所有课程事件
  Future<void> _onLoadCourses(
    LoadCourses event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(CourseLoading());
      final courses = await _courseRepository.getAllCourses();
      
      // 如果当前状态是 CourseDataLoaded，则更新其中的所有课程数据
      if (state is CourseDataLoaded) {
        final currentState = state as CourseDataLoaded;
        emit(currentState.withAllCourses(courses));
      } else {
        emit(CourseDataLoaded(allCourses: courses));
      }
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
      
      // 导入后重新初始化状态，清空缓存的日期和周数据
      emit(CourseDataLoaded(allCourses: courses));
      emit(CourseOperationSuccess('课程导入成功', courses));
    } catch (e) {
      emit(CourseError('导入课程失败: ${e.toString()}'));
    }
  }

  /// 处理加载指定日期课程事件
  Future<void> _onLoadCoursesForDay(
    LoadCoursesForDay event,
    Emitter<CourseState> emit,
  ) async {
    try {
      final currentState = state;
      
      // 如果已有数据且包含该日期的缓存，直接使用缓存
      if (currentState is CourseDataLoaded && currentState.hasDailyData(event.date)) {
        return; // 数据已存在，不需要重新加载
      }
      
      final currentWeek = await SettingsManager.instance.getCurrentWeek();
      final courses = await _courseRepository.getCoursesForDay(event.date, currentWeek);
      
      if (currentState is CourseDataLoaded) {
        // 更新现有的复合状态
        emit(currentState.withDailyCourses(event.date, courses));
      } else {
        // 创建新的复合状态
        final allCourses = await _courseRepository.getAllCourses();
        emit(CourseDataLoaded(
          allCourses: allCourses,
          dailyCourses: {CourseDataLoaded.formatDateKey(event.date): courses},
        ));
      }
    } catch (e) {
      emit(CourseError('加载当日课程失败: ${e.toString()}'));
    }
  }

  /// 处理加载指定周课程事件
  Future<void> _onLoadCoursesForWeek(
    LoadCoursesForWeek event,
    Emitter<CourseState> emit,
  ) async {
    try {
      final currentState = state;
      
      // 如果已有数据且包含该周的缓存，直接使用缓存
      if (currentState is CourseDataLoaded && currentState.hasWeeklyData(event.weekStart)) {
        return; // 数据已存在，不需要重新加载
      }
      
      final currentWeek = await SettingsManager.instance.getCurrentWeek();
      final courses = await _courseRepository.getCoursesForWeek(event.weekStart, currentWeek);
      
      if (currentState is CourseDataLoaded) {
        // 更新现有的复合状态
        emit(currentState.withWeeklyCourses(event.weekStart, courses));
      } else {
        // 创建新的复合状态
        final allCourses = await _courseRepository.getAllCourses();
        emit(CourseDataLoaded(
          allCourses: allCourses,
          weeklyCourses: {CourseDataLoaded.formatDateKey(event.weekStart): courses},
        ));
      }
    } catch (e) {
      emit(CourseError('加载周课程失败: ${e.toString()}'));
    }
  }
}
