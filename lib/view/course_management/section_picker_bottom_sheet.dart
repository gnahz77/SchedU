import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Bottom sheet widget for selecting section range with scroll pickers
class SectionPickerBottomSheet extends StatefulWidget {
  final int initialStart;
  final int initialEnd;
  final Function(int start, int end) onConfirm;
  final int maxSections;

  const SectionPickerBottomSheet({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    required this.onConfirm,
    this.maxSections = 12,
  });

  @override
  State<SectionPickerBottomSheet> createState() => _SectionPickerBottomSheetState();
}

class _SectionPickerBottomSheetState extends State<SectionPickerBottomSheet> {
  late int _selectedStart;
  late int _selectedEnd;
  late FixedExtentScrollController _startController;
  late FixedExtentScrollController _endController;

  @override
  void initState() {
    super.initState();
    _selectedStart = widget.initialStart;
    _selectedEnd = widget.initialEnd;
    _startController = FixedExtentScrollController(initialItem: _selectedStart - 1);
    _endController = FixedExtentScrollController(initialItem: _selectedEnd - 1);
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 280,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                Text(
                  '选择节次',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onConfirm(_selectedStart, _selectedEnd);
                    Navigator.pop(context);
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Pickers
          Expanded(
            child: Row(
              children: [
                // Start section picker
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _startController,
                    itemExtent: 48,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedStart = index + 1;
                        // Ensure end is not less than start
                        if (_selectedEnd < _selectedStart) {
                          _selectedEnd = _selectedStart;
                          _endController.jumpToItem(_selectedEnd - 1);
                        }
                      });
                    },
                    children: List.generate(widget.maxSections, (index) {
                      return Center(
                        child: Text(
                          '第${index + 1}节',
                          style: TextStyle(
                            fontSize: 18,
                            color: _selectedStart == index + 1
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight: _selectedStart == index + 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '至',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                // End section picker
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _endController,
                    itemExtent: 48,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedEnd = index + 1;
                        // Ensure start is not greater than end
                        if (_selectedStart > _selectedEnd) {
                          _selectedStart = _selectedEnd;
                          _startController.jumpToItem(_selectedStart - 1);
                        }
                      });
                    },
                    children: List.generate(widget.maxSections, (index) {
                      return Center(
                        child: Text(
                          '第${index + 1}节',
                          style: TextStyle(
                            fontSize: 18,
                            color: _selectedEnd == index + 1
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight: _selectedEnd == index + 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
