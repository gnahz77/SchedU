import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'section_time.g.dart';

/// 节次时间模型
@JsonSerializable()
class SectionTime extends Equatable {
  /// 节次序号
  final int section;

  /// 开始时间
  final String startTime;

  /// 结束时间
  final String endTime;

  const SectionTime({
    required this.section,
    required this.startTime,
    required this.endTime,
  });

  /// 从JSON创建SectionTime对象
  factory SectionTime.fromJson(Map<String, dynamic> json) => _$SectionTimeFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$SectionTimeToJson(this);

  /// 创建副本
  SectionTime copyWith({
    int? section,
    String? startTime,
    String? endTime,
  }) {
    return SectionTime(
      section: section ?? this.section,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  List<Object?> get props => [section, startTime, endTime];

  @override
  String toString() {
    return 'SectionTime(section: $section, startTime: $startTime, endTime: $endTime)';
  }
}

/// 时间表配置模型
@JsonSerializable()
class ScheduleConfig extends Equatable {
  /// 总周数
  final int? totalWeek;

  /// 开学时间（时间戳字符串）
  final String? startSemester;

  /// 是否以周日为起始日
  final bool? startWithSunday;

  /// 是否显示周末
  final bool? showWeekend;

  /// 上午课程节数
  final int? forenoon;

  /// 下午课程节数
  final int? afternoon;

  /// 晚间课程节数
  final int? night;

  /// 节次时间列表
  final List<SectionTime>? sections;

  const ScheduleConfig({
    this.totalWeek,
    this.startSemester,
    this.startWithSunday,
    this.showWeekend,
    this.forenoon,
    this.afternoon,
    this.night,
    this.sections,
  });

  /// 从JSON创建ScheduleConfig对象
  factory ScheduleConfig.fromJson(Map<String, dynamic> json) => _$ScheduleConfigFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$ScheduleConfigToJson(this);

  @override
  List<Object?> get props => [
    totalWeek,
    startSemester,
    startWithSunday,
    showWeekend,
    forenoon,
    afternoon,
    night,
    sections,
  ];

  @override
  String toString() {
    return 'ScheduleConfig(totalWeek: $totalWeek, startSemester: $startSemester, '
        'startWithSunday: $startWithSunday, showWeekend: $showWeekend, '
        'forenoon: $forenoon, afternoon: $afternoon, night: $night, '
        'sections: $sections)';
  }
}
