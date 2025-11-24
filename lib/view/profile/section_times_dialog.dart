import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/settings/settings_bloc.dart';
import '../../bloc/settings/settings_event.dart';
import '../../model/section_time.dart';

/// 节次时间设置对话框
class SectionTimesSettingDialog extends StatefulWidget {
  final Map<int, SectionTime> editableSectionTimes;
  final int maxSections;
  final int morningSections;
  final int afternoonSections;
  final int eveningSections;
  final TimeOfDay? Function(String) onParseTimeOfDay;
  final String Function(TimeOfDay) onFormatTimeOfDay;

  const SectionTimesSettingDialog({
    required this.editableSectionTimes,
    required this.maxSections,
    required this.morningSections,
    required this.afternoonSections,
    required this.eveningSections,
    required this.onParseTimeOfDay,
    required this.onFormatTimeOfDay,
  });

  @override
  State<SectionTimesSettingDialog> createState() => SectionTimesSettingDialogState();
}

class SectionTimesSettingDialogState extends State<SectionTimesSettingDialog> {
  bool _isQuickSetup = false;

  // 快速设置参数
  TimeOfDay _morningStartTime = const TimeOfDay(hour: 8, minute: 0);
  int _morningClassDuration = 45;
  int _morningBreakDuration = 10;
  int _morningBigBreakDuration = 0;

  TimeOfDay _afternoonStartTime = const TimeOfDay(hour: 14, minute: 0);
  int _afternoonClassDuration = 45;
  int _afternoonBreakDuration = 10;
  int _afternoonBigBreakDuration = 0;

