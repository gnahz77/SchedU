package com.gnahz.schedu.model

/**
 * 课程数据模型
 */
data class Course(
    val name: String,
    val position: String,
    val teacher: String,
    val weeks: List<Int>,
    val day: Int,
    val sections: List<Int>,
    val colorId: Int? = null
) {
    /**
     * 获取课程时间显示文本
     */
    val timeText: String
        get() {
            if (sections.isEmpty()) return ""
            val start = sections.first()
            val end = sections.last()
            return "第${start}-${end}节"
        }
}

/**
 * 节次时间模型
 */
data class SectionTime(
    val section: Int,
    val startTime: String,
    val endTime: String
)

/**
 * 课程状态枚举
 */
enum class CourseStatus {
    NOT_STARTED,  // 未开始
    ONGOING,      // 进行中
    FINISHED      // 已结束
}

/**
 * 带状态的课程
 */
data class CourseWithStatus(
    val course: Course,
    val status: CourseStatus
)

/**
 * Widget展示数据
 */
data class WidgetDisplayData(
    val todayCourses: List<CourseWithStatus>,
    val tomorrowCourses: List<CourseWithStatus>,
    val sectionTimes: List<SectionTime>,
    val currentWeek: Int,
    val dateText: String,
    val allFinished: Boolean
)
