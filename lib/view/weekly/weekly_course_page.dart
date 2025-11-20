import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/settings/settings_bloc.dart';
import 'package:schedu/bloc/settings/settings_state.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/bloc/course/course_bloc.dart';
import 'package:schedu/model/section_time.dart';
import 'package:schedu/style/colors.dart';
import 'package:schedu/view/weekly/weekly_schedule_utils.dart';
import '../../bloc/course/course_event.dart';
import '../../bloc/course/course_state.dart';

/// 周课程视图页面
class WeeklyCoursePage extends StatefulWidget {
  const WeeklyCoursePage({super.key});

  @override
  State<WeeklyCoursePage> createState() => _WeeklyCoursePageState();
}

class _WeeklyCoursePageState extends State<WeeklyCoursePage> {
  int _currentWeek = 1;
  late DateTime _selectedWeekStart;
  int _totalWeeks = 20;
  DateTime? _startSemesterDate;

  /// 初始化页面状态
  @override
  void initState() {
    super.initState();
    final settingsState = context.read<SettingsBloc>().state;
    _startSemesterDate = settingsState.startSemesterDate;
    _totalWeeks = settingsState.totalWeeks;
    _currentWeek = _calculateCurrentWeek(_startSemesterDate);
    _selectedWeekStart = _getWeekStart(_currentWeek, _startSemesterDate);
  }

  /// 计算当前周（基于开学日期），返回值最小为 1
  int _calculateCurrentWeek(DateTime? startSemester) {
    if (startSemester == null) return 1;
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    final s = DateTime(startSemester.year, startSemester.month, startSemester.day);
    final diff = d.difference(s).inDays;
    if (diff < 0) return 1;
    return (diff / 7).floor() + 1;
  }