  TimeOfDay _eveningStartTime = const TimeOfDay(hour: 19, minute: 0);
  int _eveningClassDuration = 45;
  int _eveningBreakDuration = 10;
  int _eveningBigBreakDuration = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(_isQuickSetup ? '快速设置' : '节次时间设置'),
          ),
          IconButton(
            icon: Icon(_isQuickSetup ? Icons.edit : Icons.flash_on),
            tooltip: _isQuickSetup ? '详细设置' : '快速设置',
            onPressed: () {
              setState(() {
                _isQuickSetup = !_isQuickSetup;
              });
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: _isQuickSetup ? _buildQuickSetupView() : _buildDetailedView(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => _handleSave(context),
          child: const Text('确定'),
        ),
      ],
    );
  }

  /// 详细设置视图
  Widget _buildDetailedView() {
    return ListView.builder(
      itemCount: widget.maxSections,
      itemBuilder: (context, index) {
        final section = index + 1;
        final sectionTime = widget.editableSectionTimes[section]!;
        final startTime = widget.onParseTimeOfDay(sectionTime.startTime);
        final endTime = widget.onParseTimeOfDay(sectionTime.endTime);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '第$section节',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: startTime ?? const TimeOfDay(hour: 8, minute: 0),
                          );
                          if (picked != null) {
                            setState(() {
                              widget.editableSectionTimes[section] = SectionTime(
                                section: section,
                                startTime: widget.onFormatTimeOfDay(picked),
                                endTime: sectionTime.endTime,
                              );
                            });
                          }
                        },
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            startTime != null
                                ? widget.onFormatTimeOfDay(startTime)
                                : '选择开始时间',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: endTime ?? const TimeOfDay(hour: 8, minute: 45),
                          );
                          if (picked != null) {
                            setState(() {
                              widget.editableSectionTimes[section] = SectionTime(
                                section: section,
                                startTime: sectionTime.startTime,
                                endTime: widget.onFormatTimeOfDay(picked),
                              );
                            });
                          }
                        },
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            endTime != null
                                ? widget.onFormatTimeOfDay(endTime)
                                : '选择结束时间',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 快速设置视图
  Widget _buildQuickSetupView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '通过设置首节课开始时间、课程时长和课间时长，自动计算所有节次时间',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // 上午设置
          if (widget.morningSections > 0) ...[
            _buildTimePeriodCard(
              title: '上午课程',
              subtitle: '共${widget.morningSections}节',
              startTime: _morningStartTime,
              classDuration: _morningClassDuration,
              breakDuration: _morningBreakDuration,
              extraBreakDuration: _morningBigBreakDuration,
              onStartTimeChanged: (time) {
                setState(() => _morningStartTime = time);
              },
              onClassDurationChanged: (duration) {
                setState(() => _morningClassDuration = duration);
              },
              onBreakDurationChanged: (duration) {
                setState(() => _morningBreakDuration = duration);
              },
              onExtraBreakDurationChanged: (duration) {
                setState(() => _morningBigBreakDuration = duration);
              },
            ),
            const SizedBox(height: 12),
          ],
          // 下午设置
          if (widget.afternoonSections > 0) ...[
            _buildTimePeriodCard(
              title: '下午课程',
              subtitle: '共${widget.afternoonSections}节',
              startTime: _afternoonStartTime,
              classDuration: _afternoonClassDuration,
              breakDuration: _afternoonBreakDuration,
              extraBreakDuration: _afternoonBigBreakDuration,
              onStartTimeChanged: (time) {
                setState(() => _afternoonStartTime = time);
              },
              onClassDurationChanged: (duration) {
                setState(() => _afternoonClassDuration = duration);
              },
              onBreakDurationChanged: (duration) {
                setState(() => _afternoonBreakDuration = duration);
              },
              onExtraBreakDurationChanged: (duration) {
                setState(() => _afternoonBigBreakDuration = duration);
              },
            ),
            const SizedBox(height: 12),
          ],
          // 晚上设置
          if (widget.eveningSections > 0) ...[
            _buildTimePeriodCard(
              title: '晚上课程',
              subtitle: '共${widget.eveningSections}节',
              startTime: _eveningStartTime,
              classDuration: _eveningClassDuration,
              breakDuration: _eveningBreakDuration,
              extraBreakDuration: _eveningBigBreakDuration,
              onStartTimeChanged: (time) {
                setState(() => _eveningStartTime = time);
              },
              onClassDurationChanged: (duration) {
                setState(() => _eveningClassDuration = duration);
              },
              onBreakDurationChanged: (duration) {
                setState(() => _eveningBreakDuration = duration);
              },
              onExtraBreakDurationChanged: (duration) {
                setState(() => _eveningBigBreakDuration = duration);
              },
            ),
          ],
        ],
      ),
    );
  }

  /// 构建时间段设置卡片
  Widget _buildTimePeriodCard({
    required String title,
    required String subtitle,
    required TimeOfDay startTime,
    required int classDuration,
    required int breakDuration,
    required int extraBreakDuration,
    required ValueChanged<TimeOfDay> onStartTimeChanged,
    required ValueChanged<int> onClassDurationChanged,
    required ValueChanged<int> onBreakDurationChanged,
    required ValueChanged<int> onExtraBreakDurationChanged,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            // 开始时间
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text('首节开始：'),
                ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        onStartTimeChanged(picked);
                      }
                    },
                    child: Text(widget.onFormatTimeOfDay(startTime)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 课程时长
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text('课程时长：'),
                ),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: classDuration,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [30, 40, 45, 50, 60, 90]
                        .map((duration) => DropdownMenuItem(
                      value: duration,
                      child: Text('$duration分钟'),
                    ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onClassDurationChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 课间时长
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text('课间时长：'),
                ),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: breakDuration,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [5, 10, 15, 20, 25, 30]
                        .map((duration) => DropdownMenuItem(
                      value: duration,
                      child: Text('$duration分钟'),
                    ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onBreakDurationChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 大课间时长（可选）
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text('大课间时长：'),
                ),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: extraBreakDuration,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [0, 5, 10, 15, 20, 25, 30]
                        .map((duration) => DropdownMenuItem(
                      value: duration,
                      child: Text(duration == 0 ? '不启用' : '$duration分钟'),
                    ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onExtraBreakDurationChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 处理保存
  void _handleSave(BuildContext context) {
    if (_isQuickSetup) {
      // 根据快速设置计算所有节次时间
      _calculateSectionTimes();
    }

    // 过滤掉空的时间设置
    final validSectionTimes = widget.editableSectionTimes.values
        .where((st) => st.startTime.isNotEmpty && st.endTime.isNotEmpty)
        .toList()
      ..sort((a, b) => a.section.compareTo(b.section));

    context.read<SettingsBloc>().add(UpdateSectionTimes(validSectionTimes));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('节次时间设置已保存')),
    );
  }

  /// 根据快速设置计算所有节次时间
  void _calculateSectionTimes() {
    int currentSection = 1;

    // 计算上午课程
    if (widget.morningSections > 0) {
      TimeOfDay currentTime = _morningStartTime;
      for (int i = 0; i < widget.morningSections; i++) {
        final startTime = currentTime;
        final endTime = _addMinutes(currentTime, _morningClassDuration);

        widget.editableSectionTimes[currentSection] = SectionTime(
          section: currentSection,
          startTime: widget.onFormatTimeOfDay(startTime),
          endTime: widget.onFormatTimeOfDay(endTime),
        );

        currentSection++;
        final breakToUse = (i % 2 == 1 && _morningBigBreakDuration > 0)
            ? _morningBigBreakDuration
            : _morningBreakDuration;
        currentTime = _addMinutes(endTime, breakToUse);
      }
    }

    // 计算下午课程
    if (widget.afternoonSections > 0) {
      TimeOfDay currentTime = _afternoonStartTime;
      for (int i = 0; i < widget.afternoonSections; i++) {
        final startTime = currentTime;
        final endTime = _addMinutes(currentTime, _afternoonClassDuration);

        widget.editableSectionTimes[currentSection] = SectionTime(
          section: currentSection,
          startTime: widget.onFormatTimeOfDay(startTime),
          endTime: widget.onFormatTimeOfDay(endTime),
        );

        currentSection++;
        final breakToUse = (i % 2 == 1 && _afternoonBigBreakDuration > 0)
            ? _afternoonBigBreakDuration
            : _afternoonBreakDuration;
        currentTime = _addMinutes(endTime, breakToUse);
      }
    }

    // 计算晚上课程
    if (widget.eveningSections > 0) {
      TimeOfDay currentTime = _eveningStartTime;
      for (int i = 0; i < widget.eveningSections; i++) {
        final startTime = currentTime;
        final endTime = _addMinutes(currentTime, _eveningClassDuration);

        widget.editableSectionTimes[currentSection] = SectionTime(
          section: currentSection,
          startTime: widget.onFormatTimeOfDay(startTime),
          endTime: widget.onFormatTimeOfDay(endTime),
        );

        currentSection++;
        final breakToUse = (i % 2 == 1 && _eveningBigBreakDuration > 0)
            ? _eveningBigBreakDuration
            : _eveningBreakDuration;
        currentTime = _addMinutes(endTime, breakToUse);
      }
    }
  }

  /// 给TimeOfDay添加分钟数
  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }
}
