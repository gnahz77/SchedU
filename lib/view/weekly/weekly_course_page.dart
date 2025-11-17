import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/model/course_bloc.dart';
import 'package:schedu/model/course_event.dart';
import 'package:schedu/model/course_state.dart';
import 'package:schedu/model/section_time.dart';
import 'package:schedu/repository/settings_manager.dart';
import 'package:schedu/view/weekly/weekly_schedule_utils.dart';

/// 周课程视图页面
class WeeklyCoursePage extends StatefulWidget {
  const WeeklyCoursePage({super.key});

  @override
  State<WeeklyCoursePage> createState() => _WeeklyCoursePageState();
}

class _WeeklyCoursePageState extends State<WeeklyCoursePage> {
  DateTime _selectedWeekStart = WeeklyScheduleUtils.getWeekStart(DateTime.now());
  int _currentWeek = 1; // 当前周数
  int _totalWeeks = 20; // 学期总周数
  int _maxSections = 12; // 每日最大节数
  bool _showWeekend = true; // 是否显示周末
  int _morningSections = 4; // 上午课程节数
  int _afternoonSections = 4; // 下午课程节数
  int _eveningSections = 4; // 晚上课程节数
  List<SectionTime> _sectionTimes = []; // 节次时间

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  /// 初始化设置
  Future<void> _initSettings() async {
    final currentWeek = await SettingsManager.instance.getCurrentWeek();
    final totalWeeks = await SettingsManager.instance.getTotalWeeks();
    final maxSections = await SettingsManager.instance.getMaxSections();
    final showWeekend = await SettingsManager.instance.getShowWeekend();
    final morningSections = await SettingsManager.instance.getMorningSections();
    final afternoonSections = await SettingsManager.instance.getAfternoonSections();
    final eveningSections = await SettingsManager.instance.getEveningSections();
    final sectionTimes = await SettingsManager.instance.getSectionTimesList();

    setState(() {
      _currentWeek = currentWeek;
      _totalWeeks = totalWeeks;
      _maxSections = maxSections;
      _showWeekend = showWeekend;
      _morningSections = morningSections;
      _afternoonSections = afternoonSections;
      _eveningSections = eveningSections;
      _sectionTimes = sectionTimes;
    });

    _loadCoursesForWeek();
  }

