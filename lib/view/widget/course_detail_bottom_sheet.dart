import 'package:flutter/material.dart';
import 'package:schedu/model/app_settings.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/view/route_names.dart';

/// 显示课程详情 BottomSheet
Future<void> showCourseDetailBottomSheet({
  required BuildContext context,
  required Course course,
  required AppSettings settings,
  required VoidCallback onEdited,
}) async {
  final rootContext = context;
  await showModalBottomSheet(
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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final result = await Navigator.of(rootContext).pushNamed(
                        RouteNames.COURSE_EDITING,
                        arguments: course,
                      );
                      if (result == true) {
                        onEdited();
                      }
                    },
                    icon: const Icon(Icons.edit),
                    tooltip: '编辑课程',
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: _CourseDetailContent(
                  course: course,
                  settings: settings,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CourseDetailContent extends StatelessWidget {
  const _CourseDetailContent({
    required this.course,
    required this.settings,
  });

  final Course course;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem(
          context: context,
          icon: Icons.school,
          title: '课程名称',
          content: course.name,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        _buildDetailItem(
          context: context,
          icon: Icons.person,
          title: '任课教师',
          content: course.teacher,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(height: 16),
        _buildDetailItem(
          context: context,
          icon: Icons.location_on,
          title: '上课地点',
          content: course.position,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        const SizedBox(height: 16),
        _buildDetailItem(
          context: context,
          icon: Icons.schedule,
          title: '上课时间',
          content: '${course.dayText} ${course.timeText}',
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        _buildDetailItem(
          context: context,
          icon: Icons.calendar_today,
          title: '上课周数',
          content: course.weeksText,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        _buildDetailItem(
          context: context,
          icon: Icons.sticky_note_2_outlined,
          title: '课程备注',
          content: course.remark?.trim().isNotEmpty == true
              ? course.remark!.trim()
              : '暂无备注\n点击右上角编辑添加备注',
          color: Theme.of(context).colorScheme.outline,
          emphasizeContent: course.remark?.trim().isNotEmpty == true,
        ),
        const SizedBox(height: 24),
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
                  final sectionTime = settings.sectionTimes[section - 1];
                  final timeText = '${sectionTime.startTime}-${sectionTime.endTime}';
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

  Widget _buildDetailItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    bool emphasizeContent = true,
  }) {
    final contentStyle = emphasizeContent
        ? Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
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
                  style: contentStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