  /// 获取指定周号对应的周起始日期（优先使用开学日期）
  DateTime _getWeekStart(int weekNumber, DateTime? startSemester) {
    if (startSemester == null) {
      return WeeklyScheduleUtils.getWeekStart(DateTime.now());
    }
    final start = WeeklyScheduleUtils.getWeekStart(startSemester);
    return start.add(Duration(days: (weekNumber - 1) * 7));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state.startSemesterDate != _startSemesterDate || state.totalWeeks != _totalWeeks) {
          setState(() {
            _startSemesterDate = state.startSemesterDate;
            _totalWeeks = state.totalWeeks;
            _currentWeek = _calculateCurrentWeek(_startSemesterDate);
            _selectedWeekStart = _getWeekStart(_currentWeek, _startSemesterDate);
          });
        }
      },
      child: Scaffold(
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
            child: BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, settingsState) {
                return BlocBuilder<CourseBloc, CourseState>(
                  builder: (context, state) {
                    if (state is CourseLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (state is CourseLoaded) {
                      final courses = state.courses.where((c) => c.weeks.contains(_currentWeek)).toList();
                      if (courses.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildWeeklySchedule(courses, settingsState, _selectedWeekStart);
                    } else if (state is CourseError) {
                      return _buildErrorState(state.message);
                    }
                    return _buildEmptyState();
                  },
                );
              },
            ),
          ),
        ],
      ),
    ));
  }

  /// 根据课程与当前设置构建整个周视图
  Widget _buildWeeklySchedule(List<Course> courses, SettingsState settings, DateTime weekStart) {
    final displayDays = WeeklyScheduleUtils.getDisplayWeekdays(settings.showWeekend);
    final dayCount = displayDays.length;

    final Map<int, List<Course>> coursesByDay = {};
    for (int i = 1; i <= dayCount; i++) {
      coursesByDay[i] = courses.where((c) => c.day == i).toList();
    }

    const sectionColumnWidth = 48.0; // 调小节次列宽度
    const minDayColumnWidth = 68.0;
    const maxDayColumnWidth = 108.0;
    const sectionCellHeight = 64.0;
    const breakCellHeight = 24.0;
    const headerHeight = 48.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        // 计算可用宽度并确定每日列宽度
        final availableWidth = math.max(screenWidth - sectionColumnWidth, 0.0);
        final rawDayWidth = dayCount > 0 ? availableWidth / dayCount : minDayColumnWidth;
        final dayColumnWidth = math.min(math.max(rawDayWidth, minDayColumnWidth), maxDayColumnWidth);
        final contentWidth = sectionColumnWidth + dayColumnWidth * dayCount;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTableHeader(displayDays, weekStart, sectionColumnWidth, dayColumnWidth, headerHeight),
                  _buildTableContent(coursesByDay, dayCount, settings, sectionColumnWidth, dayColumnWidth, sectionCellHeight, breakCellHeight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建表头（节次列 + 每日列，显示星期与日期）
  Widget _buildTableHeader(List<String> weekdays, DateTime weekStart, double sectionWidth, double dayWidth, double headerHeight) {
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
          Container(
            width: sectionWidth,
            height: headerHeight,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
          ...weekdays.asMap().entries.map((entry) {
            final index = entry.key;
            final weekday = entry.value;
            final date = weekStart.add(Duration(days: index));
            final isToday = WeeklyScheduleUtils.isSameDay(date, DateTime.now());

            return Container(
              width: dayWidth,
              height: headerHeight,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 构建表格内容区域
  Widget _buildTableContent(Map<int, List<Course>> coursesByDay, int dayCount, SettingsState settings, double sectionWidth, double dayWidth, double sectionHeight, double breakHeight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionColumn(settings, sectionWidth, sectionHeight, breakHeight),
        ...List.generate(dayCount, (index) {
          return _buildDayColumn(index + 1, coursesByDay[index + 1] ?? [], settings, dayWidth, sectionHeight, breakHeight);
        }),
      ],
    );
  }

  /// 构建节次列
  Widget _buildSectionColumn(SettingsState settings, double sectionWidth, double sectionHeight, double breakHeight) {
    final List<Widget> children = [];
    for (int section = 1; section <= settings.maxSections; section++) {
      if (WeeklyScheduleUtils.shouldShowBreakRow(section, settings.morningSections, settings.afternoonSections)) {
        final breakName = WeeklyScheduleUtils.getBreakRowName(section, settings.morningSections, settings.afternoonSections);
        children.add(_buildSectionBreakCell(breakName, sectionWidth, breakHeight));
      }
      children.add(_buildSectionNumberCell(section, settings.sectionTimes, sectionWidth, sectionHeight));
    }
    return Column(children: children);
  }

  /// 构建单日列
  Widget _buildDayColumn(int day, List<Course> courses, SettingsState settings, double dayWidth, double sectionHeight, double breakHeight) {
    final List<Widget> children = [];
    int section = 1;
    while (section <= settings.maxSections) {
      if (WeeklyScheduleUtils.shouldShowBreakRow(section, settings.morningSections, settings.afternoonSections)) {
        children.add(_buildDayBreakCell(dayWidth, breakHeight));
      }

      final course = courses.firstWhere(
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

      if (course.name.isNotEmpty) {
        int span = 1;
        int nextSection = section + 1;
        double height = sectionHeight;

        // 计算课程所占行高与跨越节数
        while (nextSection <= settings.maxSections && course.sections.contains(nextSection)) {
          if (WeeklyScheduleUtils.shouldShowBreakRow(nextSection, settings.morningSections, settings.afternoonSections)) {
            height += breakHeight;
          }
          height += sectionHeight;
          span++;
          nextSection++;
        }

        children.add(Container(
          height: height,
          width: dayWidth,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: GestureDetector(
            onTap: () => _showCourseDetail(course),
            child: _buildCourseCell(course),
          ),
        ));
        
        section += span;
      } else {
        children.add(Container(
          height: sectionHeight,
          width: dayWidth,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
            ),
          ),
        ));
        section++;
      }
    }
    return Column(children: children);
  }

  /// 构建节次分隔行
  Widget _buildSectionBreakCell(String name, double width, double height) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
      child: Center(
        child: Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 构建每天列中的分隔单元
  Widget _buildDayBreakCell(double width, double height) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
    );
  }

  /// 构建节次编号单元并显示对应时间
  Widget _buildSectionNumberCell(int section, List<SectionTime> sectionTimes, double width, double height) {
    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
          bottom: BorderSide(
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
            WeeklyScheduleUtils.formatSectionTime(sectionTimes, section),
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建课程格子内容
  Widget _buildCourseCell(Course course) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 定义一个阈值，当格子高度小于此值时不显示位置信息
        const double positionShowThreshold = 65.0;
        final showPosition = constraints.maxHeight >= positionShowThreshold;
        final backgroundColor = _getCourseBackgroundColor(context, course);
        final textColor = _getCourseContentColor(backgroundColor);
        final subTextColor = textColor.withOpacity(0.9);
        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              if (course.teacher.isNotEmpty) ...[
                Text(
                  course.teacher,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: subTextColor,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
              ],
              if (showPosition)
              Text(
                course.position,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: subTextColor,
                  fontSize: 10,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }
    );
  }

  /// 构建空状态视图
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

  /// 构建错误状态视图并提供重试按钮以重新加载课程
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
            onPressed: () => context.read<CourseBloc>().add(const LoadCourses()),
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
  }

  /// 下一周
  void _goToNextWeek() {
    if (_currentWeek >= _totalWeeks) return;
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
      _currentWeek = _currentWeek + 1;
    });
  }

  /// 显示周数选择对话框，用户可选择要跳转的周
  void _showWeekSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '选择周数',
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

              // 周数列表
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: _totalWeeks,
                  itemBuilder: (context, index) {
                    final week = index + 1;
                    final realCurrentWeek = _calculateCurrentWeek(_startSemesterDate);
                    final isRealCurrentWeek = week == realCurrentWeek;
                    final isSelected = _currentWeek == week;

                    Color? backgroundColor = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5);
                    Color textColor = Theme.of(context).colorScheme.onSurfaceVariant;
                    BoxBorder? border;

                    if (isSelected) {
                      // 选中周
                      backgroundColor = Theme.of(context).colorScheme.primary;
                      textColor = Theme.of(context).colorScheme.onPrimary;
                    } else if (isRealCurrentWeek) {
                      // 非选中但为当前周
                      backgroundColor = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5);
                      textColor = Theme.of(context).colorScheme.primary;
                      border = Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        // 计算第一周的开始日期（优先使用开学日期）
                        final firstWeekStart = _startSemesterDate != null
                            ? WeeklyScheduleUtils.getWeekStart(_startSemesterDate!)
                            : _selectedWeekStart.subtract(
                                Duration(days: (_currentWeek - 1) * 7),
                              );
                        final newWeekStart = firstWeekStart.add(
                          Duration(days: (week - 1) * 7),
                        );
                        setState(() {
                          _currentWeek = week;
                          _selectedWeekStart = newWeekStart;
                        });
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: border,
                        ),
                        child: Center(
                          child: Text(
                            '$week',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示课程详情底部弹窗，展示课程详细信息
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

  /// 构建课程详情面板内容
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

  /// 构建带图标的详情项组件
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

  String _getSectionTimeText(int section) {
    final settingsState = context.read<SettingsBloc>().state;
    final sectionTime = settingsState.sectionTimes.firstWhere(
      (st) => st.section == section,
      orElse: () => SectionTime(section: section, startTime: '', endTime: ''),
    );
    
    if (sectionTime.startTime.isEmpty || sectionTime.endTime.isEmpty) {
      return '';
    }
    return '${sectionTime.startTime}-${sectionTime.endTime}';
  }

  int _courseIdentityHash(Course course) {
    final buffer = '${course.name}#${course.teacher}#${course.position}';
    var hash = 0;
    for (final code in buffer.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash;
  }

  Color _getCourseBackgroundColor(BuildContext context, Course course) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = isDark
        ? AppColors.darkLessonTilePalette
        : AppColors.lessonTilePalette;
    if (palette.isEmpty) {
      return theme.colorScheme.primaryContainer;
    }
    final seed = course.colorId ?? _courseIdentityHash(course);
    final index = seed % palette.length;
    return palette[index];
  }

  Color _getCourseContentColor(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }
}
