import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/course/course_event.dart';
import 'package:schedu/repository/course_repository.dart';
import 'package:schedu/service/course_import_service.dart';
import 'package:schedu/repository/settings_manager.dart';
import 'course_state.dart';

/// 课程业务逻辑处理
class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final CourseRepository _courseRepository;

  CourseBloc(this._courseRepository) : super(CourseInitial()) {
    on<AddCourse>(_onAddCourse);
    on<UpdateCourse>(_onUpdateCourse);
    on<DeleteCourse>(_onDeleteCourse);
    on<ImportCoursesFromJson>(_onImportCoursesFromJson);
    on<ExportCoursesToFile>(_onExportCoursesToFile);
  }

  /// 处理添加课程事件
  Future<void> _onAddCourse(
    AddCourse event,
    Emitter<CourseState> emit,
  ) async {
    try {
      await _courseRepository.insertCourse(event.course);
      emit(const CourseOperationSuccess('课程添加成功'));
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
      emit(const CourseOperationSuccess('课程更新成功'));
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
      emit(const CourseOperationSuccess('课程删除成功'));
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
      emit(const CourseProcessing('正在导入课程...'));
      await _courseRepository.importCoursesFromJson(event.jsonData);
      emit(const CourseOperationSuccess('课程导入成功'));
      event.onComplete?.call(true, '课程导入成功');
    } catch (e) {
      final errorMsg = '导入课程失败: ${e.toString()}';
      emit(CourseError(errorMsg));
      event.onComplete?.call(false, errorMsg);
    }
  }

  /// 处理导出课程到文件事件
  Future<void> _onExportCoursesToFile(
    ExportCoursesToFile event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(const CourseProcessing('正在准备导出数据...'));
      
      // 获取所有课程
      final courses = await _courseRepository.getAllCourses();
      
      if (courses.isEmpty) {
        const msg = '没有可导出的课程数据';
        emit(const CourseError(msg));
        event.onComplete?.call(false, msg, null);
        return;
      }

      // 获取时间表配置
      final scheduleConfig = await SettingsManager.instance.exportScheduleConfig();

      // 生成JSON字符串
      final jsonString = CourseImportService.exportToJson(
        courses: courses,
        scheduleConfig: scheduleConfig,
      );

      emit(CourseExportSuccess(
        jsonData: jsonString,
        courseCount: courses.length,
      ));
      event.onComplete?.call(true, '导出成功', jsonString);
    } catch (e) {
      final errorMsg = '导出失败: ${e.toString()}';
      emit(CourseError(errorMsg));
      event.onComplete?.call(false, errorMsg, null);
    }
  }
}
