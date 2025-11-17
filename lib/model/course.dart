import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:schedu/repository/settings_manager.dart';
import 'package:schedu/model/section_time.dart';

part 'course.g.dart';

/// 课程状态枚举
enum CourseStatus {
  notStarted,  // 未开始
  ongoing,     // 进行中
  finished,    // 已结束
}

/// 课程模型类
@JsonSerializable()
class Course extends Equatable {
  /// 课程名称
  final String name;
  
  /// 上课地点
  final String position;
  
  /// 教师名称
  final String teacher;
  
  /// 周数列表
  final List<int> weeks;
  
  /// 星期几 (1-7, 1为周一)
  final int day;
  
  /// 节次列表
  final List<int> sections;

  const Course({
    required this.name,
    required this.position,
    required this.teacher,
    required this.weeks,
    required this.day,
    required this.sections,
  });

  /// 从JSON创建Course对象
  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$CourseToJson(this);

  /// 创建副本
  Course copyWith({
    String? name,
    String? position,
    String? teacher,
    List<int>? weeks,
    int? day,
    List<int>? sections,
  }) {
    return Course(
      name: name ?? this.name,
      position: position ?? this.position,
      teacher: teacher ?? this.teacher,
      weeks: weeks ?? this.weeks,
      day: day ?? this.day,
      sections: sections ?? this.sections,
    );
  }

  /// 获取课程时间显示文本
  String get timeText {
    final sectionStart = sections.first;
    final sectionEnd = sections.last;
    return '第$sectionStart-$sectionEnd节';
  }

  /// 获取上下课时间文本
  Future<String> getClassTimeText() async {
    final sectionTimes = await SettingsManager.instance.getSectionTimesList();

    if (sections.isEmpty || sectionTimes.isEmpty) {
      return '';
    }

    final startSection = sections.first;
    final endSection = sections.last;

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

  /// 获取星期显示文本
  String get dayText {
    const days = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days[day];
  }

  /// 获取周数显示文本
  String get weeksText {
    if (weeks.isEmpty) return '';
    if (weeks.length == 1) return '第${weeks.first}周';
    
    final sortedWeeks = List<int>.from(weeks)..sort();
    return '第${sortedWeeks.first}-${sortedWeeks.last}周';
  }

  /// 获取课程状态
  Future<CourseStatus> getCourseStatus([DateTime? targetDate]) async {
    final checkDate = targetDate ?? DateTime.now();
    final now = DateTime.now();
    final sectionTimes = await SettingsManager.instance.getSectionTimesList();

    if (sections.isEmpty || sectionTimes.isEmpty) {
      return CourseStatus.notStarted;
    }

    // 检查课程是否在指定日期进行
    // day属性：1-7，1为周一，7为周日
    final targetWeekday = checkDate.weekday; // DateTime.weekday: 1-7，1为周一
    if (day != targetWeekday) {
      // 课程不在这一天进行
      return CourseStatus.notStarted;
    }

    // 检查课程是否在当前周数内
    final startSemesterStr = await SettingsManager.instance.getStartSemester();
    if (startSemesterStr != null) {
      final startSemester = DateTime.fromMillisecondsSinceEpoch(int.parse(startSemesterStr));
      final weekNumber = ((checkDate.difference(startSemester).inDays) ~/ 7) + 1;

      if (!weeks.contains(weekNumber)) {
        // 课程不在这个周数进行
        return CourseStatus.notStarted;
      }
    }

    final startSection = sections.first;
    final endSection = sections.last;

    final startTime = sectionTimes
        .where((st) => st.section == startSection)
        .firstOrNull?.startTime;

    final endTime = sectionTimes
        .where((st) => st.section == endSection)
        .firstOrNull?.endTime;

    if (startTime == null || endTime == null) {
      return CourseStatus.notStarted;
    }

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

  /// 获取距离下课时间（分钟）
  Future<int?> getRemainingMinutes([DateTime? targetDate]) async {
    final checkDate = targetDate ?? DateTime.now();
    final status = await getCourseStatus(checkDate);

    if (status != CourseStatus.ongoing) {
      return null;
    }

    final now = DateTime.now();

    // 只有当检查日期是今天时，才计算剩余时间
    if (checkDate.year != now.year ||
        checkDate.month != now.month ||
        checkDate.day != now.day) {
      return null;
    }

    final sectionTimes = await SettingsManager.instance.getSectionTimesList();
    final endSection = sections.last;
    final endTime = sectionTimes
        .where((st) => st.section == endSection)
        .firstOrNull?.endTime;

    if (endTime == null) return null;

    final endTimeParts = endTime.split(':');
    final courseEnd = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endTimeParts[0]),
      int.parse(endTimeParts[1]),
    );

    final remaining = courseEnd.difference(now).inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  @override
  List<Object?> get props => [name, position, teacher, weeks, day, sections];

  @override
  String toString() {
    return 'Course(name: $name, position: $position, teacher: $teacher, '
        'weeks: $weeks, day: $day, sections: $sections)';
  }
}
