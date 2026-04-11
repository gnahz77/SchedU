
import 'package:flutter/material.dart';
import 'package:schedu/service/app_update_service.dart';
import 'package:schedu/view/daily/daily_course_page.dart';
import 'package:schedu/view/profile/profile_page.dart';
import 'package:schedu/view/weekly/weekly_course_page.dart';
import 'package:schedu/view/widget/app_update_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

/// 主页面 - 包含底部导航的页面容器
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final AppUpdateService _appUpdateService = AppUpdateService();
  int _currentIndex = 0;
  bool _hasCheckedUpdate = false;

  final List<Widget> _pages = [
    const DailyCoursePage(),
    const WeeklyCoursePage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppUpdate();
    });
  }

  Future<void> _checkAppUpdate() async {
    if (_hasCheckedUpdate) return;
    _hasCheckedUpdate = true;

    try {
      final prompt = await _appUpdateService.checkForUpdate();
      if (!mounted || prompt == null) return;

      final action = await showDialog<AppUpdateDialogAction>(
        context: context,
        builder: (context) => AppUpdateDialog(
          currentVersion: prompt.currentVersion,
          latestVersion: prompt.latestVersion,
        ),
      );

      if (!mounted || action == null) return;

      if (action == AppUpdateDialogAction.snooze) {
        await _appUpdateService.skipVersion(prompt.latestVersion);
        return;
      }

      if (action == AppUpdateDialogAction.update) {
        final uri = Uri.tryParse(prompt.releaseUrl);
        if (uri == null) return;

        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
        }
      }
    } catch (_) {
      // 更新检测全链路静默失败，避免影响应用启动与使用体验
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: '今日课程',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: '周课程表',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
