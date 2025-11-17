import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/model/section_time.dart';

/// 课程导入服务类
class CourseImportService {
  /// 选择并读取JSON文件
  static Future<List<Map<String, dynamic>>?> pickAndReadJsonFile() async {
    try {
      // 选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();

        // 解析JSON
        final jsonData = jsonDecode(contents);

        // 验证JSON格式
        if (jsonData is List) {
          final List<Map<String, dynamic>> courseList = [];

          for (var item in jsonData) {
            if (item is Map<String, dynamic>) {
              // 验证必要字段
              if (_validateCourseData(item)) {
                courseList.add(item);
              } else {
                throw Exception('JSON数据格式不正确：缺少必要字段');
              }
            } else {
              throw Exception('JSON数据格式不正确：应为对象数组');
            }
          }

          return courseList;
        } else {
          throw Exception('JSON数据格式不正确：根元素应为数组');
        }
      }
      
      return null; // 用户取消选择文件
    } catch (e) {
      throw Exception('文件读取失败: ${e.toString()}');
    }
  }

  /// 选择并读取时间表配置JSON文件
  static Future<ScheduleConfig?> pickAndReadScheduleConfigFile() async {
    try {
      // 选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();

        // 解析JSON
        final jsonData = jsonDecode(contents);

        // 验证并创建ScheduleConfig对象
        if (jsonData is Map<String, dynamic>) {
          return ScheduleConfig.fromJson(jsonData);
        } else {
          throw Exception('JSON数据格式不正确：应为对象格式');
        }
      }

      return null; // 用户取消选择文件
    } catch (e) {
      throw Exception('文件读取失败: ${e.toString()}');
    }
  }

  /// 验证课程数据格式
  static bool _validateCourseData(Map<String, dynamic> data) {
    // 检查必要字段
    final requiredFields = ['name', 'position', 'teacher', 'weeks', 'day', 'sections'];
    
    for (String field in requiredFields) {
      if (!data.containsKey(field)) {
        return false;
      }
    }

    // 验证数据类型
    try {
      // 验证 name, position, teacher 是字符串
      if (data['name'] is! String || 
          data['position'] is! String || 
          data['teacher'] is! String) {
        return false;
      }

      // 验证 day 是整数且在1-7范围内
      final day = data['day'];
      if (day is! int || day < 1 || day > 7) {
        return false;
      }

      // 验证 weeks 是整数数组
      final weeks = data['weeks'];
      if (weeks is! List || weeks.isEmpty) {
        return false;
      }
      for (var week in weeks) {
        if (week is! int || week < 1) {
          return false;
        }
      }

      // 验证 sections 是整数数组
      final sections = data['sections'];
      if (sections is! List || sections.isEmpty) {
        return false;
      }
      for (var section in sections) {
        if (section is! int || section < 1) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 生成示例JSON格式说明
  static String getExampleJsonFormat() {
    final example = [
      {
        "name": "高等数学",
        "position": "教学楼A101",
        "teacher": "张教授",
        "weeks": [1, 2, 3, 4, 5, 6, 7, 8],
        "day": 1,
        "sections": [1, 2]
      },
      {
        "name": "大学英语",
        "position": "教学楼B201",
        "teacher": "李老师",
        "weeks": [1, 2, 3, 4, 5, 6, 7, 8],
        "day": 2,
        "sections": [3, 4]
      }
    ];
    
    return jsonEncode(example);
  }

  /// 生成时间表配置示例JSON格式
  static String getScheduleConfigExampleFormat() {
    final example = {
      "totalWeek": 20,
      "startSemester": "1694419200000", // 时间戳，13位长度字符串
      "startWithSunday": false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
      "showWeekend": false, // 是否显示周末
      "forenoon": 4, // 上午课程节数：[1, 10]之间的整数
      "afternoon": 4, // 下午课程节数：[0, 10]之间的整数
      "night": 4, // 晚间课程节数：[0, 10]之间的整数
      "sections": [
        {
          "section": 1, // 节次：[1, 30]之间的整数
          "startTime": "08:00", // 开始时间：参照这个标准格式5位长度字符串
          "endTime": "08:50" // 结束时间：同上
        },
        {
          "section": 2,
          "startTime": "09:00",
          "endTime": "09:50"
        },
        {
          "section": 3,
          "startTime": "10:00",
          "endTime": "10:50"
        },
        {
          "section": 4,
          "startTime": "11:00",
          "endTime": "11:50"
        }
      ]
    };

    return jsonEncode(example);
  }

  /// 获取字段说明
  static Map<String, String> getFieldDescriptions() {
    return {
      'name': '课程名称（字符串）',
      'position': '上课地点（字符串）',
      'teacher': '教师姓名（字符串）',
      'weeks': '上课周数（整数数组，如[1,2,3,4]）',
      'day': '星期几（整数，1-7表示周一到周日）',
      'sections': '节次（整数数组，如[1,2]表示第1、2节课）',
    };
  }

  /// 获取时间表配置字段说明
  static Map<String, String> getScheduleConfigFieldDescriptions() {
    return {
      'totalWeek': '学期总周数（可选，整数，10-35之间）',
      'startSemester': '开学时间（可选，13位时间戳字符串）',
      'startWithSunday': '是否以周日为起始（可选，布尔值）',
      'showWeekend': '是否显示周末（可选，布尔值）',
      'forenoon': '上午课程节数（可选，整数，1-10之间）',
      'afternoon': '下午课程节数（可选，整数，0-10之间）',
      'night': '晚间课程节数（可选，整数，0-10之间）',
      'sections': '节次时间列表（可选，对象数组）',
    };
  }
}
