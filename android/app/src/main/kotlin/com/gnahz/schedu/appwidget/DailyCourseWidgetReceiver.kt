package com.gnahz.schedu.appwidget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import com.gnahz.schedu.appwidget.ui.DailyCourseWidget
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * 今日课程小组件接收器
 */
class DailyCourseWidgetReceiver : GlanceAppWidgetReceiver() {

    override val glanceAppWidget: GlanceAppWidget = DailyCourseWidget()

    companion object {
        const val ACTION_REFRESH = "com.gnahz.schedu.widget.ACTION_REFRESH"
        
        /**
         * 更新所有小组件实例
         */
        suspend fun updateAll(context: Context) {
            val manager = GlanceAppWidgetManager(context)
            val widget = DailyCourseWidget()
            val glanceIds = manager.getGlanceIds(widget::class.java)
            glanceIds.forEach { glanceId ->
                widget.update(context, glanceId)
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            ACTION_REFRESH,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED -> {
                // 刷新所有小组件
                CoroutineScope(Dispatchers.IO).launch {
                    updateAll(context)
                }
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        // 小组件首次添加时设置定时更新
        schedulePeriodicUpdate(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // 移除所有小组件时取消定时更新
        cancelPeriodicUpdate(context)
    }

    /**
     * 设置定期更新
     */
    private fun schedulePeriodicUpdate(context: Context) {
    }

    /**
     * 取消定期更新
     */
    private fun cancelPeriodicUpdate(context: Context) {
    }
}

/**
 * 刷新按钮点击回调
 */
class DailyCourseWidgetRefreshAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        // 刷新小组件
        DailyCourseWidget().update(context, glanceId)
    }
}
