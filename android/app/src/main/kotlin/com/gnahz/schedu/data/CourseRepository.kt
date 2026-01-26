package com.gnahz.schedu.data

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.core.content.edit
import com.gnahz.schedu.model.Course
import com.gnahz.schedu.model.CourseStatus
import com.gnahz.schedu.model.CourseWithStatus
import com.gnahz.schedu.model.SectionTime
import com.gnahz.schedu.model.WidgetDisplayData
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.util.Calendar

/**
 * 课程数据仓库
 */
class CourseRepository(private val context: Context) {

    private val gson = Gson()

    companion object {
        private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_SECTION_TIMES = "flutter.section_times"
        private const val KEY_START_SEMESTER = "flutter.start_semester"
        private const val KEY_TOTAL_WEEKS = "flutter.total_weeks"
        private const val DEFAULT_TOTAL_WEEKS = 20

        // 默认节次时间
        private val DEFAULT_SECTION_TIMES = listOf(
            SectionTime(1, "08:00", "08:45"),
            SectionTime(2, "08:55", "09:40"),
            SectionTime(3, "10:00", "10:45"),
            SectionTime(4, "10:55", "11:40"),
            SectionTime(5, "14:00", "14:45"),
            SectionTime(6, "14:55", "15:40"),
            SectionTime(7, "16:00", "16:45"),
            SectionTime(8, "16:55", "17:40"),
            SectionTime(9, "19:00", "19:45"),
            SectionTime(10, "19:55", "20:40"),
            SectionTime(11, "20:50", "21:35"),
            SectionTime(12, "21:45", "22:30")
        )
    }

