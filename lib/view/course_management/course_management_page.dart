import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/bloc/course_management/course_management_bloc.dart';
import 'package:schedu/bloc/course_management/course_management_event.dart';
import 'package:schedu/bloc/course_management/course_management_state.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/style/colors.dart';
import 'package:schedu/view/route_names.dart';

/// 课程管理页面
class CourseManagementPage extends StatefulWidget {
  const CourseManagementPage({super.key});

  @override
  State<CourseManagementPage> createState() => _CourseManagementPageState();
}

class _CourseManagementPageState extends State<CourseManagementPage> {
  @override
  void initState() {
    super.initState();
    // Load courses after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CourseManagementBloc>().add(const LoadAllCourses());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CourseManagementBloc, CourseManagementState>(
      listener: (context, state) {
        // Show success/error messages
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        // 多选状态下拦截返回按钮
        return PopScope(
          canPop: !state.isSelectionMode,
          onPopInvokedWithResult: (didPop, result) async {
            if (state.isSelectionMode) {
              context.read<CourseManagementBloc>().add(const ExitSelectionMode());
            }
          },
          child: Scaffold(
            appBar: _buildAppBar(context, state),
            body: _buildBody(state),
            floatingActionButton: _buildFloatingActionButton(context, state),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, CourseManagementState state) {
    if (state.isSelectionMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.read<CourseManagementBloc>().add(const ExitSelectionMode());
          },
        ),
        title: Text('已选择 ${state.selectedCount} 项'),
        actions: [
          TextButton(
            onPressed: () {
              if (state.selectedCount == state.courses.length) {
                context.read<CourseManagementBloc>().add(const UnselectAllCourses());
              } else {
                context.read<CourseManagementBloc>().add(const SelectAllCourses());
              }
            },
            child: Text(
              state.selectedCount == state.courses.length ? '全不选' : '全选',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.onPrimary),
            onPressed: state.hasSelection
                ? () => _showDeleteConfirmation(context, state.selectedCount)
                : null,
          ),
        ],
      );
    }

    return AppBar(
      title: const Text('课程管理'),
      actions: [
        TextButton(
          onPressed: () {
            context.read<CourseManagementBloc>().add(const EnterSelectionMode());
          },
          child: Text(
            '管理',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(CourseManagementState state) {
    if (state.loading && state.courses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              '暂无课程数据',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '请添加课程或从教务系统导入',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CourseManagementBloc>().add(const LoadAllCourses());
      },
      child: ListView.builder(
        itemCount: state.courses.length,
        itemBuilder: (context, index) {
          final course = state.courses[index];
          final isSelected = state.selectedCourses.contains(course);
          return _buildCourseCard(course, isSelected, state.isSelectionMode);
        },
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, CourseManagementState state) {
    if (!state.isSelectionMode) {
      return FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            RouteNames.COURSE_EDITING,
            arguments: null, // null means add new course
          );
          // Refresh course list
          if (result == true && mounted) {
            context.read<CourseManagementBloc>().add(const LoadAllCourses());
          }
        },
        child: const Icon(Icons.add),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCourseCard(Course course, bool isSelected, bool isSelectionMode) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? colorScheme.primary.withOpacity(0.15) : null,
      surfaceTintColor: colorScheme.surface,
      child: InkWell(
        onTap: () async {
          if (isSelectionMode) {
            _toggleSelection(course);
          } else {
            final result = await Navigator.pushNamed(
              context,
              RouteNames.COURSE_EDITING,
              arguments: course,
            );
            // Refresh course list
            if (result == true && mounted) {
              context.read<CourseManagementBloc>().add(const LoadAllCourses());
            }
          }
        },
        onLongPress: () {
          if (!isSelectionMode) {
            context.read<CourseManagementBloc>().add(const EnterSelectionMode());
            _toggleSelection(course);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(course),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: course.colorId != null
                                ? AppColors.lessonTilePalette[course.colorId! % AppColors.lessonTilePalette.length]
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            course.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          course.position,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.person, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          course.teacher,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          '${course.dayText} ${course.timeText}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.view_week, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          course.weeksText,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSelection(Course course) {
    final bloc = context.read<CourseManagementBloc>();
    if (bloc.state.selectedCourses.contains(course)) {
      bloc.add(UnselectCourse(course));
    } else {
      bloc.add(SelectCourse(course));
    }
  }

  void _showDeleteConfirmation(BuildContext context, int count) {
    final bloc = context.read<CourseManagementBloc>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 $count 门课程吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              bloc.add(const DeleteSelectedCourses());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
