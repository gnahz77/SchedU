import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/course/course_bloc.dart';
import 'package:schedu/bloc/settings/settings_bloc.dart';
import 'package:schedu/bloc/settings/settings_event.dart';
import 'package:schedu/bloc/settings/settings_state.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/model/section_time.dart';
import 'package:schedu/repository/course_import_service.dart';
import 'package:schedu/repository/settings_manager.dart';
import '../../bloc/course/course_event.dart';
import '../../bloc/course/course_state.dart';
import 'section_times_dialog.dart';

/// 个人设置页面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('我的'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 用户信息卡片
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(
                          Icons.person,
                          size: 36,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '学生用户',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '点击编辑个人信息',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 课程设置分组
              Text(
                '课程设置',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // 课程管理
              _buildSettingItem(
                context,
                icon: Icons.school_outlined,
                title: '课程管理',
                subtitle: '添加、编辑、删除课程',
                onTap: () {
                  // TODO: 导航到课程管理页面
                },
              ),
              // 开学时间设置
              _buildStartSemesterSettingItem(context, settingsState.startSemesterDate),
              // 学期总周数设置
              _buildSettingItem(
                context,
                icon: Icons.calendar_view_week_outlined,
                title: '学期总周数',
                subtitle: '当前设置: ${settingsState.totalWeeks}周',
                onTap: () => _showTotalWeeksSettingDialog(context, settingsState.totalWeeks),
              ),
              // 周末显示设置
              _buildSettingItem(
                context,
                icon: Icons.weekend_outlined,
                title: '显示周末',
                subtitle: settingsState.showWeekend ? '已开启' : '已关闭',
                onTap: () => _showWeekendSettingDialog(context, settingsState.showWeekend),
              ),
              // 每日节数设置
              _buildSettingItem(
                context,
                icon: Icons.format_list_numbered_outlined,
                title: '每日节数',
                subtitle: '当前设置: ${settingsState.maxSections}节',
                onTap: () => _showTimePeriodSettingDialog(
                  context,
                  settingsState.morningSections,
                  settingsState.afternoonSections,
                  settingsState.eveningSections,
                ),
              ),
              // 上课时间设置
              _buildSettingItem(
                context,
                icon: Icons.access_time_outlined,
                title: '上课时间',
                subtitle: '设置每节课的起止时间',
                onTap: () => _showSectionTimesSettingDialog(
                  context,
                  settingsState.sectionTimes,
                  settingsState.maxSections,
                ),
              ),

              const SizedBox(height: 24),

              // 数据管理分组
              Text(
                '数据管理',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // 导入课程
              _buildSettingItem(
                context,
                icon: Icons.file_download_outlined,
                title: '导入课程',
                subtitle: '支持JSON文件导入（可含时间表配置）',
                onTap: () => _showJsonImportDialog(context),
              ),
              // 教务导入
              _buildSettingItem(
                context,
                icon: Icons.language_outlined,
                title: '教务导入',
                subtitle: '从教务系统导入课程',
                onTap: () => _showJwImportDialog(context),
              ),
              // 导出课程
              _buildSettingItem(
                context,
                icon: Icons.file_upload_outlined,
                title: '导出课程',
                subtitle: '导出为JSON文件（含时间表配置）',
                onTap: () => _showExportDialog(context),
              ),

              const SizedBox(height: 24),

              // 其他设置分组
              Text(
                '其他',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // 主题设置
              _buildSettingItem(
                context,
                icon: Icons.brightness_6_outlined,
                title: '主题设置',
                subtitle: _getThemeModeText(settingsState.themeMode),
                onTap: () => _showThemeSettingDialog(context, settingsState.themeMode),
              ),
              // 关于应用
              _buildSettingItem(
                context,
                icon: Icons.info_outline,
                title: '关于应用',
                subtitle: '版本 1.0.0',
                onTap: () => _showAboutDialog(context),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  /// 构建设置项
  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }

  /// 开学日期设置项
  Widget _buildStartSemesterSettingItem(BuildContext context, DateTime? startDate) {
    return _StartSemesterSettingItem(startDate: startDate);
  }

  /// 显示学期总周数设置对话框
  void _showTotalWeeksSettingDialog(BuildContext context, int currentTotalWeeks) {
    int totalWeeks = currentTotalWeeks;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置学期总周数'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请选择本学期总共有多少周：'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: totalWeeks,
              decoration: const InputDecoration(
                labelText: '学期总周数',
                border: OutlineInputBorder(),
              ),
              items: List.generate(25, (index) => index + 10) // 10-34周的选择
                  .map((weeks) => DropdownMenuItem(
                        value: weeks,
                        child: Text('$weeks周'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  totalWeeks = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              context.read<SettingsBloc>().add(UpdateTotalWeeks(totalWeeks));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('学期总周数已设置为$totalWeeks周')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示周末设置对话框
  void _showWeekendSettingDialog(BuildContext context, bool currentShowWeekend) {
    bool showWeekend = currentShowWeekend;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('周末显示设置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('是否在课程表中显示周末？'),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('显示周末'),
                subtitle: const Text('关闭后课程表只显示周一到周五'),
                value: showWeekend,
                onChanged: (value) {
                  setState(() {
                    showWeekend = value;
                  });
                },
              ),
            ],          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                context.read<SettingsBloc>().add(UpdateShowWeekend(showWeekend));
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(showWeekend ? '已开启周末显示' : '已关闭周末显示'),
                  ),
                );
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示时间段设置对话框
  void _showTimePeriodSettingDialog(
    BuildContext context,
    int currentMorning,
    int currentAfternoon,
    int currentEvening,
  ) {
    int morningSections = currentMorning;
    int afternoonSections = currentAfternoon;
    int eveningSections = currentEvening;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('课程时间段设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('设置上午、下午、晚上的课程节数：'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: morningSections,
              decoration: const InputDecoration(
                labelText: '上午节数',
                border: OutlineInputBorder(),
              ),
              items: List.generate(9, (index) => index)
                  .map((sections) => DropdownMenuItem(
                        value: sections,
                        child: Text('$sections节'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  morningSections = value;
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: afternoonSections,
              decoration: const InputDecoration(
                labelText: '下午节数',
                border: OutlineInputBorder(),
              ),
              items: List.generate(9, (index) => index)
                  .map((sections) => DropdownMenuItem(
                        value: sections,
                        child: Text('$sections节'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  afternoonSections = value;
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: eveningSections,
              decoration: const InputDecoration(
                labelText: '晚上节数',
                border: OutlineInputBorder(),
              ),
              items: List.generate(7, (index) => index)
                  .map((sections) => DropdownMenuItem(
                        value: sections,
                        child: Text('$sections节'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  eveningSections = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              context.read<SettingsBloc>().add(UpdateSectionConfig(
                morningSections,
                afternoonSections,
                eveningSections,
              ));
              
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('课程时间段设置已更新')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示节次时间设置对话框
  void _showSectionTimesSettingDialog(
    BuildContext context,
    List<SectionTime> currentSectionTimes,
    int maxSections,
  ) {
    final settingsState = context.read<SettingsBloc>().state;
    final editableSectionTimes = {
      for (final sectionTime in currentSectionTimes) sectionTime.section: sectionTime,
    };

    for (int i = 1; i <= maxSections; i++) {
      editableSectionTimes.putIfAbsent(
        i,
        () => SectionTime(section: i, startTime: '', endTime: ''),
      );
    }

    showDialog(
      context: context,
      builder: (context) => SectionTimesSettingDialog(
        editableSectionTimes: editableSectionTimes,
        maxSections: maxSections,
        morningSections: settingsState.morningSections,
        afternoonSections: settingsState.afternoonSections,
        eveningSections: settingsState.eveningSections,
        onParseTimeOfDay: _parseTimeOfDay,
        onFormatTimeOfDay: _formatTimeOfDay,
      ),
    );
  }

  TimeOfDay? _parseTimeOfDay(String value) {
    if (value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay value) {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// 显示主题设置对话框
  void _showThemeSettingDialog(BuildContext context, ThemeMode currentThemeMode) {
    ThemeMode selectedTheme = currentThemeMode;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('主题设置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('跟随系统'),
                value: ThemeMode.system,
                groupValue: selectedTheme,
                onChanged: (value) {
                  setState(() => selectedTheme = value!);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('浅色模式'),
                value: ThemeMode.light,
                groupValue: selectedTheme,
                onChanged: (value) {
                  setState(() => selectedTheme = value!);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('深色模式'),
                value: ThemeMode.dark,
                groupValue: selectedTheme,
                onChanged: (value) {
                  setState(() => selectedTheme = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                context.read<SettingsBloc>().add(UpdateThemeMode(selectedTheme));
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  /// 显示JSON导入对话框（支持课程和时间表）
  void _showJsonImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入课程'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('选择包含课程信息的JSON文件进行导入。'),
              const SizedBox(height: 16),
              const Text(
                '支持的JSON格式：',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...CourseImportService.getFieldDescriptions().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${entry.key}: ${entry.value}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showExampleDialog(dialogContext),
                      icon: const Icon(Icons.code, size: 16),
                      label: const Text('查看示例'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(dialogContext).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '注意：导入将清空现有课程数据！',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _importCoursesFromFile(context);
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('选择文件'),
          ),
        ],
      ),
    );
  }

  /// 显示教务网站导入对话框
  void _showJwImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('教务网站导入'),
        content:
            const Text('该功能将支持从学校教务系统导入课程数据。\n\n请确保已登录教务系统并获取到正确的课程数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 实现文件选择和导入功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('导入功能开发中...')),
              );
            },
            child: const Text('开始导入')
          )
        ],
      ));
  }

  /// 显示导出课程对话框
  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导出课程'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('将当前的课程数据和时间表配置导出为JSON文件。'),
            SizedBox(height: 16),
            Text(
              '导出内容包括：',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('• 所有课程信息', style: TextStyle(fontSize: 12)),
            Text('• 时间表配置（总周数、开学时间、节次时间等）', style: TextStyle(fontSize: 12)),
            SizedBox(height: 12),
            Text(
              '导出的文件可用于备份或导入到其他设备。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _exportCoursesToFile(context);
            },
            icon: const Icon(Icons.upload, size: 16),
            label: const Text('导出'),
          ),
        ],
      ),
    );
  }

  /// 显示关于对话框
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SchedU',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.school,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: [
        const Text('SchedU是一个简洁优雅的课程表应用，采用Material 3设计风格。'),
        const SizedBox(height: 8),
        const Text('支持课程管理、提醒设置、多视图展示、等功能。可以从JSON文件或教务系统导入课程数据。'),
      ],
    );
  }

  /// 显示示例JSON格式对话框
  void _showExampleDialog(BuildContext context) {
    final exampleJson = CourseImportService.getExampleJsonFormat();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JSON格式示例'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '请按照以下格式准备JSON文件：',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  exampleJson,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: exampleJson));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已复制到剪贴板')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('复制'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 从文件导入课程（支持同时导入时间表配置）
  Future<void> _importCoursesFromFile(BuildContext context) async {
    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在处理文件...'),
            ],
          ),
        ),
      );

      // 选择并读取JSON文件
      final importData = await CourseImportService.pickAndReadJsonFile();

      // 关闭加载对话框
      Navigator.of(context).pop();

      if (importData != null) {
        // 构建确认信息
        final hasTimer = importData.scheduleConfig != null;
        final confirmMessage = hasTimer
            ? '找到 ${importData.courses.length} 门课程和时间表配置，确定要导入吗？\n\n注意：这将清空现有的所有课程数据和时间表配置！'
            : '找到 ${importData.courses.length} 门课程，确定要导入吗？\n\n注意：这将清空现有的所有课程数据！';

        // 确认导入对话框
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

        if (confirmed == true) {
          // 显示导入进度对话框
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
            // 先导入时间表配置（如果有）
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

            // 监听导入结果
            final subscription = context.read<CourseBloc>().stream.listen((state) {
              if (state is CourseOperationSuccess) {
                Navigator.of(context).pop(); // 关闭进度对话框
                final successMessage = hasTimer
                    ? '课程和时间表配置导入成功'
                    : state.message;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(successMessage),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is CourseError) {
                Navigator.of(context).pop(); // 关闭进度对话框
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });

            // 5秒后自动取消订阅，防止内存泄漏
            Future.delayed(const Duration(seconds: 5), () {
              subscription.cancel();
            });
          } catch (e) {
            // 关闭进度对话框
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
    } catch (e, s) {
      print(e);
      print(s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导入失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 导出课程到文件
  Future<void> _exportCoursesToFile(BuildContext context) async {
    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在准备导出数据...'),
            ],
          ),
        ),
      );

      // 获取所有课程
      final courseState = context.read<CourseBloc>().state;
      List<Course> courses = [];
      if (courseState is CourseLoaded) {
        courses = courseState.courses;
      }

      if (courses.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('没有课程数据可以导出'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 获取时间表配置
      final scheduleConfig = await SettingsManager.instance.exportScheduleConfig();

      // 生成JSON字符串
      final jsonString = CourseImportService.exportToJson(
        courses: courses,
        scheduleConfig: scheduleConfig,
      );

      // 转换为字节数据
      final bytes = utf8.encode(jsonString);

      // 关闭加载对话框
      Navigator.of(context).pop();

      // 使用file_picker保存文件
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '保存课程数据',
        fileName: 'schedu_export_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (result != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导出成功：${courses.length}门课程'),
              backgroundColor: Colors.green,
              // action: SnackBarAction(
              //   label: '查看',
              //   textColor: Colors.white,
              //   onPressed: () {
              //     // TODO: 实现跳转打开文件
              //   },
              // ),
            ),
          );
        }
      }
    } catch (e, s) {
      print(e);
      print(s);
      // 确保关闭可能存在的加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// 开学日期设置卡片
class _StartSemesterSettingItem extends StatelessWidget {
  final DateTime? startDate;

  const _StartSemesterSettingItem({this.startDate});

  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = startDate ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5, 12, 31),
    );

    if (pickedDate == null) return;

    final normalized = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
    
    if (context.mounted) {
      context.read<SettingsBloc>().add(UpdateStartSemesterDate(normalized));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('开学日期已更新')),
      );

      context.read<CourseBloc>().add(const LoadCourses());
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = startDate == null
            ? '未设置开学日期，点击进行设置'
            : '当前：${_formatDate(startDate!)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          Icons.calendar_month,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          '开学日期设置',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: () => _pickStartDate(context),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}年$month月$day日';
  }
}
