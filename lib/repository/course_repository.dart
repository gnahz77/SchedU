import 'dart:convert';
import 'package:schedu/model/course.dart';
import 'package:schedu/repository/settings_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 课程数据仓库接口
abstract class CourseRepository {
  Future<List<Course>> getAllCourses();
  Future<void> insertCourse(Course course);
  Future<void> updateCourse(Course course);
  Future<void> deleteCourse(Course course);
  Future<void> insertCourses(List<Course> courses);
  Future<List<Course>> getCoursesForDay(DateTime date, int currentWeek);
  Future<List<Course>> getCoursesForWeek(DateTime weekStart, int currentWeek);
  Future<void> importCoursesFromJson(List<Map<String, dynamic>> jsonData);
}

/// 课程数据仓库实现
class CourseRepositoryImpl implements CourseRepository {
  static const String _tableName = 'courses';
  
  Database? _database;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'schedu.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            position TEXT NOT NULL,
            teacher TEXT NOT NULL,
            weeks TEXT NOT NULL,
            day INTEGER NOT NULL,
            sections TEXT NOT NULL
          )
        ''');
      },
    );
  }
  /// 获取当前周数
  Future<int> getCurrentWeek() async {
    return await SettingsManager.instance.getCurrentWeek();
  }

  /// 设置当前周数
  Future<void> setCurrentWeek(int week) async {
    await SettingsManager.instance.setCurrentWeek(week);
  }

  @override
  Future<List<Course>> getAllCourses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return maps.map((map) => _mapToCourse(map)).toList();
  }

  @override
  Future<void> insertCourse(Course course) async {
    final db = await database;
    await db.insert(
      _tableName,
      _courseToMap(course),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateCourse(Course course) async {
    final db = await database;
    await db.update(
      _tableName,
      _courseToMap(course),
      where: 'name = ? AND day = ? AND sections = ?',
      whereArgs: [
        course.name,
        course.day,
        jsonEncode(course.sections),
      ],
    );
  }

  @override
  Future<void> deleteCourse(Course course) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'name = ? AND day = ? AND sections = ?',
      whereArgs: [
        course.name,
        course.day,
        jsonEncode(course.sections),
      ],
    );
  }

  @override
  Future<void> insertCourses(List<Course> courses) async {
    final db = await database;
    final batch = db.batch();
    
    for (final course in courses) {
      batch.insert(
        _tableName,
        _courseToMap(course),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }

  @override
  Future<List<Course>> getCoursesForDay(DateTime date, int currentWeek) async {
    final allCourses = await getAllCourses();
    final dayOfWeek = date.weekday;
    
    return allCourses.where((course) {
      return course.day == dayOfWeek && course.weeks.contains(currentWeek);
    }).toList();
  }

  @override
  Future<List<Course>> getCoursesForWeek(DateTime weekStart, int currentWeek) async {
    final allCourses = await getAllCourses();
    
    return allCourses.where((course) {
      return course.weeks.contains(currentWeek);
    }).toList();
  }

  @override
  Future<void> importCoursesFromJson(List<Map<String, dynamic>> jsonData) async {
    final db = await database;
    
    // 开启事务，先清空数据表，再插入新数据
    await db.transaction((txn) async {
      // 清空现有课程数据
      await txn.delete(_tableName);
      
      // 插入新的课程数据
      for (final json in jsonData) {
        final course = Course.fromJson(json);
        await txn.insert(
          _tableName,
          _courseToMap(course),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 将Course对象转换为Map
  Map<String, dynamic> _courseToMap(Course course) {
    return {
      'name': course.name,
      'position': course.position,
      'teacher': course.teacher,
      'weeks': jsonEncode(course.weeks),
      'day': course.day,
      'sections': jsonEncode(course.sections),
    };
  }

  /// 将Map转换为Course对象
  Course _mapToCourse(Map<String, dynamic> map) {
    return Course(
      name: map['name'],
      position: map['position'],
      teacher: map['teacher'],
      weeks: List<int>.from(jsonDecode(map['weeks'])),
      day: map['day'],
      sections: List<int>.from(jsonDecode(map['sections'])),
    );
  }
}
