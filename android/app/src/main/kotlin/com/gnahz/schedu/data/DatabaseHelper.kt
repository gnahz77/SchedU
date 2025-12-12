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
        private const val DATABASE_VERSION = 2

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
                $COLUMN_COLOR_ID INTEGER
            )
        """)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 2) {
            db.execSQL("ALTER TABLE $TABLE_COURSES ADD COLUMN $COLUMN_COLOR_ID INTEGER")
        }
    }
}
