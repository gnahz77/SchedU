// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
      name: json['name'] as String,
      position: json['position'] as String,
      teacher: json['teacher'] as String,
      weeks: (json['weeks'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      day: (json['day'] as num).toInt(),
      sections: (json['sections'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
      'name': instance.name,
      'position': instance.position,
      'teacher': instance.teacher,
      'weeks': instance.weeks,
      'day': instance.day,
      'sections': instance.sections,
    };
