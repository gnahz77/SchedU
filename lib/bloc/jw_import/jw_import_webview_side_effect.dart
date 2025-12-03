import 'package:equatable/equatable.dart';

/// JwImportWebview 一次性副作用事件
abstract class JwImportWebviewSideEffect extends Equatable {
  const JwImportWebviewSideEffect();

  @override
  List<Object?> get props => [];
}

/// 显示SnackBar消息
class ShowSnackBarMessage extends JwImportWebviewSideEffect {
  final String message;
  final bool isError;

  const ShowSnackBarMessage(this.message, {this.isError = false});

  @override
  List<Object?> get props => [message, isError];
}

/// 导入成功，返回上一页
class ImportSuccessNavigateBack extends JwImportWebviewSideEffect {
  final int courseCount;

  const ImportSuccessNavigateBack(this.courseCount);

  @override
  List<Object?> get props => [courseCount];
}

/// 显示导入确认对话框
class ShowImportConfirmDialog extends JwImportWebviewSideEffect {
  final int courseCount;

  const ShowImportConfirmDialog(this.courseCount);

  @override
  List<Object?> get props => [courseCount];
}

/// 隐藏导入确认对话框
class HideImportConfirmDialog extends JwImportWebviewSideEffect {
  const HideImportConfirmDialog();
}
