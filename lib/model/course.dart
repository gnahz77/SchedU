import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:schedu/model/section_time.dart';

part 'course.g.dart';

/// 课程模型类
@JsonSerializable()
class Course extends Equatable {
  static const Object _colorIdUnset = Object();
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
  
  /// 课程配色索引（对应预设颜色表），可为空
  @JsonKey(ignore: true)
  final int? colorId;

  const Course({
    required this.name,
    required this.position,
    required this.teacher,
    required this.weeks,
    required this.day,
    required this.sections,
    this.colorId,
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
    Object? colorId = _colorIdUnset,
  }) {
    return Course(
      name: name ?? this.name,
      position: position ?? this.position,
      teacher: teacher ?? this.teacher,
      weeks: weeks ?? this.weeks,
      day: day ?? this.day,
      sections: sections ?? this.sections,
      colorId: identical(colorId, _colorIdUnset) ? this.colorId : colorId as int?,
    );
  }

  /// 获取课程时间显示文本
  String get timeText {
    final sectionStart = sections.first;
    final sectionEnd = sections.last;
    return '第$sectionStart-$sectionEnd节';
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

  @override
  List<Object?> get props => [name, position, teacher, weeks, day, sections, colorId];

  @override
  String toString() {
    return 'Course(name: $name, position: $position, teacher: $teacher, '
        'weeks: $weeks, day: $day, sections: $sections, colorId: $colorId)';
  }
}
