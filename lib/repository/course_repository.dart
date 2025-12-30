import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:schedu/model/course.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 课程数据仓库接口
abstract class CourseRepository {

  // 课程数据变更流
  abstract final Stream<void> stream;

  void dispose() {}

  Future<List<Course>> getAllCourses();
  Future<void> insertCourse(Course course);
  Future<void> updateCourse(Course course);
  Future<void> deleteCourse(Course course);
  Future<void> insertCourses(List<Course> courses);
  Future<List<Course>> getCoursesForDay(int week, int day);
  Future<List<Course>> getCoursesForWeek(int week);
  Future<void> importCoursesFromJson(List<Map<String, dynamic>> jsonData);
}

/// 课程数据仓库实现
class CourseRepositoryImpl extends CourseRepository {
  static const String _tableName = 'courses';
  static const int _dbVersion = 3;
  static const int _colorSlotCount = 12; // Keep in sync with AppColors palettes
  
  Database? _database;
  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  final _stream = StreamController<void>.broadcast();
  @override
  Stream<void> get stream => _stream.stream;

  @override
  void dispose() {
    _stream.close();
    super.dispose();
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'schedu.db');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            position TEXT NOT NULL,
            teacher TEXT NOT NULL,
            weeks TEXT NOT NULL,
            day INTEGER NOT NULL,
            sections TEXT NOT NULL,
            color_id INTEGER,
            weeks_mask INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_tableName ADD COLUMN color_id INTEGER');
        }
        if (oldVersion < 3) {
          // 添加 weeks_mask 列以实现高效的 SQL 过滤
          await db.execute('ALTER TABLE $_tableName ADD COLUMN weeks_mask INTEGER DEFAULT 0');

          // 迁移现有数据：从周数 JSON 计算mask
          final List<Map<String, dynamic>> maps = await db.query(_tableName);
          final batch = db.batch();

          for (final map in maps) {
            final id = map['id'];
            try {
              final weeks = List<int>.from(jsonDecode(map['weeks']));
              final mask = _calculateWeeksMask(weeks);
              batch.update(
                _tableName,
                {'weeks_mask': mask},
                where: 'id = ?',
                whereArgs: [id]
              );
            } catch (e) {
              debugPrint('Error migrating course id $id for weeks_mask: $e');
            }
          }
          await batch.commit(noResult: true);
        }
      },
    );
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
    final normalized = _assignColorIdIfMissing(course);
    await db.insert(
      _tableName,
      _courseToMap(normalized),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _stream.add(null);
  }

  @override
  Future<void> updateCourse(Course course) async {
    if (course.id == null) {
      throw ArgumentError('Course id is required when updating.');
    }
    final db = await database;
    final normalized = _assignColorIdIfMissing(course);
    await db.update(
      _tableName,
      _courseToMap(normalized),
      where: 'id = ?',
      whereArgs: [course.id],
    );
    _stream.add(null);
  }

  @override
  Future<void> deleteCourse(Course course) async {
    if (course.id == null) {
      throw ArgumentError('Course id is required when deleting.');
    }
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [course.id],
    );
    _stream.add(null);
  }

  @override
  Future<void> insertCourses(List<Course> courses) async {
    final db = await database;
    final batch = db.batch();
    
    for (final course in courses) {
      final normalized = _assignColorIdIfMissing(course);
      batch.insert(
        _tableName,
        _courseToMap(normalized),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
    _stream.add(null);
  }

  @override
  Future<List<Course>> getCoursesForDay(int week, int day) async {
    final db = await database;
    final mask = 1 << week;

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'day = ? AND (weeks_mask & ?) != 0',
      whereArgs: [day, mask],
    );

    return maps.map((map) => _mapToCourse(map)).toList();
  }

  @override
  Future<List<Course>> getCoursesForWeek(int week) async {
    final db = await database;
    final mask = 1 << week;

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '(weeks_mask & ?) != 0',
      whereArgs: [mask],
    );

    return maps.map((map) => _mapToCourse(map)).toList();
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
        final course = _assignColorIdIfMissing(Course.fromJson(json));
        await txn.insert(
          _tableName,
          _courseToMap(course),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    _stream.add(null);
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
      'color_id': course.colorId,
      'weeks_mask': _calculateWeeksMask(course.weeks),
    };
  }

  /// 计算周数掩码 (Bitmask)
  int _calculateWeeksMask(List<int> weeks) {
    int mask = 0;
    for (final week in weeks) {
      // 最多62周 (Dart/SQLite int is 64-bit)
      if (week >= 0 && week < 63) {
        mask |= (1 << week);
      }
    }
    return mask;
  }

  /// 将Map转换为Course对象
  Course _mapToCourse(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as int?,
      name: map['name'],
      position: map['position'],
      teacher: map['teacher'],
      weeks: List<int>.from(jsonDecode(map['weeks'])),
      day: map['day'],
      sections: List<int>.from(jsonDecode(map['sections'])),
      colorId: map['color_id'] as int?,
    );
  }

  Course _assignColorIdIfMissing(Course course) {
    if (course.colorId != null || _colorSlotCount <= 0) {
      return course;
    }
    final hash = _courseIdentityHash(course);
    return course.copyWith(colorId: hash % _colorSlotCount);
  }

  int _courseIdentityHash(Course course) {
    final buffer = StringBuffer()
      ..write(course.name)
      ..write('#')
      ..write(course.teacher)
      ..write('#')
      ..write(course.position);
    var hash = 0;
    for (final codeUnit in buffer.toString().codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