    /**
     * 获取Flutter SharedPreferences
     */
    private fun getFlutterPrefs(): SharedPreferences {
        return context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE).apply {
            // 旧版本兼容
            if (!contains(KEY_START_SEMESTER)) {
                try {
                    val startSemester = getString(KEY_START_SEMESTER, null)
                    if (startSemester != null) {
                        val millis = startSemester.toLongOrNull()
                        if (millis != null) {
                            edit {
                                remove(KEY_START_SEMESTER)
                                putLong(KEY_START_SEMESTER, millis)
                            }
                        }
                    }
                } catch (e: Exception) {}
            }
        }
    }

    /**
     * 获取节次时间列表
     */
    fun getSectionTimes(): List<SectionTime> {
        val prefs = getFlutterPrefs()
        val timesJson = prefs.getString(KEY_SECTION_TIMES, null) ?: return DEFAULT_SECTION_TIMES
        return try {
            val type = object : TypeToken<List<Map<String, Any>>>() {}.type
            val list: List<Map<String, Any>> = gson.fromJson(timesJson, type)
            list.map { map ->
                SectionTime(
                    section = (map["section"] as Double).toInt(),
                    startTime = map["startTime"] as String,
                    endTime = map["endTime"] as String
                )
            }
        } catch (e: Exception) {
            DEFAULT_SECTION_TIMES
        }
    }

    /**
     * 获取开学时间
     */
    private fun getStartSemesterDate(): Calendar? {
        return try {
            val prefs = getFlutterPrefs()
            val millis = prefs.getLong(KEY_START_SEMESTER, System.currentTimeMillis())
            if (millis <= 0L) {
                Calendar.getInstance()
            } else {
                Calendar.getInstance().apply { timeInMillis = millis }
            }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * 获取学期总周数
     */
    private fun getTotalWeeks(): Int {
        return try {
            val prefs = getFlutterPrefs()
            prefs.getInt(KEY_TOTAL_WEEKS, DEFAULT_TOTAL_WEEKS)
        } catch (e: Exception) {
            DEFAULT_TOTAL_WEEKS
        }
    }

    /**
     * 计算当前周数
     */
    private fun calculateCurrentWeek(date: Calendar): Int {
        val startDate = getStartSemesterDate() ?: return 1
        val diff = date.timeInMillis - startDate.timeInMillis
        if (diff < 0) return 1
        return (diff / (7 * 24 * 60 * 60 * 1000L)).toInt() + 1
    }

    /**
     * 计算周数掩码 (Bitmask)
     */
    private fun calculateWeeksMask(week: Int): Long {
        return if (week >= 0 && week < 63) {
            1L shl week
        } else {
            0L
        }
    }

    private fun normalizeDate(date: Calendar): Calendar {
        return (date.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
    }

    private fun isHoliday(date: Calendar): Boolean {
        val startSemester = getStartSemesterDate() ?: return false
        val totalWeeks = getTotalWeeks()
        if (totalWeeks < 1) return false
        val startDate = normalizeDate(startSemester)
        val endDate = normalizeDate(startSemester).apply {
            add(Calendar.DAY_OF_YEAR, totalWeeks * 7 - 1)
        }
        val checkDate = normalizeDate(date)
        return checkDate.before(startDate) || checkDate.after(endDate)
    }

    /**
     * 从数据库获取所有课程
     */
    fun getAllCourses(): List<Course> {
        val dbPath = context.getDatabasePath("schedu.db")
        if (!dbPath.exists()) return emptyList()

        val courses = mutableListOf<Course>()
        try {
            val db = DatabaseHelper(context).readableDatabase
            val cursor = db.query(
                DatabaseHelper.TABLE_COURSES,
                null, null, null, null, null, null
            )
            cursor.use {
                while (it.moveToNext()) {
                    val name = it.getString(it.getColumnIndexOrThrow(DatabaseHelper.COLUMN_NAME))
                    val position = it.getString(it.getColumnIndexOrThrow(DatabaseHelper.COLUMN_POSITION))
                    val teacher = it.getString(it.getColumnIndexOrThrow(DatabaseHelper.COLUMN_TEACHER))
                    val weeksJson = it.getString(it.getColumnIndexOrThrow(DatabaseHelper.COLUMN_WEEKS))
                    val day = it.getInt(it.getColumnIndexOrThrow(DatabaseHelper.COLUMN_DAY))
                    val sectionsJson = it.getString(it.getColumnIndexOrThrow(DatabaseHelper.COLUMN_SECTIONS))
                    val colorIdIndex = it.getColumnIndex(DatabaseHelper.COLUMN_COLOR_ID)
                    val colorId = if (colorIdIndex >= 0 && !it.isNull(colorIdIndex)) {
                        it.getInt(colorIdIndex)
                    } else null

                    val weeks: List<Int> = gson.fromJson(weeksJson, object : TypeToken<List<Int>>() {}.type)
                    val sections: List<Int> = gson.fromJson(sectionsJson, object : TypeToken<List<Int>>() {}.type)

                    courses.add(Course(
                        name = name,
                        position = position,
                        teacher = teacher,
                        weeks = weeks,
                        day = day,
                        sections = sections,
                        colorId = colorId
                    ))
                }
            }
            db.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return courses
    }

    /**
     * 获取指定日期的课程
     */
    fun getCoursesForDate(date: Calendar): List<Course> {
        val weekNumber = calculateCurrentWeek(date)
        val dayOfWeek = when (date.get(Calendar.DAY_OF_WEEK)) {
            Calendar.MONDAY -> 1
            Calendar.TUESDAY -> 2
            Calendar.WEDNESDAY -> 3
            Calendar.THURSDAY -> 4
            Calendar.FRIDAY -> 5
            Calendar.SATURDAY -> 6
            Calendar.SUNDAY -> 7
            else -> 1
        }

        val dbPath = context.getDatabasePath("schedu.db")
        if (!dbPath.exists()) return emptyList()

        val courses = mutableListOf<Course>()
        try {
            val db = DatabaseHelper(context).readableDatabase
            val mask = calculateWeeksMask(weekNumber)

            // 使用位掩码高效筛选：(weeks_mask & mask) != 0
            val cursor = db.rawQuery(
                """
                SELECT * FROM ${DatabaseHelper.TABLE_COURSES}
                WHERE ${DatabaseHelper.COLUMN_DAY} = ? 
                AND (${DatabaseHelper.COLUMN_WEEKS_MASK} & ?) != 0
                """,
                arrayOf(dayOfWeek.toString(), mask.toString())
            )
            cursor.use {
                while (it.moveToNext()) {
                    val name = it.getString(it.getColumnIndexOrThrow(DatabaseHelper.COLUMN_NAME))
                    val position = it.getString(it.getColumnIndexOrThrow(DatabaseHelper.COLUMN_POSITION))
                    val teacher = it.getString(it.getColumnIndexOrThrow(DatabaseHelper.COLUMN_TEACHER))
                    val weeksJson = it.getString(it.getColumnIndexOrThrow(DatabaseHelper.COLUMN_WEEKS))
                    val day = it.getInt(it.getColumnIndexOrThrow(DatabaseHelper.COLUMN_DAY))
                    val sectionsJson = it.getString(it.getColumnIndexOrThrow(DatabaseHelper.COLUMN_SECTIONS))
                    val colorIdIndex = it.getColumnIndex(DatabaseHelper.COLUMN_COLOR_ID)
                    val colorId = if (colorIdIndex >= 0 && !it.isNull(colorIdIndex)) {
                        it.getInt(colorIdIndex)
                    } else null

                    val weeks: List<Int> = gson.fromJson(weeksJson, object : TypeToken<List<Int>>() {}.type)
                    val sections: List<Int> = gson.fromJson(sectionsJson, object : TypeToken<List<Int>>() {}.type)

                    courses.add(Course(
                        name = name,
                        position = position,
                        teacher = teacher,
                        weeks = weeks,
                        day = day,
                        sections = sections,
                        colorId = colorId
                    ))
                }
            }
            db.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return courses.sortedBy { it.sections.firstOrNull() ?: 0 }
    }

    /**
     * 获取课程状态
     */
    fun getCourseStatus(course: Course, date: Calendar, sectionTimes: List<SectionTime>): CourseStatus {
        if (course.sections.isEmpty() || sectionTimes.isEmpty()) {
            return CourseStatus.NOT_STARTED
        }

        val now = Calendar.getInstance()
        val startSection = course.sections.first()
        val endSection = course.sections.last()

        val startTime = sectionTimes.find { it.section == startSection }?.startTime ?: return CourseStatus.NOT_STARTED
        val endTime = sectionTimes.find { it.section == endSection }?.endTime ?: return CourseStatus.NOT_STARTED

        val startParts = startTime.split(":")
        val endParts = endTime.split(":")

        val courseStartCal = Calendar.getInstance().apply {
            set(Calendar.YEAR, date.get(Calendar.YEAR))
            set(Calendar.MONTH, date.get(Calendar.MONTH))
            set(Calendar.DAY_OF_MONTH, date.get(Calendar.DAY_OF_MONTH))
            set(Calendar.HOUR_OF_DAY, startParts[0].toInt())
            set(Calendar.MINUTE, startParts[1].toInt())
            set(Calendar.SECOND, 0)
        }

        val courseEndCal = Calendar.getInstance().apply {
            set(Calendar.YEAR, date.get(Calendar.YEAR))
            set(Calendar.MONTH, date.get(Calendar.MONTH))
            set(Calendar.DAY_OF_MONTH, date.get(Calendar.DAY_OF_MONTH))
            set(Calendar.HOUR_OF_DAY, endParts[0].toInt())
            set(Calendar.MINUTE, endParts[1].toInt())
            set(Calendar.SECOND, 0)
        }

        // 检查是否是今天
        val isToday = now.get(Calendar.YEAR) == date.get(Calendar.YEAR) &&
                now.get(Calendar.DAY_OF_YEAR) == date.get(Calendar.DAY_OF_YEAR)

        return if (isToday) {
            when {
                now.before(courseStartCal) -> CourseStatus.NOT_STARTED
                now.after(courseEndCal) -> CourseStatus.FINISHED
                else -> CourseStatus.ONGOING
            }
        } else if (date.before(now)) {
            CourseStatus.FINISHED
        } else {
            CourseStatus.NOT_STARTED
        }
    }

    /**
     * 获取Widget展示数据
     */
    fun getWidgetDisplayData(): WidgetDisplayData {
        val today = Calendar.getInstance()
        val tomorrow = Calendar.getInstance().apply { add(Calendar.DAY_OF_MONTH, 1) }
        val sectionTimes = getSectionTimes()
        val currentWeek = calculateCurrentWeek(today)
        val isHoliday = isHoliday(today)

        val todayCourses = if (isHoliday) {
            emptyList()
        } else {
            getCoursesForDate(today).map { course ->
                CourseWithStatus(
                    course = course,
                    status = getCourseStatus(course, today, sectionTimes)
                )
            }
        }

        val tomorrowCourses = if (isHoliday) {
            emptyList()
        } else {
            getCoursesForDate(tomorrow).map { course ->
                CourseWithStatus(
                    course = course,
                    status = getCourseStatus(course, tomorrow, sectionTimes)
                )
            }
        }

        val allFinished = todayCourses.isNotEmpty() && todayCourses.all { it.status == CourseStatus.FINISHED }

        val weekdays = arrayOf("周一", "周二", "周三", "周四", "周五", "周六", "周日")
        val dayOfWeek = when (today.get(Calendar.DAY_OF_WEEK)) {
            Calendar.MONDAY -> 0
            Calendar.TUESDAY -> 1
            Calendar.WEDNESDAY -> 2
            Calendar.THURSDAY -> 3
            Calendar.FRIDAY -> 4
            Calendar.SATURDAY -> 5
            Calendar.SUNDAY -> 6
            else -> 0
        }
        val dateText = "${today.get(Calendar.MONTH) + 1}月${today.get(Calendar.DAY_OF_MONTH)}日 ${weekdays[dayOfWeek]}"

        return WidgetDisplayData(
            todayCourses = todayCourses,
            tomorrowCourses = tomorrowCourses,
            sectionTimes = sectionTimes,
            currentWeek = currentWeek,
            dateText = dateText,
            allFinished = allFinished,
            isHoliday = isHoliday
        )
    }
}
