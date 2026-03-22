import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/weekly_course/weekly_course_bloc.dart';
import 'package:schedu/bloc/weekly_course/weekly_course_event.dart';
import 'package:schedu/bloc/weekly_course/weekly_course_state.dart';
import 'package:schedu/model/app_settings.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/service/course_conflict_utils.dart';
import 'package:schedu/model/section_time.dart';
import 'package:schedu/style/colors.dart';
import 'package:schedu/view/widget/course_detail_bottom_sheet.dart';
import 'package:schedu/view/weekly/weekly_schedule_utils.dart';

class WeeklyCoursePage extends StatefulWidget {
  const WeeklyCoursePage({super.key});

  @override
  State<StatefulWidget> createState() => _WeeklyCoursePageState();
}

/// 周课程视图页面
class _WeeklyCoursePageState extends State<WeeklyCoursePage>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      // 应用恢复时刷新当前周课程
      context.read<WeeklyCourseBloc>().add(const RefreshWeeklyCourses());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeeklyCourseBloc, WeeklyCourseState>(
      builder: (context, state) {
        if (state is WeeklyCourseLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is WeeklyCourseError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('周课程表'),
            ),
            body: _buildErrorState(context, state.message),
          );
        } else if (state is! WeeklyCourseLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('周课程表'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: state.currentWeek > 1
                    ? () => context.read<WeeklyCourseBloc>().add(const GoToPreviousWeek())
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: '上一周',
              ),
              IconButton(
                onPressed: state.currentWeek < state.settings.totalWeeks
                    ? () => context.read<WeeklyCourseBloc>().add(const GoToNextWeek())
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: '下一周',
              ),
            ],
          ),
          body: Column(
            children: [
              // 周次显示
              GestureDetector(
                onTap: () => _showWeekSelector(
                    context,
                    currentWeek: state.currentWeek,
                    totalWeeks: state.settings.totalWeeks,
                    startSemesterDate: DateTime.fromMillisecondsSinceEpoch(state.settings.startSemester)
                ),
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
                        state.isHoliday
                            ? '假期中'
                            : '第 ${state.currentWeek} 周 ${_getWeekDateRange(state.weekStart)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              // 周视图主体
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.isHoliday) {
                      return _buildHolidayState(context);
                    }
                    final hasCourses = state.coursesByDay
                        .any((dayCourses) => dayCourses.isNotEmpty);
                    if (!hasCourses) {
                      return _buildEmptyState(context);
                    }
                    return _buildWeeklySchedule(
                      context,
                      state.coursesByDay,
                      state.settings,
                      state.weekStart,
                      currentWeek: state.currentWeek,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 根据课程与当前设置构建整个周视图
  Widget _buildWeeklySchedule(BuildContext context, List<List<Course>> coursesByDay, AppSettings settings, DateTime weekStart, {required int currentWeek}) {
    final displayDays = WeeklyScheduleUtils.getDisplayWeekdays(settings.showWeekend);
    final dayCount = displayDays.length;

    const sectionColumnWidth = 48.0;
    const minDayColumnWidth = 68.0;
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
        final dayColumnWidth = dayCount > 0 ? availableWidth / dayCount : minDayColumnWidth;

        final scheduleColumn = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTableHeader(context, displayDays, weekStart, sectionColumnWidth, dayColumnWidth, headerHeight),
            _buildTableContent(context, coursesByDay, dayCount, settings, sectionColumnWidth, dayColumnWidth, sectionCellHeight, breakCellHeight, currentWeek: currentWeek),
          ],
        );

        final verticalScroll = SingleChildScrollView(child: scheduleColumn);

        return Container(
          width: double.infinity,
          child: verticalScroll,
        );
      },
    );
  }

  /// 构建表头（节次列 + 每日列，显示星期与日期）
  Widget _buildTableHeader(BuildContext context, List<String> weekdays, DateTime weekStart, double sectionWidth, double dayWidth, double headerHeight) {
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
  Widget _buildTableContent(BuildContext context, List<List<Course>> coursesByDay, int dayCount, AppSettings settings, double sectionWidth, double dayWidth, double sectionHeight, double breakHeight, {required int currentWeek}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionColumn(context, settings, sectionWidth, sectionHeight, breakHeight),
        ...List.generate(dayCount, (index) {
          return _buildDayColumn(context, index + 1, coursesByDay[index], settings, dayWidth, sectionHeight, breakHeight, currentWeek: currentWeek);
        }),
      ],
    );
  }

  /// 构建节次列
  Widget _buildSectionColumn(BuildContext context, AppSettings settings, double sectionWidth, double sectionHeight, double breakHeight) {
    final List<Widget> children = [];
    for (int section = 1; section <= settings.totalDailySections; section++) {
      if (WeeklyScheduleUtils.shouldShowBreakRow(section, settings.morningSections, settings.afternoonSections)) {
        final breakName = WeeklyScheduleUtils.getBreakRowName(section, settings.morningSections, settings.afternoonSections);
        children.add(_buildSectionBreakCell(context, breakName, sectionWidth, breakHeight));
      }
      children.add(_buildSectionNumberCell(context, section, settings.sectionTimes, sectionWidth, sectionHeight));
    }
    return Column(children: children);
  }

  /// 构建单日列
  Widget _buildDayColumn(BuildContext context, int day, List<Course> courses, AppSettings settings, double dayWidth, double sectionHeight, double breakHeight, {required int currentWeek}) {
    final sectionToCourses = CourseConflictUtils.buildSectionToCoursesMap(
      courses,
      maxSection: settings.totalDailySections,
    );
    final List<Widget> children = [];
    int section = 1;
    while (section <= settings.totalDailySections) {
      if (WeeklyScheduleUtils.shouldShowBreakRow(section, settings.morningSections, settings.afternoonSections)) {
        children.add(_buildDayBreakCell(context, dayWidth, breakHeight));
      }

      final sectionCourses = sectionToCourses[section] ?? const <Course>[];
      if (sectionCourses.isEmpty) {
        children.add(_buildEmptyDayCell(context, dayWidth, sectionHeight));
        section++;
        continue;
      }

      if (sectionCourses.length > 1) {
        children.add(Container(
          height: sectionHeight,
          width: dayWidth,
          decoration: _buildDayCellBorder(context),
          padding: const EdgeInsets.all(2),
          child: GestureDetector(
            onTap: () => _showConflictCoursesForSlot(
              context,
              day: day,
              section: section,
              courses: sectionCourses,
              settings: settings,
            ),
            child: _buildConflictCell(context, sectionCourses.length),
          ),
        ));
        section++;
        continue;
      }

      final course = sectionCourses.first;
      int span = 1;
      int nextSection = section + 1;
      double height = sectionHeight;
      while (nextSection <= settings.totalDailySections) {
        final nextSectionCourses = sectionToCourses[nextSection] ?? const <Course>[];
        final shouldContinue =
            nextSectionCourses.length == 1 && _isSameCourse(nextSectionCourses.first, course);
        if (!shouldContinue) {
          break;
        }
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
        decoration: _buildDayCellBorder(context),
        padding: const EdgeInsets.all(2),
        child: GestureDetector(
          onTap: () => showCourseDetailBottomSheet(
            context: this.context,
            course: course,
            settings: settings,
            onEdited: () => this.context.read<WeeklyCourseBloc>().add(const RefreshWeeklyCourses()),
          ),
          child: _buildCourseCell(context, course, currentWeek: currentWeek),
        ),
      ));
      section += span;
    }
    return Column(children: children);
  }

  BoxDecoration _buildDayCellBorder(BuildContext context) {
    return BoxDecoration(
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
    );
  }

  Widget _buildEmptyDayCell(BuildContext context, double width, double height) {
    return Container(
      height: height,
      width: width,
      decoration: _buildDayCellBorder(context),
    );
  }

  bool _isSameCourse(Course left, Course right) {
    return left == right;
  }

  Widget _buildConflictCell(BuildContext context, int count) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '冲突($count)',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showConflictCoursesForSlot(
    BuildContext context, {
    required int day,
    required int section,
    required List<Course> courses,
    required AppSettings settings,
  }) {
    final sortedCourses = CourseConflictUtils.sortCoursesForConflictList(courses);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '周${['一', '二', '三', '四', '五', '六', '日'][day - 1]} 第$section节 冲突(${sortedCourses.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sortedCourses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final course = sortedCourses[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          course.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${course.timeText} · ${course.position}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).pop();
                          showCourseDetailBottomSheet(
                            context: this.context,
                            course: course,
                            settings: settings,
                            onEdited: () =>
                                this.context.read<WeeklyCourseBloc>().add(const RefreshWeeklyCourses()),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建节次分隔行
  Widget _buildSectionBreakCell(BuildContext context, String name, double width, double height) {
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
  Widget _buildDayBreakCell(BuildContext context, double width, double height) {
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
  Widget _buildSectionNumberCell(BuildContext context, int section, List<SectionTime> sectionTimes, double width, double height) {
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
  Widget _buildCourseCell(BuildContext context, Course course, {required int currentWeek}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 定义一个阈值，当格子高度小于此值时不显示位置信息
        const double positionShowThreshold = 65.0;
        final showPosition = constraints.maxHeight >= positionShowThreshold;
        final isCurrentWeek = course.weeks.contains(currentWeek);
        final backgroundColor = _getCourseBackgroundColor(context, course, currentWeek: currentWeek);
        final textColor = _getCourseContentColor(context, backgroundColor, isCurrentWeek: isCurrentWeek);
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
  Widget _buildEmptyState(BuildContext context) {
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

  Widget _buildHolidayState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.beach_access_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '假期中',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态视图并提供重试按钮以重新加载课程
  Widget _buildErrorState(BuildContext context, String message) {
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
            onPressed: () => context.read<WeeklyCourseBloc>().add(const RefreshWeeklyCourses()),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 显示周数选择对话框，用户可选择要跳转的周
  void _showWeekSelector(BuildContext context, {
      required int currentWeek,
      required int totalWeeks,
      DateTime? startSemesterDate,
  }) {
    final bloc = context.read<WeeklyCourseBloc>();
    final actualCurrentWeek = WeeklyScheduleUtils.calculateCurrentWeek(startSemesterDate ?? DateTime.now());
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
                  itemCount: totalWeeks,
                  itemBuilder: (context, index) {
                    final week = index + 1;
                    final isSelected = currentWeek == week;
                    final isActualCurrentWeek = actualCurrentWeek == week;

                    Color? backgroundColor = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5);
                    Color textColor = Theme.of(context).colorScheme.onSurfaceVariant;
                    BoxBorder? border;

                    if (isSelected) {
                      // 选中周
                      backgroundColor = Theme.of(context).colorScheme.primary;
                      textColor = Theme.of(context).colorScheme.onPrimary;
                    } else if (isActualCurrentWeek) {
                      // 真实当前周（非选中状态）
                      textColor = Theme.of(context).colorScheme.primary;
                      border = Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        bloc.add(JumpToWeek(week));
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

  int _courseIdentityHash(Course course) {
    final buffer = '${course.name}#${course.teacher}#${course.position}';
    var hash = 0;
    for (final code in buffer.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash;
  }

  Color _getCourseBackgroundColor(BuildContext context, Course course, {required int currentWeek}) {
    final isCurrentWeek = course.weeks.contains(currentWeek);
    if (!isCurrentWeek) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return isDark
          ? Colors.grey.shade800.withOpacity(0.6)
          : Colors.grey.shade300.withOpacity(0.6);
    }
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

  Color _getCourseContentColor(BuildContext context, Color backgroundColor, {required bool isCurrentWeek}) {
    if (!isCurrentWeek) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
    return ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  /// 获取周日期范围字符串 (XX月XX日 - XX月XX日)
  String _getWeekDateRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${weekStart.month}月${weekStart.day}日 - ${weekEnd.month}月${weekEnd.day}日';
  }
}
