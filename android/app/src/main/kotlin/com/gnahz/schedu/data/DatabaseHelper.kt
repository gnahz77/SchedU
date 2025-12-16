package com.gnahz.schedu.data

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

/**
 * 数据库帮助类 - 与Flutter代码保持一致
 */
class DatabaseHelper(context: Context) : SQLiteOpenHelper(
    context,
    DATABASE_NAME,
    null,
    DATABASE_VERSION
) {
    companion object {
        private const val DATABASE_NAME = "schedu.db"
        private const val DATABASE_VERSION = 3

        const val TABLE_COURSES = "courses"

        // 课程表字段
        const val COLUMN_ID = "id"
        const val COLUMN_NAME = "name"
        const val COLUMN_POSITION = "position"
        const val COLUMN_TEACHER = "teacher"
        const val COLUMN_WEEKS = "weeks"
        const val COLUMN_DAY = "day"
        const val COLUMN_SECTIONS = "sections"
        const val COLUMN_COLOR_ID = "color_id"
        const val COLUMN_WEEKS_MASK = "weeks_mask"
    }

    override fun onCreate(db: SQLiteDatabase) {
        // 创建课程表（与Flutter端保持一致）
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS $TABLE_COURSES (
                $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COLUMN_NAME TEXT NOT NULL,
                $COLUMN_POSITION TEXT NOT NULL,
                $COLUMN_TEACHER TEXT NOT NULL,
                $COLUMN_WEEKS TEXT NOT NULL,
                $COLUMN_DAY INTEGER NOT NULL,
                $COLUMN_SECTIONS TEXT NOT NULL,
                $COLUMN_COLOR_ID INTEGER,
                $COLUMN_WEEKS_MASK INTEGER DEFAULT 0
            )
        """)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 2) {
            db.execSQL("ALTER TABLE $TABLE_COURSES ADD COLUMN $COLUMN_COLOR_ID INTEGER")
        }
        if (oldVersion < 3) {
            // 添加 weeks_mask 列以支持高效的 SQL 位掩码筛选
            db.execSQL("ALTER TABLE $TABLE_COURSES ADD COLUMN $COLUMN_WEEKS_MASK INTEGER DEFAULT 0")

            // 迁移现有数据：从周数 JSON 计算 mask
            val cursor = db.query(
                TABLE_COURSES,
                arrayOf(COLUMN_ID, COLUMN_WEEKS),
                null, null, null, null, null
            )
            cursor.use {
                while (it.moveToNext()) {
                    val id = it.getLong(it.getColumnIndexOrThrow(COLUMN_ID))
                    val weeksJson = it.getString(it.getColumnIndexOrThrow(COLUMN_WEEKS))
                    try {
                        val weeks = com.google.gson.Gson().fromJson(
                            weeksJson,
                            object : com.google.gson.reflect.TypeToken<List<Int>>() {}.type
                        ) as? List<Int> ?: emptyList()
                        val mask = calculateWeeksMask(weeks)
                        db.execSQL(
                            "UPDATE $TABLE_COURSES SET $COLUMN_WEEKS_MASK = ? WHERE $COLUMN_ID = ?",
                            arrayOf(mask, id)
                        )
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        }
    }

    /**
     * 计算周数掩码 (Bitmask)
     */
    private fun calculateWeeksMask(weeks: List<Int>): Long {
        var mask = 0L
        for (week in weeks) {
            if (week >= 0 && week < 63) {
                mask = mask or (1L shl week)
            }
        }
        return mask
    }
}
