import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/course/course_bloc.dart';
import 'package:schedu/bloc/course/course_event.dart';
import 'package:schedu/bloc/course/course_state.dart';
import 'package:schedu/bloc/daily_course/daily_course_bloc.dart';
import 'package:schedu/bloc/daily_course/daily_course_event.dart';
import 'package:schedu/bloc/weekly_course/weekly_course_bloc.dart';
import 'package:schedu/bloc/weekly_course/weekly_course_event.dart';
import 'package:schedu/bloc/settings/settings_bloc.dart';
import 'package:schedu/bloc/settings/settings_event.dart';
import 'package:schedu/repository/settings_manager.dart';

/// 导入导出混入，将导入导出逻辑从 ProfilePage 分离
mixin ImportExportMixin {
  /// 从文件导入课程（支持同时导入时间表配置）
  Future<void> importCoursesFromFile(BuildContext context) async {
    // 触发导入事件
    context.read<CourseBloc>().add(const ImportCoursesFromFile());
    
    // 监听状态变化
    final subscription = context.read<CourseBloc>().stream.listen((state) async {
      if (state is CourseProcessing) {
        // 显示处理中对话框
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(state.message),
                ],
              ),
            ),
          );
        }
      } else if (state is CourseImportConfirmation) {
        // 关闭处理对话框
        if (context.mounted) {
          Navigator.of(context).pop();
          
          // 显示确认对话框
          final hasTimer = state.hasScheduleConfig;
          final confirmMessage = hasTimer
              ? '找到 ${state.courseCount} 门课程和时间表配置，确定要导入吗？\n\n注意：这将清空现有的所有课程数据和时间表配置！'
              : '找到 ${state.courseCount} 门课程，确定要导入吗？\n\n注意：这将清空现有的所有课程数据！';

          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('确认导入'),
              content: Text(confirmMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('确定导入'),
                ),
              ],
            ),
          );

          if (confirmed == true && context.mounted) {
            // 显示导入进度
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('正在导入数据...'),
                  ],
                ),
              ),
            );

            try {
              final importData = state.importData;
              
              // 导入时间表配置（如果有）
              if (importData.scheduleConfig != null) {
                await SettingsManager.instance.importScheduleConfig(importData.scheduleConfig!);
                if (context.mounted) {
                  context.read<SettingsBloc>().add(LoadSettings());
                }
              }

              // 导入课程数据
              if (context.mounted) {
                context.read<CourseBloc>().add(ImportCoursesFromJson(importData.courses));
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('导入失败: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        }
      } else if (state is CourseOperationSuccess) {
        // 关闭进度对话框
        if (context.mounted) {
          Navigator.of(context).pop();
          
          // 刷新所有课程相关的 Bloc
          context.read<DailyCourseBloc>().add(const RefreshDailyCourses());
          context.read<WeeklyCourseBloc>().add(const RefreshWeeklyCourses());
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (state is CourseError) {
        // 关闭可能存在的对话框
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });

    // 5秒后自动取消订阅
    Future.delayed(const Duration(seconds: 5), () {
      subscription.cancel();
    });
  }

  /// 导出课程到文件
  Future<void> exportCoursesToFile(BuildContext context) async {
    // 触发导出事件
    context.read<CourseBloc>().add(const ExportCoursesToFile());
    
    // 监听状态变化
    final subscription = context.read<CourseBloc>().stream.listen((state) async {
      if (state is CourseProcessing) {
        // 显示处理中对话框
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(state.message),
                ],
              ),
            ),
          );
        }
      } else if (state is CourseExportSuccess) {
        // 关闭处理对话框
        if (context.mounted) {
          Navigator.of(context).pop();
          
          // 转换为字节数据
          final bytes = utf8.encode(state.jsonData);
          
          // 使用file_picker保存文件
          final result = await FilePicker.platform.saveFile(
            dialogTitle: '保存课程数据',
            fileName: 'schedu_export_${DateTime.now().millisecondsSinceEpoch}.json',
            type: FileType.custom,
            allowedExtensions: ['json'],
            bytes: bytes,
          );

          if (result != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('导出成功：${state.courseCount}门课程'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else if (state is CourseError) {
        // 关闭可能存在的对话框
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: state.message.contains('没有') ? Colors.orange : Colors.red,
            ),
          );
        }
      }
    });

    // 5秒后自动取消订阅
    Future.delayed(const Duration(seconds: 5), () {
      subscription.cancel();
    });
  }
}
