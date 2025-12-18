import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:schedu/gen/assets.gen.dart';
import '../../bloc/jw_import/jw_import_config_bloc.dart';
import '../../bloc/jw_import/jw_import_config_event.dart';
import '../../bloc/jw_import/jw_import_config_state.dart';

/// AI服务配置组件
class AiServiceConfigWidget extends StatelessWidget {
  const AiServiceConfigWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JwImportConfigBloc, JwImportConfigState>(
      builder: (context, state) {
        if (state is! JwImportConfigLoaded) {
          return const SizedBox.shrink();
        }

        return _AiServiceConfigContent(state: state);
      },
    );
  }
}

class _AiServiceConfigContent extends StatefulWidget {
  final JwImportConfigLoaded state;

  const _AiServiceConfigContent({required this.state});

  @override
  State<_AiServiceConfigContent> createState() => _AiServiceConfigContentState();
}

class _AiServiceConfigContentState extends State<_AiServiceConfigContent> {
  late TextEditingController _apiKeyController;
  late TextEditingController _customModelInputController;
  late TextEditingController _maxTextLengthController;
  late TextEditingController _customBaseUrlController;
  late bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.state.apiKey);
    _customModelInputController = TextEditingController(
      text: widget.state.useCustomModel ? widget.state.aiModel : '',
    );
    _maxTextLengthController = TextEditingController(text: widget.state.maxTextLength.toString());
    _customBaseUrlController = TextEditingController(text: widget.state.apiUrl);
  }

  @override
  void didUpdateWidget(_AiServiceConfigContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.apiKey != widget.state.apiKey &&
        _apiKeyController.text != widget.state.apiKey) {
      _apiKeyController.text = widget.state.apiKey;
    }
    // 当切换到自定义模型模式时，更新输入框内容
    if (widget.state.useCustomModel &&
        oldWidget.state.aiModel != widget.state.aiModel &&
        _customModelInputController.text != widget.state.aiModel) {
      _customModelInputController.text = widget.state.aiModel;
    }
    if (oldWidget.state.maxTextLength != widget.state.maxTextLength &&
      _maxTextLengthController.text != widget.state.maxTextLength.toString()) {
      _maxTextLengthController.text = widget.state.maxTextLength.toString();
    }
    if (oldWidget.state.apiUrl != widget.state.apiUrl &&
        _customBaseUrlController.text != widget.state.apiUrl) {
      _customBaseUrlController.text = widget.state.apiUrl;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customModelInputController.dispose();
    _maxTextLengthController.dispose();
    _customBaseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<JwImportConfigBloc>();
    
    return Card(
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
              'AI服务配置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // AI服务商选择
            Text(
              'AI服务商',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: widget.state.selectedProviderIndex,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: widget.state.aiProviders
                  .asMap()
                  .entries
                  .map((entry) => DropdownMenuItem<int>(
                        value: entry.key,
                        child: Row(
                          children: [
                            // AI服务商图标
                            _buildProviderIcon(entry.value.icon, entry.value.name),
                            const SizedBox(width: 8),
                            Text(entry.value.name),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  bloc.add(UpdateAiProviderEvent(value));
                }
              },
            ),

            const SizedBox(height: 16),

            // 系统免费服务说明 - 仅当选择系统服务时显示
            if (widget.state.isSystemFreeService) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '注意：使用AI导入功能会把导入时打开的页面HTML内容发送到第三方AI服务进行解析，继续则代表您已同意此操作。'
                        '\n\n系统免费解析服务可能速度较慢且不稳定，建议使用其他AI服务以获得更好体验。'
                        '\n\n推荐使用: ChatGPT、Grok、DeepSeek、Qwen等高性价比模型',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 以下配置项仅在非系统免费服务时显示
            if (!widget.state.isSystemFreeService) ...[
              // API Key
              Text(
                'API Key',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '请输入API密钥',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureApiKey = !_obscureApiKey;
                      });
                    },
                  ),
                ),
                obscureText: _obscureApiKey,
                onChanged: (value) {
                  bloc.add(UpdateApiKeyEvent(value));
                },
              ),

              const SizedBox(height: 16),

              // AI模型选择
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI模型',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '自定义模型',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: widget.state.useCustomModel,
                        onChanged: (value) {
                          bloc.add(UpdateUseCustomModelEvent(value));
                          if (value) {
                            // 切换到自定义模式时，清空输入框
                            _customModelInputController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 根据是否使用自定义模型显示不同的输入方式
              if (widget.state.useCustomModel)
                // 自定义模型输入框
                TextField(
                  controller: _customModelInputController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '请输入模型名称，例如: gpt-4-turbo',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    bloc.add(UpdateAiModelEvent(value));
                  },
                )
              else
                // 模型下拉列表
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _getSelectedModelValue(),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _buildModelDropdownItems(),
                        onChanged: (value) {
                          if (value != null) {
                            bloc.add(UpdateAiModelEvent(value));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 加载模型按钮
                    IconButton(
                      onPressed: widget.state.apiKey.isEmpty
                          ? null
                          : () {
                        bloc.add(LoadAiModelsEvent());
                      },
                      icon: widget.state.isLoadingModels
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.refresh),
                      tooltip: '加载可用模型',
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // 最大文本长度(可选)
              Text(
                '最大发送文本长度(可选)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _maxTextLengthController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '默认: 32768',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final length = int.tryParse(value);
                  if (length != null && length > 0) {
                    bloc.add(UpdateMaxTextLengthEvent(length));
                  }
                },
              ),

              const SizedBox(height: 16),

              // BaseUrl编辑
              ExpansionTile(
                title: Text(
                  '自定义API BaseUrl',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                    _customBaseUrlController.text.isEmpty ? '使用默认BaseUrl' : '自定义BaseUrl已设置',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.secondary)
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _customBaseUrlController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: '例如: https://api.example.com/v1',
                        helperText: '留空则使用服务商默认BaseUrl: ${widget.state.selectedProvider?.baseUrl ?? "N/A"}',
                        helperMaxLines: 2,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        bloc.add(UpdateCustomApiUrlEvent(value));
                      },
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.state.isTestingService
                        ? null
                        : () {
                            bloc.add(const TestAiServiceEvent());
                          },
                    icon: widget.state.isTestingService
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.science, size: 18),
                    label: Text(widget.state.isTestingService ? '测试中...' : '测试服务'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      bloc.add(const SaveConfigEvent());
                    },
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('保存配置'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 获取当前选中的模型值
  String? _getSelectedModelValue() {
    final currentModel = widget.state.aiModel;

    // 检查当前模型是否在可用模型列表中
    if (widget.state.availableModels.any((m) => m.id == currentModel)) {
      return currentModel;
    }

    // 如果有可用模型，返回第一个
    if (widget.state.availableModels.isNotEmpty) {
      return widget.state.availableModels.first.id;
    }

    // 否则返回默认模型
    return widget.state.selectedProvider?.defaultModel;
  }

  /// 构建模型下拉列表项
  List<DropdownMenuItem<String>> _buildModelDropdownItems() {
    final items = <DropdownMenuItem<String>>[];

    // 如果有从API获取的模型列表，显示它们
    if (widget.state.availableModels.isNotEmpty) {
      items.addAll(
        widget.state.availableModels.map(
          (model) => DropdownMenuItem<String>(
            value: model.id,
            child: Text(
              model.id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    } else if (widget.state.selectedProvider != null) {
      // 否则显示默认模型
      items.add(
        DropdownMenuItem<String>(
          value: widget.state.selectedProvider!.defaultModel,
          child: Text(
            widget.state.selectedProvider!.defaultModel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return items;
  }

  /// 构建服务提供商图标
  Widget _buildProviderIcon(String iconName, String providerName) {
    // 系统免费服务使用 SVG 图标
    if (providerName == JwImportConfigLoaded.systemFreeServiceName) {
      return SvgPicture.asset(
        Assets.images.scheduIcon,
        width: 20,
        height: 20,
      );
    }

    // 其他服务使用 PNG/ICO 图标
    return Image.asset(
      'assets/images/ai/$iconName',
      width: 20,
      height: 20,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.cloud, size: 20);
      },
    );
  }
}
