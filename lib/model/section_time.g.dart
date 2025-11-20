// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'section_time.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SectionTime _$SectionTimeFromJson(Map<String, dynamic> json) => SectionTime(
      section: (json['section'] as num).toInt(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
    );

Map<String, dynamic> _$SectionTimeToJson(SectionTime instance) =>
    <String, dynamic>{
      'section': instance.section,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
    };

ScheduleConfig _$ScheduleConfigFromJson(Map<String, dynamic> json) =>
    ScheduleConfig(
      totalWeek: (json['totalWeek'] as num?)?.toInt(),
      startSemester: json['startSemester'] as String?,
      startWithSunday: json['startWithSunday'] as bool?,
      showWeekend: json['showWeekend'] as bool?,
      forenoon: (json['forenoon'] as num?)?.toInt(),
      afternoon: (json['afternoon'] as num?)?.toInt(),
      night: (json['night'] as num?)?.toInt(),
      sections: (json['sections'] as List<dynamic>?)
          ?.map((e) => SectionTime.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ScheduleConfigToJson(ScheduleConfig instance) =>
    <String, dynamic>{
      'totalWeek': instance.totalWeek,
      'startSemester': instance.startSemester,
      'startWithSunday': instance.startWithSunday,
      'showWeekend': instance.showWeekend,
      'forenoon': instance.forenoon,
      'afternoon': instance.afternoon,
      'night': instance.night,
      'sections': instance.sections,
    };
