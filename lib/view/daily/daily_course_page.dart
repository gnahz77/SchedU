import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/settings/settings_bloc.dart';
import 'package:schedu/bloc/settings/settings_state.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/bloc/course/course_bloc.dart';
import '../../bloc/course/course_event.dart';
import '../../bloc/course/course_state.dart';
import '../../model/section_time.dart';

/// 当日课程视图页面
class DailyCoursePage extends StatefulWidget {
  const DailyCoursePage({super.key});

  @override
  State<DailyCoursePage> createState() => _DailyCoursePageState();
}

class _DailyCoursePageState extends State<DailyCoursePage>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<CourseBloc>().add(const LoadCourses());
      setState(() {}); // force rebuild to refresh "today" timestamp
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = _startOfDay(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日课程'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 日期展示
          Container(
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
            child: Text(
              _formatDate(today),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          // 课程列表
          Expanded(
            child: BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, settingsState) {
                return BlocBuilder<CourseBloc, CourseState>(
                  builder: (context, courseState) {
                    if (courseState is CourseLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (courseState is CourseLoaded) {
                      final todayCourses = _filterCourses(
                        courseState.courses,
                        today,
                        settingsState.startSemesterDate,
                      );
                      final tomorrowCourses = _filterCourses(
                        courseState.courses,
                        tomorrow,
                        settingsState.startSemesterDate,
                      );
                      return _buildCourseContent(
                        todayCourses: todayCourses,
                        tomorrowCourses: tomorrowCourses,
                        settings: settingsState,
                        today: today,
                      );
                    } else if (courseState is CourseError) {
                      return _buildErrorState(courseState.message);
                    }
                    return _buildEmptyState();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Course> _filterCourses(List<Course> allCourses, DateTime date, DateTime? startSemester) {
    final weekNumber = _calculateWeekNumber(date, startSemester);
    final weekday = date.weekday;
    return allCourses.where((course) {
      return course.day == weekday && course.weeks.contains(weekNumber);
    }).toList();
  }

  int _calculateWeekNumber(DateTime date, DateTime? startSemester) {
    if (startSemester == null) return 1;
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startSemester.year, startSemester.month, startSemester.day);
    
    final diff = d.difference(s).inDays;
    if (diff < 0) return 1;
    return (diff / 7).floor() + 1;
  }

  /// 构建每日课程内容
  Widget _buildCourseContent({
    required List<Course> todayCourses,
    required List<Course> tomorrowCourses,
    required SettingsState settings,
    required DateTime today,
  }) {
    if (todayCourses.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildEmptyState(),
            const SizedBox(height: 24),
            _buildTomorrowPreview(tomorrowCourses, settings),
          ],
        ),
      );
    }

    final allFinished = todayCourses.every(
      (course) => _getCourseStatus(course, today, settings) == CourseStatus.finished,
    );

    final sortedCourses = List<Course>.from(todayCourses)
      ..sort((a, b) => a.sections.first.compareTo(b.sections.first));

    final children = <Widget>[
      for (final course in sortedCourses) _buildCourseCard(course, settings, today),
    ];

    if (allFinished) {
      children.add(const SizedBox(height: 24));
      children.add(_buildTomorrowPreview(tomorrowCourses, settings));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }

  /// 构建课程列表
  Widget _buildCourseCard(Course course, SettingsState settings, DateTime checkDate) {
    final classTimeText = _getClassTimeText(course, settings.sectionTimes);
    final timeText = classTimeText.isNotEmpty ? classTimeText : course.timeText;
    final status = _getCourseStatus(course, checkDate, settings);
    final isFinished = status == CourseStatus.finished;
    final isOngoing = status == CourseStatus.ongoing;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isFinished ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Opacity(
        opacity: isFinished ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 时间显示
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isFinished
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      timeText,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isFinished
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 课程信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isFinished
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : null,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.teacher,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      course.position,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  if (isFinished) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '已结束',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (isOngoing) ...[
                    const SizedBox(width: 8),
                    _buildOngoingIndicator(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建上课中指示器
  Widget _buildOngoingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPulsingDot(),
          const SizedBox(width: 4),
          Text(
            '上课中',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onError,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建脉动圆点
  Widget _buildPulsingDot() => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onError,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      });

  Widget _buildTomorrowPreview(List<Course> tomorrowCourses, SettingsState settings) {
    final sortedCourses = List<Course>.from(tomorrowCourses)
      ..sort((a, b) => a.sections.first.compareTo(b.sections.first));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '明日课程预告',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            if (sortedCourses.isEmpty)
              Text(
                '明日暂无课程安排',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              ...sortedCourses.map(
                (course) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTomorrowCourseRow(course, settings),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTomorrowCourseRow(Course course, SettingsState settings) {
    final classTimeText = _getClassTimeText(course, settings.sectionTimes);
    final timeText = classTimeText.isNotEmpty ? classTimeText : course.timeText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            timeText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${course.position} · ${course.teacher}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 获取课程时间显示文本
  String _getClassTimeText(Course course, List<SectionTime> sectionTimes) {
    if (course.sections.isEmpty || sectionTimes.isEmpty) {
      return '';
    }

    final startSection = course.sections.first;
    final endSection = course.sections.last;

    // 查找开始节次的时间
    final startTime = sectionTimes
        .where((st) => st.section == startSection)
        .firstOrNull?.startTime;

    // 查找结束节次的时间
    final endTime = sectionTimes
        .where((st) => st.section == endSection)
        .firstOrNull?.endTime;

    if (startTime != null && endTime != null) {
      return '$startTime-$endTime';
    }

    return '';
  }

  /// 获取课程状态
  CourseStatus _getCourseStatus(Course course, DateTime checkDate, SettingsState settings) {
    if (course.sections.isEmpty || settings.sectionTimes.isEmpty) {
      return CourseStatus.notStarted;
    }

    // 检查课程是否在指定日期进行
    final targetWeekday = checkDate.weekday;
    if (course.day != targetWeekday) {
      return CourseStatus.notStarted;
    }

    // 检查课程是否在当前周数内
    if (settings.startSemesterDate != null) {
      final weekNumber = ((checkDate.difference(settings.startSemesterDate!).inDays) ~/ 7) + 1;
      if (!course.weeks.contains(weekNumber)) {
        return CourseStatus.notStarted;
      }
    }

    final startSection = course.sections.first;
    final endSection = course.sections.last;

    final startTime = settings.sectionTimes
        .where((st) => st.section == startSection)
        .firstOrNull?.startTime;

    final endTime = settings.sectionTimes
        .where((st) => st.section == endSection)
        .firstOrNull?.endTime;

    if (startTime == null || endTime == null) {
      return CourseStatus.notStarted;
    }

    final now = DateTime.now();
    
    // 构建课程的开始和结束时间
    final startTimeParts = startTime.split(':');
    final endTimeParts = endTime.split(':');

    final courseStart = DateTime(
      checkDate.year,
      checkDate.month,
      checkDate.day,
      int.parse(startTimeParts[0]),
      int.parse(startTimeParts[1]),
    );

    final courseEnd = DateTime(
      checkDate.year,
      checkDate.month,
      checkDate.day,
      int.parse(endTimeParts[0]),
      int.parse(endTimeParts[1]),
    );

    // 只有当检查日期是今天时，才根据当前时间判断进行状态
    if (checkDate.year == now.year &&
        checkDate.month == now.month &&
        checkDate.day == now.day) {
      // 今天的课程，根据当前时间判断状态
      if (now.isBefore(courseStart)) {
        return CourseStatus.notStarted;
      } else if (now.isAfter(courseEnd)) {
        return CourseStatus.finished;
      } else {
        return CourseStatus.ongoing;
      }
    } else if (checkDate.isBefore(DateTime(now.year, now.month, now.day))) {
      // 过去的日期，课程已结束
      return CourseStatus.finished;
    } else {
      // 未来的日期，课程未开始
      return CourseStatus.notStarted;
    }
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '今日无课程安排',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '享受悠闲的一天吧！',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            onPressed: () => context.read<CourseBloc>().add(const LoadCourses()),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  /// 格式化日期显示
  String _formatDate(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}月${date.day}日 $weekday';
  }
}
