import 'package:flutter/material.dart';

enum AppUpdateDialogAction {
  cancel,
  snooze,
  update,
}

class AppUpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;

  const AppUpdateDialog({
    required this.currentVersion,
    required this.latestVersion,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('发现新版本'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('当前版本：$currentVersion'),
          const SizedBox(height: 8),
          Text('最新版本：$latestVersion'),
          const SizedBox(height: 12),
          const Text('检测到新版本已发布，是否前往 GitHub 发布页查看更新？'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(AppUpdateDialogAction.cancel);
          },
          child: const Text('暂不更新'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(AppUpdateDialogAction.snooze);
          },
          child: const Text('此版本不再提醒'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(AppUpdateDialogAction.update);
          },
          child: const Text('立即更新'),
        ),
      ],
    );
  }
}
