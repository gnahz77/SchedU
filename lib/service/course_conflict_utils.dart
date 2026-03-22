import 'package:schedu/model/course.dart';

/// 课程冲突相关工具
class CourseConflictUtils {
  static const int _emptySectionOrder = 1 << 30;

  /// 归一化节次：过滤非法值，排序并去重
  static List<int> normalizeSections(List<int> sections) {
    final normalized = sections.where((section) => section > 0).toList()..sort();
    if (normalized.isEmpty) {
      return const [];
    }
    final deduplicated = <int>[];
    int? last;
    for (final section in normalized) {
      if (last != section) {
        deduplicated.add(section);
        last = section;
      }
    }
    return deduplicated;
  }

  /// 节次是否重叠（任意交集即冲突）
  static bool sectionsOverlap(List<int> a, List<int> b) {
    final left = normalizeSections(a);
    final right = normalizeSections(b);
    if (left.isEmpty || right.isEmpty) {
      return false;
    }
    var i = 0;
    var j = 0;
    while (i < left.length && j < right.length) {
      final lv = left[i];
      final rv = right[j];
      if (lv == rv) {
        return true;
      }
      if (lv < rv) {
        i++;
      } else {
        j++;
      }
    }
    return false;
  }

  /// 课程开始节次（用于排序）
  static int courseStartSection(Course course) {
    final normalized = normalizeSections(course.sections);
    if (normalized.isEmpty) {
      return _emptySectionOrder;
    }
    return normalized.first;
  }

  /// 冲突列表排序（稳定规则）
  static List<Course> sortCoursesForConflictList(List<Course> courses) {
    final sorted = List<Course>.from(courses);
    sorted.sort((a, b) {
      final startCompare = courseStartSection(a).compareTo(courseStartSection(b));
      if (startCompare != 0) {
        return startCompare;
      }
      final nameCompare = a.name.compareTo(b.name);
      if (nameCompare != 0) {
        return nameCompare;
      }
      final teacherCompare = a.teacher.compareTo(b.teacher);
      if (teacherCompare != 0) {
        return teacherCompare;
      }
      final positionCompare = a.position.compareTo(b.position);
      if (positionCompare != 0) {
        return positionCompare;
      }
      return _compareNullableInt(a.id, b.id);
    });
    return sorted;
  }

  /// 获取与 target 重叠的课程集合（含 target 本身）
  static List<Course> overlappingGroupForCourse(List<Course> all, Course target) {
    final result = <Course>[];
    for (final course in all) {
      if (course.day != target.day) {
        continue;
      }
      if (sectionsOverlap(course.sections, target.sections)) {
        result.add(course);
      }
    }
    return sortCoursesForConflictList(result);
  }

  /// 按节次构建课程映射（用于周视图逐节次渲染）
  static Map<int, List<Course>> buildSectionToCoursesMap(
    List<Course> courses, {
    required int maxSection,
  }) {
    final result = <int, List<Course>>{};
    for (var section = 1; section <= maxSection; section++) {
      result[section] = <Course>[];
    }
    for (final course in courses) {
      for (final section in normalizeSections(course.sections)) {
        if (section < 1 || section > maxSection) {
          continue;
        }
        result[section]!.add(course);
      }
    }
    for (final entry in result.entries) {
      final sorted = sortCoursesForConflictList(entry.value);
      entry.value
        ..clear()
        ..addAll(sorted);
    }
    return result;
  }

  static int _compareNullableInt(int? a, int? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }
    return a.compareTo(b);
  }
}
