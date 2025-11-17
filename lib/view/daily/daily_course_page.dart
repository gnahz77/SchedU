import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/model/course_bloc.dart';
import 'package:schedu/model/course_event.dart';
import 'package:schedu/model/course_state.dart';
import 'package:schedu/repository/settings_manager.dart';

/// 当日课程视图页面
class DailyCoursePage extends StatefulWidget {
  const DailyCoursePage({super.key});

  @override
  State<DailyCoursePage> createState() => _DailyCoursePageState();
}

class _DailyCoursePageState extends State<DailyCoursePage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCoursesForToday();
  }

  void _loadCoursesForToday() {
    context.read<CourseBloc>().add(LoadCoursesForDay(_selectedDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日课程'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _loadCoursesForToday();
            },
            icon: const Icon(Icons.chevron_left),
            tooltip: '上一天',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
              _loadCoursesForToday();
            },
            icon: const Icon(Icons.chevron_right),
            tooltip: '下一天',
          ),
        ],
      ),
      body: Column(
        children: [
          // 日期选择器
          GestureDetector(
            onTap: () => _selectDate(context),
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
              child: Text(
                _formatDate(_selectedDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // 课程列表
          Expanded(
            child: BlocBuilder<CourseBloc, CourseState>(
              buildWhen: (previous, current) {
                // 只在相关状态变化时重建
                if (current is CourseDataLoaded) {
                  if (previous is CourseDataLoaded) {
                    // 检查当前日期的数据是否发生变化
                    return previous.getCoursesForDate(_selectedDate) !=
                           current.getCoursesForDate(_selectedDate);
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
                  final courses = state.getCoursesForDate(_selectedDate);
                  if (courses.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildCourseList(courses);
                } else if (state is CoursesForDayLoaded &&
                           state.date.year == _selectedDate.year &&
                           state.date.month == _selectedDate.month &&
                           state.date.day == _selectedDate.day) {
                  // 兼容旧的状态类型
                  if (state.courses.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildCourseList(state.courses);
                } else if (state is CourseError) {
                  return _buildErrorState(state.message);
                }
                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建课程列表
  Widget _buildCourseList(List<Course> courses) {
    // 按节次排序
    final sortedCourses = List<Course>.from(courses);
    sortedCourses.sort((a, b) => a.sections.first.compareTo(b.sections.first));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCourses.length,
      itemBuilder: (context, index) {
        final course = sortedCourses[index];
        return _buildCourseCard(course);
      },
    );
  }

  /// 构建课程卡片
  Widget _buildCourseCard(Course course) {
    return FutureBuilder<({String timeText, CourseStatus status})>(
      future: _getCourseDisplayInfo(course),
      builder: (context, snapshot) {
        final timeText = snapshot.data?.timeText ?? course.timeText;
        final status = snapshot.data?.status ?? CourseStatus.notStarted;
        final isFinished = status == CourseStatus.finished;

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
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 获取课程显示信息
  Future<({String timeText, CourseStatus status})> _getCourseDisplayInfo(Course course) async {
    final timeText = await course.getClassTimeText();
    final status = await course.getCourseStatus(_selectedDate);

    return (
      timeText: timeText.isNotEmpty ? timeText : course.timeText,
      status: status,
    );
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
            onPressed: _loadCoursesForToday,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 选择日期
  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _loadCoursesForToday();
    }
  }

  /// 格式化日期显示
  String _formatDate(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}月${date.day}日 $weekday';
  }
}
