import 'package:schedu/model/section_time.dart';

/// 周课程表相关的工具类和UI逻辑
class WeeklyScheduleUtils {
  /// 获取周的开始日期
  static DateTime getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// 格式化周范围显示
  static String formatWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${weekStart.month}月${weekStart.day}日 - ${weekEnd.month}月${weekEnd.day}日';
  }

  /// 获取显示的星期列表
  static List<String> getDisplayWeekdays(bool showWeekend) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return showWeekend ? weekdays : weekdays.take(5).toList();
  }

  /// 检查是否需要显示休息分隔行
  static bool shouldShowBreakRow(int section, int morningSections, int afternoonSections) {
    return section == morningSections + 1 || 
           section == morningSections + afternoonSections + 1;
  }

  /// 获取休息行的名称
  static String getBreakRowName(int section, int morningSections, int afternoonSections) {
    if (section == morningSections + 1) {
      return '午休';
    } else if (section == morningSections + afternoonSections + 1) {
      return '晚休';
    }
    return '';
  }

  /// 格式化节次时间文本
  static String formatSectionTime(List<SectionTime> sectionTimes, int section) {
    final sectionTime = sectionTimes.firstWhere(
      (st) => st.section == section,
      orElse: () => SectionTime(section: section, startTime: '', endTime: ''),
    );
    if (sectionTime.startTime.isNotEmpty && sectionTime.endTime.isNotEmpty) {
      return '${sectionTime.startTime}\n${sectionTime.endTime}';
    }
    return '';
  }

  /// 验证时间格式
  static bool isValidTimeFormat(String time) {
    final regex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }

  /// 解析时间字符串为分钟数
  static int parseTimeToMinutes(String time) {
    if (!isValidTimeFormat(time)) return 0;
    
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  /// 将分钟数格式化为时间字符串
  static String formatMinutesToTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// 检查两个日期是否是同一天
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
