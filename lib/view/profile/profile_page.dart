import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/model/course_bloc.dart';
import 'package:schedu/model/course_event.dart';
import 'package:schedu/model/course_state.dart';
import 'package:schedu/model/section_time.dart';
import 'package:schedu/repository/course_import_service.dart';
import 'package:schedu/repository/settings_manager.dart';

/// 个人设置页面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
          // 当前周设置
          _buildSettingItem(
            context,
            icon: Icons.calendar_today_outlined,
            title: '当前周设置',
            subtitle: '设置当前是第几周',
            onTap: () async {
              _showWeekSettingDialog(context);
            },
          ),
          // 学期总周数设置
          _buildSettingItem(
            context,
            icon: Icons.date_range_outlined,
            title: '学期总周数',
            subtitle: '设置本学期总共有多少周',
            onTap: () {
              _showTotalWeeksSettingDialog(context);
            },
          ),
          // 周末显示设置
          _buildSettingItem(
            context,
            icon: Icons.weekend_outlined,
            title: '周末显示',
            subtitle: '设置是否在课程表中显示周末',
            onTap: () async {
              final result = await _showWeekendSettingDialog(context);
              if (result == true) {
                // 触发课程数据重新加载
                context.read<CourseBloc>().add(const LoadCourses());
              }
            },
          ),
          // 课程时间段设置
          _buildSettingItem(
            context,
            icon: Icons.access_time_outlined,
            title: '课程时间段',
            subtitle: '设置上午、下午、晚上的节数分配',
            onTap: () {
              _showTimePeriodSettingDialog(context);
            },
          ),
          // 节次时间设置
          _buildSettingItem(
            context,
            icon: Icons.timer_outlined,
            title: '节次时间设置',
            subtitle: '设置每节课的上下课时间',
            onTap: () {
              _showSectionTimesSettingDialog(context);
            },
          ),

          const SizedBox(height: 24),

          // 课程设置分组
          Text(
            '导入导出',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // 导入课程
          _buildSettingItem(
            context,
            icon: Icons.data_object,
            title: 'JSON课程导入',
            subtitle: '从JSON文件导入课程数据',
            onTap: () {
              _showJsonImportDialog(context);
            },
          ),
          // 导入时间表配置
          _buildSettingItem(
            context,
            icon: Icons.schedule_outlined,
            title: 'JSON时间表导入',
            subtitle: '导入课程时间表配置（总周数、开学时间等）',
            onTap: () {
              _showScheduleConfigImportDialog(context);
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.language_outlined,
            title: '教务网站导入',
            subtitle: '从学校教务系统导入课程数据',
            onTap: () {
              _showJwImportDialog(context);
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.file_upload_outlined,
            title: '导出课程',
            subtitle: '导出课程数据到JSON文件',
            onTap: () {
              _showExportDialog(context);
            },
          ),
          
          const SizedBox(height: 24),
          
          // 应用设置分组
          Text(
            '应用设置',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // 提醒设置
          _buildSettingItem(
            context,
            icon: Icons.notifications_outlined,
            title: '提醒设置',
            subtitle: '设置课程提醒和通知',
            onTap: () {
              // TODO: 导航到提醒设置页面
            },
          ),
          
          // 主题设置
          _buildSettingItem(
            context,
            icon: Icons.palette_outlined,
            title: '主题设置',
            subtitle: '切换浅色/深色主题',
            onTap: () {
              // TODO: 主题切换功能
            },
          ),
          
          const SizedBox(height: 24),
          
          // 其他分组
          Text(
            '其他',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // 关于应用
          _buildSettingItem(
            context,
            icon: Icons.info_outlined,
            title: '关于应用',
            subtitle: '版本信息和开发者信息',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          
          // 意见反馈
          _buildSettingItem(
            context,
            icon: Icons.feedback_outlined,
            title: '意见反馈',
            subtitle: '帮助我们改进应用',
            onTap: () {
              // TODO: 意见反馈功能
            },
          ),
        ],
      ),
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

  /// 显示周设置对话框
  void _showWeekSettingDialog(BuildContext context) async {
    int currentWeek = await SettingsManager.instance.getCurrentWeek();
    int totalWeeks = await SettingsManager.instance.getTotalWeeks();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置当前周'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请选择当前是第几周：'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: currentWeek,
              decoration: const InputDecoration(
                labelText: '当前周',
                border: OutlineInputBorder(),
              ),
              items: List.generate(totalWeeks, (index) => index + 1)
                  .map((week) => DropdownMenuItem(
                        value: week,
                        child: Text('第$week周'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  currentWeek = value;
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
            onPressed: () async {
              await SettingsManager.instance.setCurrentWeek(currentWeek);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('当前周已设置为第$currentWeek周')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示学期总周数设置对话框
  void _showTotalWeeksSettingDialog(BuildContext context) async {
    int totalWeeks = await SettingsManager.instance.getTotalWeeks();
    
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
            onPressed: () async {
              await SettingsManager.instance.setTotalWeeks(totalWeeks);
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
  Future<bool?> _showWeekendSettingDialog(BuildContext context) async {
    bool showWeekend = await SettingsManager.instance.getShowWeekend();
    
    return showDialog<bool>(
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                await SettingsManager.instance.setShowWeekend(showWeekend);
                Navigator.of(context).pop(true); // 返回true表示有设置变更
                
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
  void _showTimePeriodSettingDialog(BuildContext context) async {
    int morningSections = await SettingsManager.instance.getMorningSections();
    int afternoonSections = await SettingsManager.instance.getAfternoonSections();
    int eveningSections = await SettingsManager.instance.getEveningSections();
    
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
            onPressed: () async {
              await SettingsManager.instance.setMorningSections(morningSections);
              await SettingsManager.instance.setAfternoonSections(afternoonSections);
              await SettingsManager.instance.setEveningSections(eveningSections);
              
              // 更新总节数
              final totalSections = morningSections + afternoonSections + eveningSections;
              await SettingsManager.instance.setMaxSections(totalSections);
              
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('时间段设置已保存')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示节次时间设置对话框
  void _showSectionTimesSettingDialog(BuildContext context) async {
    final sectionTimes = await SettingsManager.instance.getSectionTimesList();
    final maxSections = await SettingsManager.instance.getMaxSections();
    
    // 创建一个副本用于编辑
    List<SectionTime> editableSectionTimes = List.from(sectionTimes);

    // 确保有足够的节次
    for (int i = 1; i <= maxSections; i++) {
      if (!editableSectionTimes.any((st) => st.section == i)) {
        editableSectionTimes.add(SectionTime(
          section: i,
          startTime: '',
          endTime: '',
        ));
      }
    }

    // 按节次排序
    editableSectionTimes.sort((a, b) => a.section.compareTo(b.section));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('节次时间设置'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: maxSections,
            itemBuilder: (context, index) {
              final section = index + 1;
              final sectionTime = editableSectionTimes.firstWhere(
                (st) => st.section == section,
                orElse: () => SectionTime(section: section, startTime: '', endTime: ''),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '第$section节',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: sectionTime.startTime,
                              decoration: const InputDecoration(
                                labelText: '开始时间',
                                hintText: '08:00',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                // 找到对应的节次并更新
                                final index = editableSectionTimes.indexWhere((st) => st.section == section);
                                if (index != -1) {
                                  editableSectionTimes[index] = SectionTime(
                                    section: section,
                                    startTime: value,
                                    endTime: editableSectionTimes[index].endTime,
                                  );
                                } else {
                                  editableSectionTimes.add(SectionTime(
                                    section: section,
                                    startTime: value,
                                    endTime: '',
                                  ));
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: sectionTime.endTime,
                              decoration: const InputDecoration(
                                labelText: '结束时间',
                                hintText: '08:45',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                // 找到对应的节次并更新
                                final index = editableSectionTimes.indexWhere((st) => st.section == section);
                                if (index != -1) {
                                  editableSectionTimes[index] = SectionTime(
                                    section: section,
                                    startTime: editableSectionTimes[index].startTime,
                                    endTime: value,
                                  );
                                } else {
                                  editableSectionTimes.add(SectionTime(
                                    section: section,
                                    startTime: '',
                                    endTime: value,
                                  ));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              // 过滤掉空的时间设置
              final validSectionTimes = editableSectionTimes.where((st) =>
                st.startTime.isNotEmpty && st.endTime.isNotEmpty).toList();

              await SettingsManager.instance.setSectionTimesList(validSectionTimes);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('节次时间设置已保存')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示JSON导入对话框
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
            icon: const Icon(Icons.file_upload, size: 16),
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
    // TODO: 实现导出课程功能
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

  /// 显示时间表配置导入对话框
  void _showScheduleConfigImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入时间表配置'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('选择包含时间表配置信息的JSON文件进行导入。'),
              const SizedBox(height: 16),
              const Text(
                '支持的配置项：',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...CourseImportService.getScheduleConfigFieldDescriptions().entries.map(
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
                      onPressed: () => _showScheduleConfigExampleDialog(dialogContext),
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
                '注意：导入的配置将覆盖当前设置！',
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
              await _importScheduleConfigFromFile(context);
            },
            icon: const Icon(Icons.file_upload, size: 16),
            label: const Text('选择文件'),
          ),
        ],
      ),
    );
  }

  /// 显示时间表配置示例对话框
  void _showScheduleConfigExampleDialog(BuildContext context) {
    final exampleJson = CourseImportService.getScheduleConfigExampleFormat();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('时间表配置JSON示例'),
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

  /// 从文件导入课程
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
      final courseData = await CourseImportService.pickAndReadJsonFile();

      // 关闭加载对话框
      Navigator.of(context).pop();

      if (courseData != null) {
        // 确认导入对话框
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认导入'),
            content: Text('找到 ${courseData.length} 门课程，确定要导入吗？\n\n注意：这将清空现有的所有课程数据！'),
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
                  Text('正在导入课程...'),
                ],
              ),
            ),
          );

          // 执行导入
          context.read<CourseBloc>().add(ImportCoursesFromJson(courseData));

          // 监听导入结果
          final subscription = context.read<CourseBloc>().stream.listen((state) {
            if (state is CourseOperationSuccess) {
              Navigator.of(context).pop(); // 关闭进度对话框
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
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

  /// 从文件导入时间表配置
  Future<void> _importScheduleConfigFromFile(BuildContext context) async {
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
      final configData = await CourseImportService.pickAndReadScheduleConfigFile();

      // 关闭加载对话框
      Navigator.of(context).pop();

      if (configData != null) {
        // 显示配置预览和确认对话框
        final confirmed = await _showScheduleConfigPreviewDialog(context, configData);

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
                  Text('正在导入配置...'),
                ],
              ),
            ),
          );

          try {
            // 执行导入
            await SettingsManager.instance.importScheduleConfig(configData);
            
            // 关闭进度对话框
            Navigator.of(context).pop();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('时间表配置导入成功'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            // 关闭进度对话框
            Navigator.of(context).pop();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('导入配置失败: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      // 确保关闭可能存在的加载对话框
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导入失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 显示时间表配置预览对话框
  Future<bool?> _showScheduleConfigPreviewDialog(BuildContext context, ScheduleConfig config) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认导入配置'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '即将导入以下配置项：',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (config.totalWeek != null)
                _buildConfigItem('学期总周数', '${config.totalWeek}周'),
              if (config.startSemester != null)
                _buildConfigItem('开学时间', '时间戳: ${config.startSemester}'),
              if (config.startWithSunday != null)
                _buildConfigItem('周日起始', config.startWithSunday! ? '是' : '否'),
              if (config.showWeekend != null)
                _buildConfigItem('显示周末', config.showWeekend! ? '是' : '否'),
              if (config.forenoon != null)
                _buildConfigItem('上午节数', '${config.forenoon}节'),
              if (config.afternoon != null)
                _buildConfigItem('下午节数', '${config.afternoon}节'),
              if (config.night != null)
                _buildConfigItem('晚间节数', '${config.night}节'),
              if (config.sections != null && config.sections!.isNotEmpty)
                _buildConfigItem('节次时间', '${config.sections!.length}个节次'),
              const SizedBox(height: 12),
              const Text(
                '注意：导入将覆盖相应的当前设置！',
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
  }

  /// 构建配置项显示
  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
