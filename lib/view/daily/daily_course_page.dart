import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/bloc/daily_course/daily_course_bloc.dart';
import 'package:schedu/bloc/daily_course/daily_course_event.dart';
import 'package:schedu/bloc/daily_course/daily_course_state.dart';
import 'package:schedu/repository/app_settings_store.dart';
import 'package:schedu/service/course_conflict_utils.dart';
import 'package:schedu/view/widget/course_detail_bottom_sheet.dart';

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
      context.read<DailyCourseBloc>().add(const RefreshDailyCourses());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日课程'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: BlocBuilder<DailyCourseBloc, DailyCourseState>(
        builder: (context, dailyState) {
          if (dailyState is DailyCourseLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (dailyState is DailyCourseLoaded) {
            return Column(
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
                    _formatDate(dailyState.today),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // 课程列表
                Expanded(
                  child: _buildCourseContent(
                    todayCourses: dailyState.todayCourses,
                    tomorrowCourses: dailyState.tomorrowCourses,
                    sectionTimes: dailyState.sectionTimes,
                    today: dailyState.today,
                    isHoliday: dailyState.isHoliday,
                  ),
                ),
              ],
            );
          } else if (dailyState is DailyCourseError) {
            return _buildErrorState(dailyState.message);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  /// 构建每日课程内容
  Widget _buildCourseContent({
    required List<CourseWithStatus> todayCourses,
    required List<CourseWithStatus> tomorrowCourses,
    required List<SectionTime> sectionTimes,
    required DateTime today,
    required bool isHoliday,
  }) {
    if (isHoliday) {
      return _buildHolidayState();
    }
    if (todayCourses.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildEmptyState(),
            const SizedBox(height: 24),
            _buildTomorrowPreview(tomorrowCourses, sectionTimes),
          ],
        ),
      );
    }

    final allFinished = todayCourses.every(
      (cws) => cws.status == CourseStatus.finished,
    );

    final sortedCourses = List<CourseWithStatus>.from(todayCourses)
      ..sort((a, b) => a.course.sections.first.compareTo(b.course.sections.first));
    final dayCourses = sortedCourses.map((courseWithStatus) => courseWithStatus.course).toList();

    final children = <Widget>[
      for (final cws in sortedCourses)
        _buildCourseCard(
          cws,
          sectionTimes,
          conflictCourses: CourseConflictUtils.overlappingGroupForCourse(dayCourses, cws.course),
        ),
    ];

    if (allFinished) {
      children.add(const SizedBox(height: 24));
      children.add(_buildTomorrowPreview(tomorrowCourses, sectionTimes));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }

  /// 构建课程列表
  Widget _buildCourseCard(
    CourseWithStatus cws,
    List<SectionTime> sectionTimes, {
    required List<Course> conflictCourses,
  }) {
    final course = cws.course;
    final classTimeText = _getClassTimeText(course, sectionTimes);
    final timeText = classTimeText.isNotEmpty ? classTimeText : course.timeText;
    final status = cws.status;
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
                  if (conflictCourses.length > 1) ...[
                    const SizedBox(width: 8),
                    ActionChip(
                      label: Text('冲突(${conflictCourses.length})'),
                      onPressed: () => _showConflictCoursesBottomSheet(conflictCourses),
                      avatar: const Icon(Icons.warning_amber_rounded, size: 16),
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
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
              if (course.remarkSnippet != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        course.remarkSnippet!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showConflictCoursesBottomSheet(List<Course> courses) {
    final sortedCourses = CourseConflictUtils.sortCoursesForConflictList(courses);
    final settings = AppSettingsStore.instance.data;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '冲突(${sortedCourses.length})',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
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
                          Navigator.of(sheetContext).pop();
                          showCourseDetailBottomSheet(
                            context: this.context,
                            course: course,
                            settings: settings,
                            onEdited: () => this.context.read<DailyCourseBloc>().add(const RefreshDailyCourses()),
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

  Widget _buildTomorrowPreview(List<CourseWithStatus> tomorrowCourses, List<SectionTime> sectionTimes) {
    final sortedCourses = List<CourseWithStatus>.from(tomorrowCourses)
      ..sort((a, b) => a.course.sections.first.compareTo(b.course.sections.first));

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
                (cws) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTomorrowCourseRow(cws.course, sectionTimes),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTomorrowCourseRow(Course course, List<SectionTime> sectionTimes) {
    final classTimeText = _getClassTimeText(course, sectionTimes);
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

  Widget _buildHolidayState() {
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
            onPressed: () => context.read<DailyCourseBloc>().add(const RefreshDailyCourses()),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 格式化日期显示
  String _formatDate(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}月${date.day}日 $weekday';
  }
}
