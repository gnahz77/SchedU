import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/jw_import/jw_import_config_bloc.dart';
import '../../bloc/jw_import/jw_import_config_event.dart';
import '../../bloc/jw_import/jw_import_config_side_effect.dart';
import '../../bloc/jw_import/jw_import_config_state.dart';
import 'package:schedu/view/route_names.dart';
import 'ai_service_config_widget.dart';

/// 教务导入配置页面
class JwImportConfigPage extends StatefulWidget {
  const JwImportConfigPage({super.key});

  @override
  State<JwImportConfigPage> createState() => _JwImportConfigPageContentState();
}

class _JwImportConfigPageContentState extends State<JwImportConfigPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _jwUrlController;
  late StreamSubscription<JwImportConfigSideEffect> _sideEffectSub;

  @override
  void initState() {
    super.initState();
    _jwUrlController = TextEditingController();
    final bloc = context.read<JwImportConfigBloc>();
    // 监听SideEffect
    _sideEffectSub = bloc.sideEffectStream.listen((effect) {
      // 处理SideEffect事件
      if (!mounted) return;
      if (effect is ShowErrorMessage) {
        _showSnackBar(context, effect.message, isError: true);
      } else if (effect is ShowSuccessMessage) {
        _showSnackBar(context, effect.message, isError: false);
      } else if (effect is NavigateToImportWebView) {
        Navigator.pushNamed(
          context,
          RouteNames.JW_IMPORT_WEBVIEW,
          arguments: effect.arguments,
        );
      }
    });
    context.read<JwImportConfigBloc>().add(const LoadConfigEvent());
  }

  @override
  void dispose() {
    _jwUrlController.dispose();
    _sideEffectSub.cancel();
    super.dispose();
  }

  /// 开始导入
  Future<void> _startImport(BuildContext context, JwImportConfigLoaded state) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!state.isSystemFreeService && state.importMode == 'ai' && state.apiKey.isEmpty) {
      _showSnackBar(context, '请先配置API Key', isError: true);
      return;
    }

    // 保存配置并在SideEffect中处理导航
    context.read<JwImportConfigBloc>().add(const SaveConfigEvent(navigateToImport: true));
  }

  void _showSnackBar(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JwImportConfigBloc, JwImportConfigState>(
      builder: (context, state) {
        if (state is JwImportConfigInitial || state is JwImportConfigLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('教务导入配置'),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 获取实际的loaded状态
        final loadedState = state as JwImportConfigLoaded;

        // 更新文本框
        if (_jwUrlController.text != loadedState.jwUrl) {
          _jwUrlController.text = loadedState.jwUrl;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('教务导入配置'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 教务系统URL输入
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '教务系统地址',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _jwUrlController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '例如: https://jw.example.edu.cn',
                            labelText: '教务系统URL',
                            prefixIcon: Icon(Icons.link),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入教务系统地址';
                            }
                            if (!value.startsWith('http://') && !value.startsWith('https://')) {
                              return '请输入有效的URL地址';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            context.read<JwImportConfigBloc>().add(UpdateJwUrlEvent(value));
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 导入模式选择
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '导入模式',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment<String>(
                              value: 'ai',
                              label: Text('AI智能识别'),
                              icon: Icon(Icons.auto_awesome),
                            ),
                            ButtonSegment<String>(
                              value: 'js',
                              label: Text('JS脚本解析'),
                              icon: Icon(Icons.code),
                            ),
                          ],
                          selected: {loadedState.importMode},
                          onSelectionChanged: (Set<String> newSelection) {
                            context.read<JwImportConfigBloc>().add(
                              UpdateImportModeEvent(newSelection.first),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // AI服务配置（仅在AI模式下显示）
                if (loadedState.importMode == 'ai')
                  const AiServiceConfigWidget(),

                // JS导入模式提示
                if (loadedState.importMode == 'js')
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.code,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'JS脚本解析模式',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '自定义JavaScript脚本解析课程表数据',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // 开始导入按钮
                FilledButton.icon(
                  onPressed: () => _startImport(context, loadedState),
                  icon: const Icon(Icons.download),
                  label: const Text('开始导入'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
