package com.gnahz.schedu.appwidget.ui

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.Action
import androidx.glance.action.ActionParameters
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.ActionCallback
import android.content.Intent
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.gnahz.schedu.MainActivity
import com.gnahz.schedu.R
import com.gnahz.schedu.model.Course
import com.gnahz.schedu.appwidget.DailyCourseWidgetRefreshAction
import com.gnahz.schedu.data.CourseRepository
import com.gnahz.schedu.model.CourseStatus
import com.gnahz.schedu.model.CourseWithStatus
import com.gnahz.schedu.model.SectionTime
import com.gnahz.schedu.model.WidgetDisplayData

/**
 * 今日课程桌面小组件
 */
class DailyCourseWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val repository = CourseRepository(context)
        val displayData = repository.getWidgetDisplayData()

        provideContent {
            GlanceTheme {
                WidgetContent(displayData)
            }
        }
    }

    @Composable
    private fun WidgetContent(data: WidgetDisplayData) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(WidgetColors.surface)
                .cornerRadius(16.dp)
                .padding(12.dp)
                .clickable(actionRunCallback<OpenAppAction>())
        ) {
            // 头部：日期和刷新按钮
            HeaderRow(data.dateText)

            Spacer(modifier = GlanceModifier.height(8.dp))

            // 课程列表
            if (data.isHoliday) {
                HolidayState()
            } else if (data.todayCourses.isEmpty()) {
                EmptyState(data.tomorrowCourses, data.sectionTimes)
            } else if (data.allFinished) {
                // 今日课程全部结束，显示今日课程和明日预告
                FinishedState(data.todayCourses, data.tomorrowCourses, data.sectionTimes)
            } else {
                // 显示今日课程列表
                CourseList(data.todayCourses, data.sectionTimes)
            }
        }
    }

    @Composable
    private fun HeaderRow(dateText: String) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "今日课程",
                style = TextStyle(
                    color = WidgetColors.onSurface,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
            )

            Spacer(modifier = GlanceModifier.width(8.dp))

            Text(
                text = dateText,
                style = TextStyle(
                    color = WidgetColors.primary,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium
                )
            )

            Spacer(modifier = GlanceModifier.defaultWeight())

            // 刷新按钮
            Box(
                modifier = GlanceModifier
                    .size(32.dp)
                    .cornerRadius(16.dp)
                    .clickable(actionRunCallback<DailyCourseWidgetRefreshAction>()),
                contentAlignment = Alignment.Center
            ) {
                Image(
                    provider = ImageProvider(R.drawable.ic_refresh),
                    contentDescription = "刷新",
                    modifier = GlanceModifier.size(20.dp)
                )
            }
        }
    }

    @Composable
    private fun CourseList(
        courses: List<CourseWithStatus>,
        sectionTimes: List<SectionTime>,
    ) {
        LazyColumn(modifier = GlanceModifier.fillMaxSize()) {
            items(courses) { courseWithStatus ->
                CourseCard(courseWithStatus, sectionTimes)
            }
        }
    }

    @Composable
    private fun CourseCard(
        courseWithStatus: CourseWithStatus,
        sectionTimes: List<SectionTime>,
    ) {
        val course = courseWithStatus.course
        val status = courseWithStatus.status
        val timeText = getCourseTimeText(course, sectionTimes)

        val cardBackground = when (status) {
            CourseStatus.FINISHED -> WidgetColors.finishedBackground
            CourseStatus.ONGOING -> WidgetColors.ongoingBackground
            CourseStatus.NOT_STARTED -> WidgetColors.cardBackground
        }

        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(cardBackground)
                .clickable(actionRunCallback<OpenAppAction>())
                .cornerRadius(12.dp)
                .padding(12.dp)
        ) {
            Column(
                modifier = GlanceModifier
                    .fillMaxWidth()
            ) {
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // 时间标签
                    TimeTag(timeText, status)

                    Spacer(modifier = GlanceModifier.width(8.dp))

                    // 课程名称
                    Column(modifier = GlanceModifier.defaultWeight()) {
                        Text(
                            text = course.name,
                            style = TextStyle(
                                color = if (status == CourseStatus.FINISHED)
                                    WidgetColors.textSecondary else WidgetColors.onSurface,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold
                            ),
                            maxLines = 1
                        )
                    }

                    // 状态指示
                    if (status == CourseStatus.ONGOING) {
                        OngoingIndicator()
                    } else if (status == CourseStatus.FINISHED) {
                        Text(
                            text = "已结束",
                            style = TextStyle(
                                color = WidgetColors.textSecondary,
                                fontSize = 10.sp
                            )
                        )
                    }
                }

                Spacer(modifier = GlanceModifier.height(6.dp))

                // 地点和教师
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Image(
                        provider = ImageProvider(R.drawable.ic_location),
                        contentDescription = null,
                        modifier = GlanceModifier.size(12.dp)
                    )
                    Spacer(modifier = GlanceModifier.width(4.dp))
                    Text(
                        text = "${course.position} · ${course.teacher}",
                        style = TextStyle(
                            color = WidgetColors.textSecondary,
                            fontSize = 11.sp
                        ),
                        maxLines = 1
                    )
                }
            }
        }
    }

    @Composable
    private fun TimeTag(timeText: String, status: CourseStatus) {
        val bgColor = when (status) {
            CourseStatus.ONGOING -> WidgetColors.primary
            CourseStatus.FINISHED -> WidgetColors.finishedTagBg
            CourseStatus.NOT_STARTED -> WidgetColors.primaryContainer
        }

        val textColor = when (status) {
            CourseStatus.ONGOING -> WidgetColors.onPrimary
            CourseStatus.FINISHED -> WidgetColors.textSecondary
            CourseStatus.NOT_STARTED -> WidgetColors.onPrimaryContainer
        }

        Box(
            modifier = GlanceModifier
                .background(bgColor)
                .cornerRadius(6.dp)
                .padding(horizontal = 6.dp, vertical = 4.dp)
        ) {
            Text(
                text = timeText,
                style = TextStyle(
                    color = textColor,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Medium
                )
            )
        }
    }

    @Composable
    private fun OngoingIndicator() {
        Box(
            modifier = GlanceModifier
                .background(WidgetColors.error)
                .cornerRadius(12.dp)
                .padding(horizontal = 8.dp, vertical = 4.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = GlanceModifier
                        .size(6.dp)
                        .cornerRadius(3.dp)
                        .background(WidgetColors.onError)
                ) {
                    Spacer(modifier = GlanceModifier.width(4.dp))
                    Text(
                        text = "上课中",
                        style = TextStyle(
                            color = WidgetColors.onError,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Medium
                        )
                    )
                }
            }
        }
    }

    @Composable
    private fun EmptyState(
        tomorrowCourses: List<CourseWithStatus>,
        sectionTimes: List<SectionTime>,
    ) {
        LazyColumn {
            item {
                Column(
                    modifier = GlanceModifier.fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Spacer(modifier = GlanceModifier.height(16.dp))
                    if (tomorrowCourses.isEmpty()) {
                        // 今日无课程安排
                        Image(
                            provider = ImageProvider(R.drawable.ic_event_available),
                            contentDescription = null,
                            modifier = GlanceModifier.size(48.dp)
                        )
                        Spacer(modifier = GlanceModifier.height(8.dp))
                        Text(
                            text = "今日无课程安排",
                            style = TextStyle(
                                color = WidgetColors.textSecondary,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Medium
                            )
                        )
                        Text(
                            text = "享受悠闲的一天吧！",
                            style = TextStyle(
                                color = WidgetColors.textSecondary,
                                fontSize = 12.sp
                            )
                        )
                    } else {
                        // 明日课程预告
                        TomorrowPreview(tomorrowCourses, sectionTimes)
                    }
                }
            }
        }
    }

    @Composable
    private fun HolidayState() {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Image(
                provider = ImageProvider(R.drawable.ic_event_available),
                contentDescription = null,
                modifier = GlanceModifier.size(48.dp)
            )
            Spacer(modifier = GlanceModifier.height(8.dp))
            Text(
                text = "假期中",
                style = TextStyle(
                    color = WidgetColors.textSecondary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            )
        }
    }

    @Composable
    private fun FinishedState(
        todayCourses: List<CourseWithStatus>,
        tomorrowCourses: List<CourseWithStatus>,
        sectionTimes: List<SectionTime>,
    ) {
        LazyColumn(modifier = GlanceModifier.fillMaxSize()) {
            items(todayCourses) { courseWithStatus ->
                CourseCard(courseWithStatus, sectionTimes)
            }

            item {
                TomorrowPreview(tomorrowCourses, sectionTimes)
            }
        }
    }

    @Composable
    private fun TomorrowPreview(
        tomorrowCourses: List<CourseWithStatus>,
        sectionTimes: List<SectionTime>,
    ) {
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(WidgetColors.cardBackground)
                .cornerRadius(12.dp)
                .padding(12.dp)
        ) {
            Column {
                Text(
                    text = "明日课程预告",
                    style = TextStyle(
                        color = WidgetColors.onSurface,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold
                    )
                )

                Spacer(modifier = GlanceModifier.height(8.dp))

                if (tomorrowCourses.isEmpty()) {
                    Text(
                        text = "明日暂无课程安排",
                        style = TextStyle(
                            color = WidgetColors.textSecondary,
                            fontSize = 12.sp
                        )
                    )
                } else {
                    tomorrowCourses.forEach { courseWithStatus ->
                        CourseCard(courseWithStatus, sectionTimes)
//                        TomorrowCourseRow(courseWithStatus.course, sectionTimes)
                    }
                }
            }
        }
    }

    @Composable
    private fun TomorrowCourseRow(
        course: Course,
        sectionTimes: List<SectionTime>,
    ) {
        val timeText = getCourseTimeText(course, sectionTimes)

        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = GlanceModifier
                    .background(WidgetColors.primaryContainer)
                    .cornerRadius(4.dp)
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            ) {
                Text(
                    text = timeText,
                    style = TextStyle(
                        color = WidgetColors.onPrimaryContainer,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
            }

            Spacer(modifier = GlanceModifier.width(8.dp))

            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(
                    text = course.name,
                    style = TextStyle(
                        color = WidgetColors.onSurface,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium
                    ),
                    maxLines = 1
                )
                Text(
                    text = "${course.position} · ${course.teacher}",
                    style = TextStyle(
                        color = WidgetColors.textSecondary,
                        fontSize = 10.sp
                    ),
                    maxLines = 1
                )
            }
        }
    }

    /**
     * 获取课程时间文本
     */
    fun getCourseTimeText(course: Course, sectionTimes: List<SectionTime>): String {
        if (course.sections.isEmpty() || sectionTimes.isEmpty()) {
            return course.timeText
        }

        val startSection = course.sections.first()
        val endSection = course.sections.last()

        val startTime = sectionTimes.find { it.section == startSection }?.startTime
        val endTime = sectionTimes.find { it.section == endSection }?.endTime

        return if (startTime != null && endTime != null) {
            "$startTime-$endTime"
        } else {
            course.timeText
        }
    }
}

/**
 * 打开应用的回调
 */
class OpenAppAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        context.startActivity(intent)
    }
}

