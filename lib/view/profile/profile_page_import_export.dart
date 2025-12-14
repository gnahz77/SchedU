import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/course/course_bloc.dart';
import 'package:schedu/bloc/course/course_event.dart';
import 'package:schedu/bloc/settings/settings_bloc.dart';
import 'package:schedu/bloc/settings/settings_event.dart';
import 'package:schedu/repository/settings_manager.dart';
import 'package:schedu/service/course_import_service.dart';

/// 导入导出混入，将导入导出逻辑从 ProfilePage 分离
mixin ImportExportMixin {
  /// 从文件导入课程（支持同时导入时间表配置）
  Future<void> importCoursesFromFile(BuildContext context) async {
    try {
      // 1. 选择并读取文件
      final importData = await CourseImportService.pickAndReadJsonFile();
      if (importData == null) return; // 用户取消选择

      if (!context.mounted) return;

      // 2. 确认对话框
      final hasTimer = importData.scheduleConfig != null;
      final confirmMessage = hasTimer
          ? '找到 ${importData.courses.length} 门课程和时间表配置，确定要导入吗？\n\n注意：这将清空现有的所有课程数据和时间表配置！'
          : '找到 ${importData.courses.length} 门课程，确定要导入吗？\n\n注意：这将清空现有的所有课程数据！';

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

      if (confirmed != true || !context.mounted) return;

      // 3. 显示加载中
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 4. 执行导入逻辑
      try {
        // 导入时间表配置
        if (importData.scheduleConfig != null) {
          await SettingsManager.instance.importScheduleConfig(importData.scheduleConfig!);
          if (context.mounted) {
            context.read<SettingsBloc>().add(LoadSettings());
          }
        }

        // 导入课程
        if (context.mounted) {
          final bloc = context.read<CourseBloc>();
          final completer = Completer<void>();

          bloc.add(ImportCoursesFromJson(
            importData.courses,
            onComplete: (success, message) {
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
          ));

          await completer.future;
        }
      } finally {
        // 无论成功失败，都关闭Loading
        if (context.mounted) {
           Navigator.of(context).pop(); 
        }
      }

    } catch (e) {
      if (context.mounted) {
        // 确保Loading关闭
        // Navigator.of(context).pop(); // 可能需要检查是否有关闭
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: ${e.toString()}')),
        );
      }
    }
  }

  /// 导出课程到文件
  Future<void> exportCoursesToFile(BuildContext context) async {
    // 显示加载中
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bloc = context.read<CourseBloc>();
      final completer = Completer<void>();

      bloc.add(ExportCoursesToFile(
        onComplete: (success, message, jsonData) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      ));

      await completer.future;
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭Loading
      }
    }
  }
}

