package com.gnahz.schedu.appwidget.ui


import androidx.compose.ui.graphics.Color
import androidx.glance.color.ColorProvider

/**
 * Widget颜色定义
 */
object WidgetColors {
    // 主色调 - Mars Green
    val primary = ColorProvider(day = Color(0xFF008C8C), night = Color(0xFF00A3A3))
    val onPrimary = ColorProvider(day = Color(0xFFFFFFFF), night = Color(0xFFFFFFFF))
    val primaryContainer = ColorProvider(day = Color(0xFFE0F2F2), night = Color(0xFF1C3333))
    val onPrimaryContainer = ColorProvider(day = Color(0xFF006060), night = Color(0xFF4FBCBC))
    
    // 表面色
    val surface = ColorProvider(day = Color(0xFFF8F8F8), night = Color(0xFF1E1E1E))
    val onSurface = ColorProvider(day = Color(0xFF1A1A1A), night = Color(0xFFE6E6E6))
    
    // 卡片背景
    val cardBackground = ColorProvider(day = Color(0xFFFFFFFF), night = Color(0xFF242D2D))
    
    // 状态色
    val error = ColorProvider(day = Color(0xFFB00020), night = Color(0xFFCF6679))
    val onError = ColorProvider(day = Color(0xFFFFFFFF), night = Color(0xFF000000))
    
    // 文字色
    val textSecondary = ColorProvider(day = Color(0xFF757575), night = Color(0xFFB8B8B8))
    
    // 已结束课程背景
    val finishedBackground = ColorProvider(day = Color(0xFFF5F5F5), night = Color(0xFF1A1A1A))
    val finishedTagBg = ColorProvider(day = Color(0xFFE0E0E0), night = Color(0xFF424242))
    
    // 上课中课程背景
    val ongoingBackground = ColorProvider(day = Color(0xFFFFF8E1), night = Color(0xFF3D3520))
}