  void _loadCoursesForWeek() {
    context.read<CourseBloc>().add(LoadCoursesForWeek(_selectedWeekStart));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('周课程表'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _goToPreviousWeek,
            icon: const Icon(Icons.chevron_left),
            tooltip: '上一周',
          ),
          IconButton(
            onPressed: _goToNextWeek,
            icon: const Icon(Icons.chevron_right),
            tooltip: '下一周',
          ),
        ],
      ),
      body: Column(
        children: [
          // 周次显示 - 可点击选择
          GestureDetector(
            onTap: _showWeekSelector,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '第$_currentWeek周 ${WeeklyScheduleUtils.formatWeekRange(_selectedWeekStart)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // 课程表
          Expanded(
            child: BlocListener<CourseBloc, CourseState>(
              listener: (context, state) {
                // 当BLoC状态变化时，刷新设置以获取最新配置
                if (state is CourseLoaded || state is CourseDataLoaded) {
                  _initSettings();
                }
              },
              child: BlocBuilder<CourseBloc, CourseState>(
                buildWhen: (previous, current) {
                  // 只在相关状态变化时重建
                  if (current is CourseDataLoaded) {
                    if (previous is CourseDataLoaded) {
                      // 检查当前周的数据是否发生变化
                      return previous.getCoursesForWeek(_selectedWeekStart) !=
                             current.getCoursesForWeek(_selectedWeekStart);
                    }
                    return true;
                  }
                  return current is CourseLoading ||
                         current is CourseError ||
                         current is CourseOperationSuccess;
                },
                builder: (context, state) {
                  if (state is CourseLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (state is CourseDataLoaded) {
                    final courses = state.getCoursesForWeek(_selectedWeekStart);
                    if (courses.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildWeeklySchedule(courses);
                  } else if (state is CoursesForWeekLoaded) {
                    // 兼容旧的状态类型
                    return _buildWeeklySchedule(state.courses);
                  } else if (state is CourseError) {
                    return _buildErrorState(state.message);
                  }
                  return _buildEmptyState();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }  /// 构建周课程表
  Widget _buildWeeklySchedule(List<Course> courses) {
    final displayDays = WeeklyScheduleUtils.getDisplayWeekdays(_showWeekend);
    final dayCount = displayDays.length;

    // 按天分组课程
    final Map<int, List<Course>> coursesByDay = {};
    for (int i = 1; i <= dayCount; i++) {
      coursesByDay[i] = courses.where((c) => c.day == i).toList();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          children: [          // 表头
          _buildTableHeader(displayDays),
            // 表格内容
            _buildTableContent(coursesByDay, dayCount),
          ],
        ),
      ),
    );
  }

  /// 构建表头
  Widget _buildTableHeader(List<String> weekdays) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 节次列
          Container(
            width: 80,
            height: 60,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 0.5,
                ),
              ),
            ),
            child: const Center(
              child: Text(
                '节次',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // 星期列
          ...weekdays.asMap().entries.map((entry) {
            final index = entry.key;
            final weekday = entry.value;
            final date = _selectedWeekStart.add(Duration(days: index));
            final isToday = WeeklyScheduleUtils.isSameDay(date, DateTime.now());

            return Container(
              width: 100,
              height: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekday,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 构建表格内容
  Widget _buildTableContent(Map<int, List<Course>> coursesByDay, int dayCount) {
    final List<Widget> rows = [];
    for (int section = 1; section <= _maxSections; section++) {
      // 检查是否需要添加休息分隔行
      if (WeeklyScheduleUtils.shouldShowBreakRow(section, _morningSections, _afternoonSections)) {
        final breakName = WeeklyScheduleUtils.getBreakRowName(section, _morningSections, _afternoonSections);
        rows.add(_buildBreakRow(breakName, dayCount));
      }

      rows.add(_buildSectionRow(section, coursesByDay, dayCount));
    }

    return Column(children: rows);
  }

  /// 构建休息分隔行
  Widget _buildBreakRow(String breakName, int dayCount) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            child: Center(
              child: Text(
                breakName,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          ...List.generate(dayCount, (index) => Container(
            width: 100,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 0.5,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  /// 构建节次行
  Widget _buildSectionRow(int section, Map<int, List<Course>> coursesByDay, int dayCount) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 节次信息列
          Container(
            width: 80,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$section',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getSectionTimeText(section),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // 课程列
          ...List.generate(dayCount, (dayIndex) {
            final day = dayIndex + 1;
            final daysCourses = coursesByDay[day] ?? [];
            final course = daysCourses.firstWhere(
              (c) => c.sections.contains(section),
              orElse: () => const Course(
                name: '',
                position: '',
                teacher: '',
                weeks: [],
                day: 0,
                sections: [],
              ),
            );

            return Container(
              width: 100,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 0.5,
                  ),
                ),
              ),
              child: course.name.isNotEmpty
                  ? GestureDetector(
                      onTap: () => _showCourseDetail(course),
                      child: _buildCourseCell(course),
                    )
                  : const SizedBox(),
            );
          }),
        ],
      ),
    );
  }

  /// 获取节次时间文本
  String _getSectionTimeText(int section) {
    final sectionTime = _sectionTimes.firstWhere(
      (st) => st.section == section,
      orElse: () => SectionTime(section: section, startTime: '', endTime: ''),
    );
    return '${sectionTime.startTime}\n${sectionTime.endTime}';
  }

  /// 构建课程单元格
  Widget _buildCourseCell(Course course) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          if (course.teacher.isNotEmpty) ...[
            Text(
              course.teacher,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
          ],
          Text(
            course.position,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_view_week_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '本周无课程安排',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCoursesForWeek,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 上一周
  void _goToPreviousWeek() {
    if (_currentWeek <= 1) return;
    setState(() {
      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
      _currentWeek = _currentWeek - 1;
    });
    // 保存当前周数到设置
    SettingsManager.instance.setCurrentWeek(_currentWeek);
    _loadCoursesForWeek();
  }

  /// 下一周
  void _goToNextWeek() {
    if (_currentWeek >= _totalWeeks) return;
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
      _currentWeek = _currentWeek + 1;
    });
    // 保存当前周数到设置
    SettingsManager.instance.setCurrentWeek(_currentWeek);
    _loadCoursesForWeek();
  }

  /// 显示周数选择器
  void _showWeekSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择周数'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _totalWeeks,
            itemBuilder: (context, index) {
              final week = index + 1;
              return ListTile(
                title: Text('第$week周'),
                trailing: _currentWeek == week
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () async {
                  // 先计算第一周的开始日期（基于当前 _selectedWeekStart 与 _currentWeek）
                  final firstWeekStart = _selectedWeekStart.subtract(
                    Duration(days: (_currentWeek - 1) * 7),
                  );
                  final newWeekStart = firstWeekStart.add(
                    Duration(days: (week - 1) * 7),
                  );
                  setState(() {
                    _currentWeek = week;
                    _selectedWeekStart = newWeekStart;
                  });
                  await SettingsManager.instance.setCurrentWeek(week);
                  Navigator.of(context).pop();
                  _loadCoursesForWeek();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 显示课程详情底部弹窗
  void _showCourseDetail(Course course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 拖拽指示器
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 标题栏
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '课程详情',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 课程详情内容
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: _buildCourseDetailContent(course),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建课程详情内容
  Widget _buildCourseDetailContent(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 课程名称
        _buildDetailItem(
          icon: Icons.school,
          title: '课程名称',
          content: course.name,
          color: Theme.of(context).colorScheme.primary,
        ),

        const SizedBox(height: 16),

        // 教师信息
        _buildDetailItem(
          icon: Icons.person,
          title: '任课教师',
          content: course.teacher,
          color: Theme.of(context).colorScheme.secondary,
        ),

        const SizedBox(height: 16),

        // 上课地点
        _buildDetailItem(
          icon: Icons.location_on,
          title: '上课地点',
          content: course.position,
          color: Theme.of(context).colorScheme.tertiary,
        ),

        const SizedBox(height: 16),

        // 上课时间
        _buildDetailItem(
          icon: Icons.schedule,
          title: '上课时间',
          content: '${course.dayText} ${course.timeText}',
          color: Theme.of(context).colorScheme.error,
        ),

        const SizedBox(height: 16),

        // 周数信息
        _buildDetailItem(
          icon: Icons.calendar_today,
          title: '上课周数',
          content: course.weeksText,
          color: Theme.of(context).colorScheme.primary,
        ),

        const SizedBox(height: 24),

        // 详细节次信息
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '节次详情',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...course.sections.map((section) {
                  final timeText = _getSectionTimeText(section);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              section.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            timeText.isNotEmpty ? '第$section节课 ($timeText)' : '第$section节课',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  /// 构建详情项
  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
